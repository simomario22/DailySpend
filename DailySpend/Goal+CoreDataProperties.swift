//
//  Goal+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 2/12/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData

extension Goal {

    @nonobjc class func fetchRequest() -> NSFetchRequest<Goal> {
        return NSFetchRequest<Goal>(entityName: "Goal")
    }

    @NSManaged var amount_: NSDecimalNumber?
    @NSManaged var alwaysCarryOver_: Bool
    @NSManaged var adjustMonthAmountAutomatically_: Bool
    @NSManaged var dateCreated_: NSDate?
    @NSManaged var end_: NSDate?
    @NSManaged var period_: Int64
    @NSManaged var payFrequency_: Int64
    @NSManaged var payFrequencyMultiplier_: Int64
    @NSManaged var shortDescription_: String?
    @NSManaged var start_: NSDate?
    @NSManaged var periodMultiplier_: Int64
    @NSManaged var adjustments_: NSSet?
    @NSManaged var expenses_: NSSet?
    @NSManaged var pauses_: NSSet?
    @NSManaged var parentGoal_: Goal?
    @NSManaged var childGoals_: NSSet?

}

// MARK: Generated accessors for adjustments_
extension Goal {

    @objc(addAdjustments_Object:)
    @NSManaged func addToAdjustments_(_ value: Adjustment)

    @objc(removeAdjustments_Object:)
    @NSManaged func removeFromAdjustments_(_ value: Adjustment)

    @objc(addAdjustments_:)
    @NSManaged func addToAdjustments_(_ values: NSSet)

    @objc(removeAdjustments_:)
    @NSManaged func removeFromAdjustments_(_ values: NSSet)

}

// MARK: Generated accessors for expenses_
extension Goal {

    @objc(addExpenses_Object:)
    @NSManaged func addToExpenses_(_ value: Expense)

    @objc(removeExpenses_Object:)
    @NSManaged func removeFromExpenses_(_ value: Expense)

    @objc(addExpenses_:)
    @NSManaged func addToExpenses_(_ values: NSSet)

    @objc(removeExpenses_:)
    @NSManaged func removeFromExpenses_(_ values: NSSet)

}

// MARK: Generated accessors for pauses_
extension Goal {

    @objc(addPauses_Object:)
    @NSManaged func addToPauses_(_ value: Pause)

    @objc(removePauses_Object:)
    @NSManaged func removeFromPauses_(_ value: Pause)

    @objc(addPauses_:)
    @NSManaged func addToPauses_(_ values: NSSet)

    @objc(removePauses_:)
    @NSManaged func removeFromPauses_(_ values: NSSet)

}

// MARK: Generated accessors for childGoals_
extension Goal {

    @objc(addChildGoals_Object:)
    @NSManaged func addToChildGoals_(_ value: Goal)

    @objc(removeChildGoals_Object:)
    @NSManaged func removeFromChildGoals_(_ value: Goal)

    @objc(addChildGoals_:)
    @NSManaged func addToChildGoals_(_ values: NSSet)

    @objc(removeChildGoals_:)
    @NSManaged func removeFromChildGoals_(_ values: NSSet)

}
