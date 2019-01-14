//
//  CarryOverAdjustmentManager.swift
//  DailyTest
//
//  Created by Josh Sherick on 12/1/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class CarryOverAdjustmentManager {
    private var persistentContainer: NSPersistentContainer
    private var queue: DispatchQueue

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer

        let queueLabel = "com.joshsherick.DailySpend.GetCarryOverAdjustments"
        queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
    }

    /**
     * Required to write to any carry over adjustments.
     */
    private static let carryOverWrite = DispatchSemaphore(value: 1)

    typealias CarryOverAdjustmentUpdateCompletion = (_ amountUpdated: Set<Adjustment>?, _ deleted: Set<Adjustment>?, _ inserted: Set<Adjustment>?) -> ()

    typealias CarryOverAdjustmentEnableCompletion = (_ enabled: Adjustment?) -> ()

    /**
     * For a given recurring goal:
     * Updates all existing carry over adjustments that are on the correct day
     * but with the wrong amount. Deletes all carry over adjustments that are
     * on the wrong day. Adds carry over adjustments on days where they should
     * exist but don't.
     *
     * If `goal` is not recurring, removes all carry over adjustments for that
     * goal, since it doesn't need any.
     *
     * On completion, calls `completion` with the set of adjustments where the
     * value was updated, deleted, and inserted, in that order. If the operation
     * failed, all three values will be `nil`.
     */
    func updateCarryOverAdjustments(
        for goal: Goal,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        queue.async {
            self.persistentContainer.performBackgroundTask({ (context) in
                context.perform {
                    let goal = Goal.inContext(goal.objectID, context: context) as! Goal

                    if !goal.isRecurring {
                        self.removeAllCarryOver(context: context, for: goal, completion: completion)
                    } else {
                        self.updateAdjustments(
                            context: context,
                            for: goal,
                            creationType: goal.carryOverBalance ? .CarryOver : .CarryOverDeleted,
                            completion: completion
                        )
                    }
                }
            })
        }
    }

    private func removeAllCarryOver(
        context: NSManagedObjectContext,
        for goal: Goal,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        CarryOverAdjustmentManager.carryOverWrite.wait()
        let currentAdjustments = getCarryOverAdjustments(context: context, goal: goal)

        var deleted = Set<Adjustment>()

        for adjustment in currentAdjustments {
            context.delete(adjustment)
            deleted.insert(adjustment)
        }

        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            context.rollback()
            completionOnMain(completion, amountUpdated: nil, deleted: nil, inserted: nil)
            CarryOverAdjustmentManager.carryOverWrite.signal()
            return
        }

        completionOnMain(completion, amountUpdated: Set<Adjustment>(), deleted: deleted, inserted: Set<Adjustment>())
        CarryOverAdjustmentManager.carryOverWrite.signal()
    }

    /**
     * Performs the update operation on a recurring goal.
     *
     * - Parameters:
     *    - creationType: The type with which any adjustments created as part of
     *      this process will be created with.
     */
    private func updateAdjustments(
        context: NSManagedObjectContext,
        for goal: Goal,
        creationType: Adjustment.AdjustmentType,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        let group = DispatchGroup()
        
        // True if any balance calculations have failed.
        var failed = false
        
        // A map from a calendar day to the balance on that day.
        var balanceOnDay = [CalendarDay: Decimal]()
        
        // Start from the first period.
        var period = CalendarPeriod(
            calendarDate: goal.start!,
            period: goal.period,
            beginningDateOfPeriod: goal.start!,
            boundingEndDate: nil
        )!
        
        // Customize this balance calculator to calculate balances without
        // carry over adjustments.
        let balanceCalculator = GoalBalanceCalculator(persistentContainer: persistentContainer)

        let df = DateFormatter()
        df.timeStyle = .none
        df.dateStyle = .short

        
        // Stop at the period before the most recent one.
        let mostRecentPeriod = goal.mostRecentPeriod()!
        while period.end!.gmtDate <= mostRecentPeriod.start.gmtDate {
            let df = DateFormatter()
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.timeStyle = .none
            df.dateStyle = .short
            let lastDayOfPeriod = CalendarDay(dateInDay: period.end!).subtract(days: 1)
            period = period.nextCalendarPeriod()!
            balanceOnDay[lastDayOfPeriod] = 0
            group.enter()
        }

        // Store balances when calculated, ensuring data consistency with a
        // mutex.
        let balanceOnDayReadWrite = DispatchSemaphore(value: 1)
        let failedReadWrite = DispatchSemaphore(value: 1)
        balanceCalculator.calculateBalances(for: [goal], on: Array(balanceOnDay.keys), completionQueue: queue) {
            (_ balance: Decimal?, _ day: CalendarDay, _ goal: NSManagedObjectID?) in
            guard let balance = balance else {
                failedReadWrite.wait()
                failed = true
                failedReadWrite.signal()
                group.leave()
                return
            }
            balanceOnDayReadWrite.wait()
            balanceOnDay[day] = balance
            balanceOnDayReadWrite.signal()
            group.leave()
        }

        group.wait()

        if failed {
            completionOnMain(completion, amountUpdated: nil, deleted: nil, inserted: nil)
            return
        }

        CarryOverAdjustmentManager.carryOverWrite.wait()

        let sortedBalances = balanceOnDay.sorted { $0.key < $1.key }
        var currentAdjustments = getCarryOverAdjustments(context: context, goal: goal)
        var updated = Set<Adjustment>()
        var deleted = Set<Adjustment>()
        var inserted = Set<Adjustment>()
        for pair in sortedBalances {
            let day = pair.key.add(days: 1)
            let balance = pair.value

            // Add a carry over adjustment the day after each balance date,
            // with the amount from that balance, or update the balance if it
            // needs to be updated.
            if let index = currentAdjustments.firstIndex(where: { $0.firstDayEffective == day }) {
                // An adjustment already exists on this day. Update it if necessary.
                let adjustment = currentAdjustments[index]
                if adjustment.amountPerDay != balance {
                    let validation = adjustment.propose(
                        amountPerDay: balance
                    )

                    if !validation.valid {
                        context.rollback()
                        completionOnMain(completion, amountUpdated: nil, deleted: nil, inserted: nil)
                        CarryOverAdjustmentManager.carryOverWrite.signal()
                        return
                    }
                    updated.insert(adjustment)
                }
                currentAdjustments.remove(at: index)
            } else {
                // Create an adjustment.
                let adjustment = Adjustment(context: context)
                let validation = adjustment.propose(
                    shortDescription: nil,
                    amountPerDay: balance,
                    firstDayEffective: day,
                    lastDayEffective: day,
                    type: creationType,
                    dateCreated: Date(),
                    goal: goal
                )
                if !validation.valid {
                    context.rollback()
                    completionOnMain(completion, amountUpdated: nil, deleted: nil, inserted: nil)
                    CarryOverAdjustmentManager.carryOverWrite.signal()
                    return
                }
                inserted.insert(adjustment)
            }
        }
        
        // Delete all remaining adjustments in currentAdjustments.
        for adjustment in currentAdjustments {
            deleted.insert(adjustment)
            context.delete(adjustment)
        }
        
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            completionOnMain(completion, amountUpdated: nil, deleted: nil, inserted: nil)
            CarryOverAdjustmentManager.carryOverWrite.signal()
            return
        }
        completionOnMain(completion, amountUpdated: updated, deleted: deleted, inserted: inserted)
        CarryOverAdjustmentManager.carryOverWrite.signal()
    }
    
    /**
     * Returns a goals adjustments in a particular interval that are not carry
     * over adjustments.
     */
    private func getNonCarryOverAdjustments(
        context: NSManagedObjectContext,
        goal: Goal,
        interval: CalendarIntervalProvider
    ) -> [Adjustment] {
        var predicate: NSPredicate
        let descendants = goal.allChildDescendants()
        let isNotCarryOver = "(NOT \(Adjustment.AdjustmentType.isCarryOverAdjustmentPredicateString()))"
        var fs = "\(isNotCarryOver) AND (goal_ = %@ OR goal_ IN %@) AND lastDateEffective_ >= %@"
        if let end = interval.end {
            fs += " AND firstDateEffective_ < %@"
            predicate = NSPredicate(
                format: fs,
                goal,
                descendants ?? [],
                interval.start.gmtDate as CVarArg,
                end.gmtDate as CVarArg
            )
        } else {
            predicate = NSPredicate(
                format: fs,
                goal,
                descendants ?? [],
                interval.start.gmtDate as CVarArg
            )
        }

        return Adjustment.get(context: context, predicate: predicate) ?? []
    }
    
    /**
     * Returns a goal's adjustments in a particular interval that are carry
     * over adjustments.
     *
     * Note that this only returns this goal's carry over adjustments, and not
     * its children's.
     */
    private func getCarryOverAdjustments(
        context: NSManagedObjectContext,
        goal: Goal,
        day: CalendarDay? = nil
    ) -> [Adjustment] {

        var fs = "goal_ = $goal AND " + Adjustment.AdjustmentType.isCarryOverAdjustmentPredicateString()
        if day != nil {
            fs += " AND firstDateEffective_ = $date"
        }

        let predicateTemplate = NSPredicate(format: fs)
        let predicate = predicateTemplate.withSubstitutionVariables([
            "goal": goal,
            "date": day?.start.gmtDate ?? Date(),
        ])

        return Adjustment.get(context: context, predicate: predicate) ?? []
    }
    /**
     * Calls `completion` on the main thread with the given arguments.
     */
    private func completionOnMain(
        _ completion: @escaping CarryOverAdjustmentUpdateCompletion,
        amountUpdated: Set<Adjustment>?,
        deleted: Set<Adjustment>?,
        inserted: Set<Adjustment>?
    ) {
        // Convert all adjustments to their main context equivalents.
        let globalContext = persistentContainer.viewContext
        var mainSets = [Set<Adjustment>?]()

        for set in [amountUpdated, deleted, inserted] {
            var mainSet = set != nil ? Set<Adjustment>() : nil
            for adjustment in set ?? [] {
                if let adjustmentOnMain = globalContext.object(with: adjustment.objectID) as? Adjustment {
                    globalContext.refresh(adjustmentOnMain, mergeChanges: true)
                    mainSet!.insert(adjustmentOnMain)
                } else {
                    DispatchQueue.main.async {
                        completion(nil, nil, nil)
                    }
                    return
                }
            }
            mainSets.append(mainSet)
        }

        DispatchQueue.main.async {
            completion(mainSets[0], mainSets[1], mainSets[2])
        }
    }

    /**
     * Enables a carry over adjustment on a given day if one exists, otherwise
     * returns nil.
     */
    func enableCarryOverAdjustmentForDay(
        for goal: Goal,
        on day: CalendarDay,
        completion: @escaping CarryOverAdjustmentEnableCompletion
    ) {
        if !goal.isRecurring {
            completion(nil)
            return
        }

        self.updateCarryOverAdjustments(for: goal) { (updated, _, _) in
            if updated == nil {
                completion(nil)
                return
            }
            let queueLabel = "com.joshsherick.DailySpend.EnableCarryOverAdjustments"
            let queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
            queue.async {
                self.persistentContainer.performBackgroundTask({ (context) in
                    let goal = context.object(with: goal.objectID) as! Goal

                    CarryOverAdjustmentManager.carryOverWrite.wait()
                    let carryOverDeleted = self.getCarryOverAdjustments(context: context, goal: goal, day: day).filter({ $0.type == .CarryOverDeleted })

                    if carryOverDeleted.count != 1 {
                        completion(nil)
                        return
                    }

                    carryOverDeleted.first!.type = .CarryOver
                    try! context.save()
                    CarryOverAdjustmentManager.carryOverWrite.signal()
                })

                self.updateCarryOverAdjustments(for: goal, completion: { (updated, _, _) in
                    if updated == nil {
                        completion(nil)
                        return
                    }
                    self.persistentContainer.performBackgroundTask({ (context) in
                        CarryOverAdjustmentManager.carryOverWrite.wait()
                        let carryOver = self.getCarryOverAdjustments(context: context, goal: goal, day: day)
                        if carryOver.count != 1 {
                            completion(nil)
                            return
                        }
                        let adjustmentOnViewContext = Adjustment.inContext(carryOver.first!, context: self.persistentContainer.viewContext, refresh: true)
                        DispatchQueue.main.async {
                            completion(adjustmentOnViewContext)
                        }
                        CarryOverAdjustmentManager.carryOverWrite.signal()
                    })
                })
            }
        }
    }

    /**
     * Adds deleted adjustments where there aren't any, and updates amounts for
     * all existing adjustments.
     */
    func performPostImportTasks(
        for goal: Goal,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        let queueLabel = "com.joshsherick.DailySpend.PostImportTasks"
        let queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
        queue.async {
            self.persistentContainer.performBackgroundTask({ (context) in
                let goal = context.object(with: goal.objectID) as! Goal

                if !goal.isRecurring {
                    self.removeAllCarryOver(context: context, for: goal, completion: completion)
                } else {
                    self.updateAdjustments(
                        context: context,
                        for: goal,
                        creationType: .CarryOverDeleted,
                        completion: completion
                    )
                }
            })
        }
    }
}
