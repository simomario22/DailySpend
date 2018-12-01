//
//  GoalBalanceCache.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/1/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class GoalBalanceCache {
    /**
     * Returns a unique string associated with a particular goal.
     */
    private func keyForGoal(goal: Goal) -> String {
        let id = goal.objectID.uriRepresentation()
        return "mostRecentComputedAmount_\(id)"
    }
    
    /**
     * Retrieves the amount most recently displayed balance to the user for the
     * day they viewed it, persisting across app termination.
     */
    func mostRecentlyDisplayedBalance(goal: Goal) -> Double {
        return UserDefaults.standard.double(forKey: keyForGoal(goal: goal))
    }
    
    /**
     * Sets the amount most recently displayed balance to the user for the day
     * they viewed it, persisting across app termination.
     */
    func setMostRecentlyDisplayedBalance(goal: Goal, amount: Double) {
        UserDefaults.standard.set(amount, forKey: keyForGoal(goal: goal))
    }
}
