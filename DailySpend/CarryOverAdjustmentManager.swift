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
    /**
     * Required to write to any carry over adjustments.
     */
    private static let carryOverWrite = DispatchSemaphore(value: 1)

    private let appDelegate = (UIApplication.shared.delegate as! AppDelegate)

    typealias CarryOverAdjustmentCompletion = (_ amountUpdated: Set<Adjustment>?, _ deleted: Set<Adjustment>?, _ inserted: Set<Adjustment>?) -> ()

    /**
     * For a given recurring goal:
     * Updates all existing carry over adjustments that are on the correct day
     * but with the wrong amount. Deletes all carry over adjustments that are
     * on the wrong day. Adds carry over adjustments on days where they should
     * exist but don't.
     *
     * On completion, calls `completion` with the set of adjustments where the
     * value was updated, deleted, and inserted, in that order. If the operation
     * failed, all three values will be `nil`.
     */
    func updateCarryOverAdjustments(
        for goal: Goal,
        completion: @escaping CarryOverAdjustmentCompletion
    ) {
        if !goal.isRecurring {
            completion(nil, nil, nil)
        }
        let queueLabel = "com.joshsherick.DailySpend.GetCarryOverAdjustments"
        let queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
        queue.async {
            self.updateAdjustments(for: goal, completion: completion)
        }
    }
    
    private func updateAdjustments(
        for goal: Goal,
        completion: @escaping CarryOverAdjustmentCompletion
    ) {
        let context = appDelegate.persistentContainer.newBackgroundContext()
        let queueLabel = "com.joshsherick.DailySpend.UpdateAdjustments"
        let queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
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
        let balanceCalculator = GoalBalanceCalculator()
        balanceCalculator.customTotalAdjustmentAmount {
            (goal: Goal, interval: CalendarIntervalProvider) -> Decimal in
            return self.getNonCarryOverAdjustments(goal: goal, interval: interval)
                .reduce(0, {(amount, adjustment) -> Decimal in
                    return amount + adjustment.overlappingAmount(with: interval)
                })
        }
        
        // Store balances when calcualted, ensuring data consistency with a
        // mutex.
        let balanceOnDayReadWrite = DispatchSemaphore(value: 1)
        let failedReadWrite = DispatchSemaphore(value: 1)
        func completedBalance(_ balance: Decimal?, _ day: CalendarDay, _: Goal) {
            guard let balance = balance else {
                failedReadWrite.wait()
                failed = true
                failedReadWrite.signal()
                return
            }
            
            balanceOnDayReadWrite.wait()
            balanceOnDay[day] = balance
            balanceOnDayReadWrite.signal()
        }
        
        // Stop at the period before the most recent one.
        let mostRecentPeriod = goal.mostRecentPeriod()!
        while period.end!.gmtDate <= mostRecentPeriod.start.gmtDate {
            let lastDayOfPeriod = CalendarDay(dateInDay: period.end!).subtract(days: 1)
            period = period.nextCalendarPeriod()!
            queue.async(group: group) {
                balanceCalculator.calculateBalance(for: goal, on: lastDayOfPeriod, completion: completedBalance)
            }
        }
        
        group.wait()
        
        if failed {
            completion(nil, nil, nil)
            return
        }

        CarryOverAdjustmentManager.carryOverWrite.wait()

        let sortedBalances = balanceOnDay.sorted { $0.key < $1.key }
        var currentAdjustments = getCarryOverAdjustments(goal: goal)
        var updated = Set<Adjustment>()
        var deleted = Set<Adjustment>()
        var inserted = Set<Adjustment>()
        var runningBalance: Decimal = 0
        for pair in sortedBalances {
            let day = pair.key.add(days: 1)
            runningBalance = runningBalance + pair.value
            
            // Add a carry over adjustment the day after each balance date,
            // with the amount from that balance, or update the balance if it
            // needs to be updated.
            if let index = currentAdjustments.firstIndex(where: { $0.firstDayEffective == day }) {
                // An adjustment already exists on this day. Update it if necessary.
                let adjustment = currentAdjustments[index]
                if adjustment.amountPerDay != runningBalance {
                    adjustment.amountPerDay = runningBalance
                    updated.insert(adjustment)
                }
                currentAdjustments.remove(at: index)
            } else {
                // Create an adjustment.
                let adjustment = Adjustment(context: context)
                let validation = adjustment.propose(
                    shortDescription: nil,
                    amountPerDay: runningBalance,
                    firstDayEffective: day,
                    lastDayEffective: day,
                    dateCreated: Date(),
                    goal: goal
                )
                if !validation.valid {
                    context.rollback()
                    Logger.debug(validation.problem ?? "There was a problem saving the carry-over adjustment.")
                    completion(nil, nil, nil)
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
            try context.save()
        } catch {
            completion(nil, nil, nil)
            CarryOverAdjustmentManager.carryOverWrite.signal()
            return
        }
        completion(updated, deleted, inserted)
        CarryOverAdjustmentManager.carryOverWrite.signal()
    }
    
    /**
     * Returns a goals adjustments in a particular interval that are not carry
     * over adjustments.
     */
    private func getNonCarryOverAdjustments(goal: Goal, interval: CalendarIntervalProvider) -> [Adjustment] {
        var predicate: NSPredicate
        
        let descendants = goal.allChildDescendants()
        var fs = "type_ != \(Adjustment.AdjustmentType.CarryOver.rawValue) AND "
        fs += "type_ != \(Adjustment.AdjustmentType.CarryOverDeleted.rawValue) AND "
        fs += "(goal_ = %@ OR goal_ IN %@) AND lastDateEffective_ >= %@"
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
     * Returns a goal's adjustments in a particular interval that are not carry
     * over adjustments.
     *
     * Note that this only returns this goal's carry over adjustments, and not
     * its children's.
     */
    private func getCarryOverAdjustments(goal: Goal) -> [Adjustment] {
        var predicate: NSPredicate

        var fs = "goal_ = %@ AND "
        fs += "(type_ != \(Adjustment.AdjustmentType.CarryOver.rawValue) OR "
        fs += "type_ != \(Adjustment.AdjustmentType.CarryOverDeleted.rawValue))"
        predicate = NSPredicate(
            format: fs,
            goal
        )

        return Adjustment.get(context: context, predicate: predicate) ?? []
    }

}
