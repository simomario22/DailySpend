//
//  Day+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData


extension Day {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Day> {
        return NSFetchRequest<Day>(entityName: "Day");
    }

    @NSManaged public var date_: NSDate?
    @NSManaged public var adjustments_: NSSet?
    @NSManaged public var expenses_: NSSet?
    @NSManaged public var pause_: Pause?
    @NSManaged public var month_: Month?
    @NSManaged public var dateCreated_: NSDate?

}

// MARK: Generated accessors for adjustments_
extension Day {

    @objc(addAdjustments_Object:)
    @NSManaged public func addToAdjustments_(_ value: DayAdjustment)

    @objc(removeAdjustments_Object:)
    @NSManaged public func removeFromAdjustments_(_ value: DayAdjustment)

    @objc(addAdjustments_:)
    @NSManaged public func addToAdjustments_(_ values: NSSet)

    @objc(removeAdjustments_:)
    @NSManaged public func removeFromAdjustments_(_ values: NSSet)

}

// MARK: Generated accessors for expenses_
extension Day {

    @objc(addExpenses_Object:)
    @NSManaged public func addToExpenses_(_ value: Expense)

    @objc(removeExpenses_Object:)
    @NSManaged public func removeFromExpenses_(_ value: Expense)

    @objc(addExpenses_:)
    @NSManaged public func addToExpenses_(_ values: NSSet)

    @objc(removeExpenses_:)
    @NSManaged public func removeFromExpenses_(_ values: NSSet)

}
