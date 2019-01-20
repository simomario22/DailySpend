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

    typealias CarryOverAdjustmentUpdateCompletion = (_ amountUpdated: Set<NSManagedObjectID>?, _ deleted: Set<NSManagedObjectID>?, _ inserted: Set<NSManagedObjectID>?) -> ()

    /**
     * Creates a carry over adjustment with the previous day's balance.
     */
    func enableCarryOverAdjustment(
        for goal: Goal,
        on day: CalendarDay,
        completionQueue: DispatchQueue = .main,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        queue.async {
            let context = self.persistentContainer.newBackgroundContext()
            context.perform {
                let goal: Goal = Goal.inContext(goal.objectID, context: context)!
                CarryOverAdjustmentManager.carryOverWrite.wait()
                self.enableCarryOverAdjustment(context: context, for: goal, on: day) {
                    (updatedAmount, inserted, deleted) in
                    completionQueue.async {
                        completion(updatedAmount, inserted, deleted)
                        CarryOverAdjustmentManager.carryOverWrite.signal()
                    }
                }
            }
        }
    }

    /**
     * Refreshes a carry over adjustment.
     */
    func refreshCarryOverAdjustment(
        adjustment: Adjustment,
        completionQueue: DispatchQueue = .main,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        queue.async {
            let context = self.persistentContainer.newBackgroundContext()
            context.perform {
                let adjustment: Adjustment = Adjustment.inContext(adjustment.objectID, context: context)!
                CarryOverAdjustmentManager.carryOverWrite.wait()
                self.refreshCarryOverAdjustment(context: context, adjustment: adjustment) {
                    (updatedAmount, inserted, deleted) in
                    completionQueue.async {
                        completion(updatedAmount, inserted, deleted)
                        CarryOverAdjustmentManager.carryOverWrite.signal()
                    }
                }
            }
        }
    }

    /**
     * Refreshes all carry over adjustments.
     */
    func refreshAllCarryOverAdjustments(
        for goal: Goal,
        completionQueue: DispatchQueue = .main,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        queue.async {
            let context = self.persistentContainer.newBackgroundContext()
            context.perform {
                let goal: Goal = Goal.inContext(goal.objectID, context: context)!
                CarryOverAdjustmentManager.carryOverWrite.wait()
                self.refreshAllCarryOverAdjustments(context: context, goal: goal) {
                    (updatedAmount, deleted, inserted) in
                    completionQueue.async {
                        completion(updatedAmount, deleted, inserted)
                        CarryOverAdjustmentManager.carryOverWrite.signal()
                    }
                }
            }
        }
    }

    /**
     * Removes a carry over adjustment.
     */
    func removeCarryOverAdjustment(
        adjustment: Adjustment,
        completionQueue: DispatchQueue = .main,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        queue.async {
            let context = self.persistentContainer.newBackgroundContext()
            context.perform {
                let adjustment: Adjustment = Adjustment.inContext(adjustment.objectID, context: context)!
                CarryOverAdjustmentManager.carryOverWrite.wait()
                self.removeCarryOverAdjustment(context: context, adjustment: adjustment) {
                    (updatedAmount, inserted, deleted) in
                    completionQueue.async {
                        completion(updatedAmount, inserted, deleted)
                        CarryOverAdjustmentManager.carryOverWrite.signal()
                    }
                }
            }
        }
    }


    /**
     * Creates a carry over adjustment with the previous day's balance.
     */
    private func enableCarryOverAdjustment(
        context: NSManagedObjectContext,
        for goal: Goal,
        on day: CalendarDay,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        let adjustments = self.getCarryOverAdjustments(context: context, goal: goal, day: day)
        var createdNewAdjustment = false
        var adjustment: Adjustment
        if adjustments.isEmpty {
            adjustment = Adjustment(context: context)
            createdNewAdjustment = true
        } else {
            adjustment = adjustments.first!
        }

        let previousDay = day.subtract(days: 1)
        let balanceCalc = GoalBalanceCalculator(persistentContainer: self.persistentContainer)
        balanceCalc.calculateBalance(for: goal, on: previousDay, completionQueue: self.queue) {
            (amount, balanceDay, goalId) in
            guard let amount = amount else {
                completion(nil, nil, nil)
                return
            }

            context.perform {
                let validation = adjustment.propose(
                    amountPerDay: amount,
                    firstDayEffective: day,
                    lastDayEffective: day,
                    type: .CarryOver,
                    dateCreated: Date(),
                    goal: goal
                )

                if validation.valid {
                    if context.hasChanges {
                        try! context.save()
                    }
                    if !createdNewAdjustment {
                        completion(Set<NSManagedObjectID>(), Set<NSManagedObjectID>(), Set<NSManagedObjectID>([adjustment.objectID]))
                    } else {
                        // Since this was newly created, we need to make sure
                        // that any intermediary adjustments between this and
                        // the latest adjustment before we created this one are
                        // created, then we can update our amount to get the
                        // proper amount.
                        let type: Adjustment.AdjustmentType = goal.carryOverBalance ? .CarryOver : .CarryOverDeleted
                        self.ensureProperAdjustmentsCreated(context: context, for: goal, creationType: type) { (updated, _, _) in
                            if updated == nil {
                                context.rollback()
                                completion(nil, nil, nil)
                                return
                            }
                            self.refreshCarryOverAdjustment(context: context, adjustment: adjustment) { (updated, _, _) in
                                if updated == nil {
                                    context.rollback()
                                    completion(nil, nil, nil)
                                    return
                                }
                                completion(Set<NSManagedObjectID>(), Set<NSManagedObjectID>(), Set<NSManagedObjectID>([adjustment.objectID]))
                            }
                        };
                    }
                } else {
                    context.rollback()
                    completion(nil, nil, nil)
                }
            }
        }
    }

    /**
     * Refreshes a carry over adjustment.
     */
    private func refreshCarryOverAdjustment(
        context: NSManagedObjectContext,
        adjustment: Adjustment,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        let previousDay = adjustment.firstDayEffective!.subtract(days: 1)
        let balanceCalc = GoalBalanceCalculator(persistentContainer: self.persistentContainer)
        balanceCalc.calculateBalance(for: adjustment.goal!, on: previousDay, completionQueue: self.queue) {
            (amount, balanceDay, goalId) in
            guard let amount = amount else {
                completion(nil, nil, nil)
                return
            }
            context.perform {
                let validation = adjustment.propose(
                    amountPerDay: amount
                )

                if validation.valid {
                    if context.hasChanges {
                        try! context.save()
                    }
                    completion(Set<NSManagedObjectID>([adjustment.objectID]), Set<NSManagedObjectID>(), Set<NSManagedObjectID>())
                } else {
                    context.rollback()
                    completion(nil, nil, nil)
                }
            }
        }
    }

    func refreshAllCarryOverAdjustments(
        context: NSManagedObjectContext,
        goal: Goal,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        let adjustments = self.getCarryOverAdjustments(context: context, goal: goal)
        var adjustmentDays = [CalendarDay: Adjustment]()
        let group = DispatchGroup()
        for adjustment in adjustments {
            let previousDay = adjustment.firstDayEffective!.subtract(days: 1)
            adjustmentDays[previousDay] = adjustment
            group.enter()
        }

        var failed = false
        let failedWrite = DispatchSemaphore(value: 1)
        let balanceCalculator = GoalBalanceCalculator(persistentContainer: self.persistentContainer)
        balanceCalculator.calculateBalances(for: [goal], on: Array(adjustmentDays.keys), completionQueue: queue) {
             (_ balance: Decimal?, _ day: CalendarDay, _ goal: NSManagedObjectID?) in
            guard let balance = balance else {
                failedWrite.wait()
                failed = true
                failedWrite.signal()
                group.leave()
                return
            }
            context.perform {
                let adjustment = adjustmentDays[day]
                let validation = adjustment!.propose(amountPerDay: balance)
                if !validation.valid {
                    failedWrite.wait()
                    failed = true
                    failedWrite.signal()
                }
                group.leave()
            }
        }

        group.notify(queue: queue) {
            context.perform {
                if failed {
                    context.rollback()
                    completion(nil, nil, nil)
                    return
                }

                if context.hasChanges {
                    try! context.save()
                }

                let updatedAmount = Set<NSManagedObjectID>(adjustments.map{ $0.objectID })
                completion(updatedAmount, Set<NSManagedObjectID>(), Set<NSManagedObjectID>())
            }
        }
    }

    /**
     * Removes a carry over adjustment.
     */
    private func removeCarryOverAdjustment(
        context: NSManagedObjectContext,
        adjustment: Adjustment,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        let validation = adjustment.propose(type: .CarryOverDeleted)
        if validation.valid {
            if context.hasChanges {
                try! context.save()
            }
            completion(Set<NSManagedObjectID>(), Set<NSManagedObjectID>([adjustment.objectID]), Set<NSManagedObjectID>())
        } else {
            context.rollback()
            completion(nil, nil, nil)
        }
    }


    /**
     * For a given goal:
     * Deletes all carry over adjustments that are on the wrong day. Adds carry
     * over adjustments on days where they should exist but don't.
     *
     * On completion, calls `completion` with the set of adjustments where the
     * value was updated, deleted, and inserted, in that order. If the operation
     * failed, all three values will be `nil`.
     */
    func ensureProperAdjustmentsCreated(
        for goal: Goal,
        completionQueue: DispatchQueue = .main,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        queue.async {
            let context = self.persistentContainer.newBackgroundContext()
            context.perform {
                let goal: Goal = Goal.inContext(goal.objectID, context: context)!
                CarryOverAdjustmentManager.carryOverWrite.wait()
                self.ensureProperAdjustmentsCreated(
                    context: context,
                    for: goal,
                    creationType: goal.carryOverBalance ? .CarryOver : .CarryOverDeleted
                ) {
                    (amountUpdated, deleted, inserted) in
                    completionQueue.async {
                        completion(amountUpdated, deleted, inserted)
                        CarryOverAdjustmentManager.carryOverWrite.signal()
                    }
                }
            }
        }
    }

    /**
     * For a given goal:
     * Deletes all carry over adjustments that are on the wrong day. Adds carry
     * over adjustments on days where they should exist but don't, and sets
     * their balances. Does not update existing goal's balances.
     *
     * Depending on the value of the goal
     *
     * - Parameters:
     *    - creationType: The type with which any adjustments created as part of
     *      this process will be created with.
     */
    private func ensureProperAdjustmentsCreated(
        context: NSManagedObjectContext,
        for goal: Goal,
        creationType: Adjustment.AdjustmentType,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        // A map from calendar days to amounts
        var carryOverOnDay = [CalendarDay: Decimal]()
        let carryOverOnDayWrite = DispatchSemaphore(value: 1)
        
        // Start from the first period.
        guard let firstDate = goal.startOfFirstPaySchedule() else {
            Logger.debug("Could not find start of first pay schedule for goal \(goal.shortDescription ?? "").")
            completion(nil, nil, nil)
            return
        }
        var period = GoalPeriod(
            goal: goal,
            date: firstDate,
            style: .period
        )

        let balanceCalculator = GoalBalanceCalculator(persistentContainer: persistentContainer)

        // Get current adjustments.
        var currentAdjustments = getCarryOverAdjustments(context: context, goal: goal)

        // Create adjustments to the current period, or the latest valid carry
        // over adjustment, whichever is later.
        // It doesn't make sense to create carry over adjustment past today in
        // most cases, since they won't be up to date. However, this will allow
        // us to support that case if they have explicitly added an expense.
        let today = CalendarDay()
        let latestAdjustment = currentAdjustments.max { $0.firstDayEffective! < $1.firstDayEffective! }
        let latestDay = latestAdjustment != nil ? max(today, latestAdjustment!.firstDayEffective!) : today
        let mostRecentPeriod = goal.periodInterval(for: latestDay.start)

        let group = DispatchGroup()
        var failed = false
        let failedWrite = DispatchSemaphore(value: 1)
        while period != nil && mostRecentPeriod != nil &&
            (period!.end!.gmtDate <= mostRecentPeriod!.start.gmtDate) {
            let adjustmentDay = CalendarDay(dateInDay: period!.end!)
            if let index = currentAdjustments.firstIndex(where: { $0.firstDayEffective == adjustmentDay }) {
                // There's already an adjustment for this day - mark it as
                // correct by removing it from the current adjustments array.
                currentAdjustments.remove(at: index)
            } else {
                // Calculate the carry over amount for this day (the balance on
                // the previous day) to use for this adjustment.
                group.enter()
                balanceCalculator.calculateBalance(for: goal, on: adjustmentDay.subtract(days: 1), completionQueue: queue) {
                    (balance, balanceDay, goalId) in
                    guard let balance = balance else {
                        failedWrite.wait()
                        failed = true
                        failedWrite.signal()
                        group.leave()
                        return
                    }
                    carryOverOnDayWrite.wait()
                    carryOverOnDay[adjustmentDay] = balance
                    carryOverOnDayWrite.signal()
                    group.leave()
                }
            }
            period = period!.nextGoalPeriod()
        }

        group.wait()

        if failed {
            completion(nil, nil, nil)
            return
        }

        var insertedAdjustments = Set<Adjustment>()

        let sortedBalances = carryOverOnDay.sorted { $0.key < $1.key }
        var runningBalance: Decimal = 0
        for (day, balance) in sortedBalances {
            runningBalance += balance
            let adjustment = Adjustment(context: context)
            let validation = adjustment.propose(
                amountPerDay: runningBalance,
                firstDayEffective: day,
                lastDayEffective: day,
                type: creationType,
                dateCreated: Date(),
                goal: goal
            )

            if validation.valid {
                insertedAdjustments.insert(adjustment)
            } else {
                context.rollback()
                completion(nil, nil, nil)
                return
            }
        }

        var deleted = Set<NSManagedObjectID>()
        // Delete all remaining adjustments in currentAdjustments.
        for adjustment in currentAdjustments {
            deleted.insert(adjustment.objectID)
            context.delete(adjustment)
        }

        if context.hasChanges {
            try! context.save()
        }

        let inserted = Set<NSManagedObjectID>(insertedAdjustments.map({ $0.objectID }))
        completion(Set<NSManagedObjectID>(), deleted, inserted)
    }

    /**
     * Adds deleted adjustments where there aren't any, and updates amounts for
     * all existing adjustments.
     */
    func performPostImportTasks(
        for goal: Goal,
        completionQueue: DispatchQueue = .main,
        completion: @escaping CarryOverAdjustmentUpdateCompletion
    ) {
        self.ensureProperAdjustmentsCreated(for: goal, completionQueue: completionQueue, completion: completion)
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
}
