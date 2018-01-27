//
//  Goal+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/26/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData


extension Goal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Goal> {
        return NSFetchRequest<Goal>(entityName: "Goal")
    }

    @NSManaged public var archived_: Bool
    @NSManaged public var period_: Int64
    @NSManaged public var reconciled_: Int64
    @NSManaged public var jsonId_: Int64
    @NSManaged public var start_: NSDate?
    @NSManaged public var end_: NSDate?
    @NSManaged public var amount_: NSDate?
    @NSManaged public var shortDescription_: String?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var expenses_: NSSet?
    @NSManaged public var adjustments_: NSSet?
    @NSManaged public var pauses_: NSSet?
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
