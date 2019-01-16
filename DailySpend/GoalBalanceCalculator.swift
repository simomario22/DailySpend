//
//  GoalBalanceCalculator.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/1/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class GoalBalanceCalculator {
    private var persistentContainer: NSPersistentContainer
    private var queue: DispatchQueue

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        let queueLabel = "com.joshsherick.DailySpend.CalculateBalance"
        self.queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
    }
    
    typealias BalanceCompletion = (_ balance: Decimal?, _ day: CalendarDay, _ goal: NSManagedObjectID?) -> ()

    /**
     * Calculates the balance for a particular goal for a given set of days,
     * calling `completion` when finished with the result, or `nil` as the first
     * argument if a result could not be computed.
     *
     * `completion` will be executed on `completionQueue`, if provided
     * otherwise `DispatchQueue.main`.
     */
    func calculateBalances(
        for goals: [Goal],
        on days: [CalendarDay],
        completionQueue: DispatchQueue = .main,
        completion: @escaping BalanceCompletion
    ) {
        for goal in goals {
            for day in days {
                queue.async {
                    self.balance(for: goal.objectID, on: day) { (balance, day, goal) in
                        completionQueue.async {
                            completion(balance, day, goal)
                        }
                    }
                }
            }
        }
    }

    /**
     * Calculates the balance for a particular goal on a given day, calling
     * `completion` when finished with the result, or `nil` as the first
     * argument if a result could not be computed.
     */
    func calculateBalance(for goal: Goal, on day: CalendarDay, completionQueue: DispatchQueue = .main, completion: @escaping BalanceCompletion) {
        queue.async {
            self.balance(for: goal.objectID, on: day) { (balance, day, goal) in
                completionQueue.async {
                    completion(balance, day, goal)
                }
            }
        }
    }

    private func balance(
        for goalId: NSManagedObjectID,
        on day: CalendarDay,
        completion: @escaping BalanceCompletion
    ) {
        let context = self.persistentContainer.newBackgroundContext()
        var goal: Goal!
        var interval: CalendarIntervalProvider!
        context.performAndWait {
            goal = Goal.inContext(goalId, context: context) as! Goal?
            interval = goal.periodInterval(for: day.start)
        }

        if interval == nil {
            completion(nil, day, goal.objectID)
            return
        }

        let group = DispatchGroup()

        var totalPaidAmount: Decimal? = nil
        var totalExpenseAmount: Decimal = 0
        var totalAdjustmentAmount: Decimal = 0

        group.enter()
        context.perform {
            totalPaidAmount = self.getTotalPaidAmount(goal, day, interval)
            group.leave()
        }

        group.enter()
        context.perform {
            totalExpenseAmount = self.getTotalExpenses(context, goal, interval)
            group.leave()
        }

        group.enter()
        context.perform {
            totalAdjustmentAmount = self.getTotalAdjustments(context, goal, interval)
            group.leave()
        }

        group.wait()
        var balance: Decimal? = nil
        if let totalPaidAmount = totalPaidAmount {
            balance = totalPaidAmount + totalAdjustmentAmount - totalExpenseAmount
        }
        completion(balance, day, goal.objectID)
    }

    /**
     * A function which, given a goal, an interval within that goal, and
     * a day within that interval, calculates the total amount paid in that goal
     * on that day.
     */
    private var getTotalPaidAmount: (Goal, CalendarDay, CalendarIntervalProvider) -> Decimal? = {
        (goal: Goal, day: CalendarDay, interval: CalendarIntervalProvider) in
        return goal.calculateTotalPaidAmount(for: day, in: interval)
    }
    
    /**
     * Sets a function to use when calculating the total paid amount for a goal.
     *
     * - Parameters:
     *    - calculationFunction: A function which, given a goal, an interval
     *      within that goal, and a day within that interval, calculates the
     *      total amount paid in that goal on that day.
     */
    func customTotalPaidAmount(calculationFunction: @escaping (Goal, CalendarDay, CalendarIntervalProvider) -> Decimal?) {
        getTotalPaidAmount = calculationFunction
    }
    
    /**
     * A function which, given a goal and an interval within that goal,
     * calculates the total amount of the expenses occuring within that interval.
     */
    private var getTotalExpenses: (NSManagedObjectContext, Goal, CalendarIntervalProvider) -> Decimal = {
        (context: NSManagedObjectContext, goal: Goal, interval: CalendarIntervalProvider) in
        return goal.getExpenses(context: context, interval: interval)
            .reduce(0, {(amount, expense) -> Decimal in
                return amount + (expense.amount ?? 0)
            })
    }
    
    /**
     * Sets a function to use when calculating the total expense amount for a
     * goal.
     *
     * - Parameters:
     *    - calculationFunction: A function which, given a goal and an interval
     *      within that goal, calculates the total amount of the expenses occuring
     *      within that interval.
     */
    func customTotalExpenseAmount(calculationFunction: @escaping (NSManagedObjectContext, Goal, CalendarIntervalProvider) -> Decimal) {
        getTotalExpenses = calculationFunction
    }
    
    /**
     * A function which, given a goal and an interval within that goal,
     * calculates the total amount of adjustments occuring within that interval.
     */
    private var getTotalAdjustments: (NSManagedObjectContext, Goal, CalendarIntervalProvider) -> Decimal = {
        (context: NSManagedObjectContext, goal: Goal, interval: CalendarIntervalProvider) in
        return goal.getAdjustments(context: context, interval: interval)
            .reduce(0, {(amount, adjustment) -> Decimal in
                return amount + adjustment.overlappingAmount(with: interval)
            })
    }
    
    /**
     * Sets a function to use when calculating the total expense amount for a
     * goal.
     *
     * - Parameters:
     *    - calculationFunction: A function which, given a goal and an interval
     *      within that goal, calculates the total amount of the adjustments
     *      occuring within that interval.
     */
    func customTotalAdjustmentAmount(calculationFunction: @escaping (NSManagedObjectContext, Goal, CalendarIntervalProvider) -> Decimal) {
        getTotalAdjustments = calculationFunction
    }
}
