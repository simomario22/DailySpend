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

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Goal> {
        return NSFetchRequest<Goal>(entityName: "Goal")
    }

    @NSManaged public var amount_: NSDecimalNumber?
    @NSManaged public var archived_: Bool
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var end_: NSDate?
    @NSManaged public var period_: Int64
    @NSManaged public var reconcileFrequency_: Int64
    @NSManaged public var reconcileFrequencyMultiplier_: Int64
    @NSManaged public var shortDescription_: String?
    @NSManaged public var start_: NSDate?
    @NSManaged public var periodMultiplier_: Int64
    @NSManaged public var adjustments_: NSSet?
    @NSManaged public var expenses_: NSSet?
    @NSManaged public var pauses_: NSSet?
    @NSManaged public var parentGoal_: Goal?
    @NSManaged public var childGoals_: NSSet?

}

// MARK: Generated accessors for adjustments_
extension Goal {

    @objc(addAdjustments_Object:)
    @NSManaged public func addToAdjustments_(_ value: Adjustment)

    @objc(removeAdjustments_Object:)
    @NSManaged public func removeFromAdjustments_(_ value: Adjustment)

    @objc(addAdjustments_:)
    @NSManaged public func addToAdjustments_(_ values: NSSet)

    @objc(removeAdjustments_:)
    @NSManaged public func removeFromAdjustments_(_ values: NSSet)

}

// MARK: Generated accessors for expenses_
extension Goal {

    @objc(addExpenses_Object:)
    @NSManaged public func addToExpenses_(_ value: Expense)

    @objc(removeExpenses_Object:)
    @NSManaged public func removeFromExpenses_(_ value: Expense)

    @objc(addExpenses_:)
    @NSManaged public func addToExpenses_(_ values: NSSet)

    @objc(removeExpenses_:)
    @NSManaged public func removeFromExpenses_(_ values: NSSet)

}

// MARK: Generated accessors for pauses_
extension Goal {

    @objc(addPauses_Object:)
    @NSManaged public func addToPauses_(_ value: Pause)

    @objc(removePauses_Object:)
    @NSManaged public func removeFromPauses_(_ value: Pause)

    @objc(addPauses_:)
    @NSManaged public func addToPauses_(_ values: NSSet)

    @objc(removePauses_:)
    @NSManaged public func removeFromPauses_(_ values: NSSet)

}

// MARK: Generated accessors for childGoals_
extension Goal {

    @objc(addChildGoals_Object:)
    @NSManaged public func addToChildGoals_(_ value: Goal)

    @objc(removeChildGoals_Object:)
    @NSManaged public func removeFromChildGoals_(_ value: Goal)

    @objc(addChildGoals_:)
    @NSManaged public func addToChildGoals_(_ values: NSSet)

    @objc(removeChildGoals_:)
    @NSManaged public func removeFromChildGoals_(_ values: NSSet)

}
