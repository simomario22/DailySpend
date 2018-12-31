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

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    typealias BalanceCompletion = (_ balance: Decimal?, _ day: CalendarDay, _ goal: Goal?) -> ()
    
    /**
     * Calculates the balance for particular goals on a given day, calling
     * `completion` when finished with the result, or `nil` as the first
     * argument if a result could not be computed.
     */
    func calculateBalance(for goals: [Goal], on day: CalendarDay, completion: @escaping BalanceCompletion) {
        for goal in goals {
            let queueLabel = "com.joshsherick.DailySpend.CalculateBalance"
            let queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
            queue.async {
                self.persistentContainer.performBackgroundTask({ (context) in
                    let goal = context.object(with: goal.objectID) as! Goal
                    self.balance(context: context, for: goal, on: day, completion: completion)
                })
            }
        }
    }

    /**
     * Calculates the balance for a particular goal on a given day, calling
     * `completion` when finished with the result, or `nil` as the first
     * argument if a result could not be computed.
     */
    func calculateBalance(for goal: Goal, on day: CalendarDay, completion: @escaping BalanceCompletion) {
        let queueLabel = "com.joshsherick.DailySpend.CalculateBalance"
        let queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
        queue.async {
            self.persistentContainer.performBackgroundTask({ (context) in
                let goal = context.object(with: goal.objectID) as! Goal
                self.balance(context: context, for: goal, on: day, completion: completion)
            })
        }
    }
    
    /**
     * Compute the balance amount in this goal on a particular day.
     *
     * - Parameters:
     *    - goal: The goal to compute the balance for.
     *    - day: The day to compute the balance for.
     *
     * - Returns: The balance for `goal` on `day`, taking into account periods,
     *            interval pay, and expenses.
     */
    private func balance(
        context: NSManagedObjectContext,
        for goal: Goal,
        on day: CalendarDay,
        completion: @escaping BalanceCompletion
    ) {
        guard let interval = goal.periodInterval(for: day.start) else {
            completionOnMain(completion, balance: nil, day: day, goal: goal)
            return
        }
        let id = goal.objectID.uriRepresentation()
        let queueLabel = "com.joshsherick.DailySpend.CalculateBalance_\(id)"
        let queue = DispatchQueue(label: queueLabel, qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        
        var totalPaidAmount: Decimal? = nil
        var totalExpenseAmount: Decimal = 0
        var totalAdjustmentAmount: Decimal = 0

        group.enter()
        queue.async {
            self.persistentContainer.performBackgroundTask({ (context) in
                let goal = context.object(with: goal.objectID) as! Goal
                totalPaidAmount = self.getTotalPaidAmount(goal, day, interval)
                group.leave()
            })
        }

        group.enter()
        queue.async {
            self.persistentContainer.performBackgroundTask({ (context) in
                let goal = context.object(with: goal.objectID) as! Goal
                totalExpenseAmount = self.getTotalExpenses(context, goal, interval)
                group.leave()
            })
        }

        group.enter()
        queue.async {
            self.persistentContainer.performBackgroundTask({ (context) in
                let goal = context.object(with: goal.objectID) as! Goal
                totalAdjustmentAmount = self.getTotalAdjustments(context, goal, interval)
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            var balance: Decimal? = nil
            if let totalPaidAmount = totalPaidAmount {
                balance = totalPaidAmount + totalAdjustmentAmount - totalExpenseAmount
            }
            self.completionOnMain(completion, balance: balance, day: day, goal: goal)
        }
    }

    /**
     * Calls `completion` on the main thread with the given arguments.
     */
    private func completionOnMain(
        _ completion: @escaping BalanceCompletion,
        balance: Decimal?,
        day: CalendarDay,
        goal: Goal
    ) {
        if let goalOnMain = persistentContainer.viewContext.object(with: goal.objectID) as? Goal {
            DispatchQueue.main.async {
                completion(balance, day, goalOnMain)
            }
        } else {
            DispatchQueue.main.async {
                completion(nil, day, nil)
            }

        }
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
