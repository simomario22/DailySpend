//
//  Month+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData


extension Month {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Month> {
        return NSFetchRequest<Month>(entityName: "Month");
    }

    @NSManaged public var actualSpend_: NSDecimalNumber?
    @NSManaged public var baseDailyTargetSpend_: NSDecimalNumber?
    @NSManaged public var daysInMonth_: Int64
    @NSManaged public var month_: NSDate?
    @NSManaged public var targetSpend_: NSDecimalNumber?
    @NSManaged public var adjustments_: NSSet?
    @NSManaged public var days_: NSSet?

}

// MARK: Generated accessors for adjustments_
extension Month {

    @objc(addAdjustments_Object:)
    @NSManaged public func addToAdjustments_(_ value: MonthAdjustment)

    @objc(removeAdjustments_Object:)
    @NSManaged public func removeFromAdjustments_(_ value: MonthAdjustment)

    @objc(addAdjustments_:)
    @NSManaged public func addToAdjustments_(_ values: NSSet)

    @objc(removeAdjustments_:)
    @NSManaged public func removeFromAdjustments_(_ values: NSSet)

}

// MARK: Generated accessors for days_
extension Month {

    @objc(addDays_Object:)
    @NSManaged public func addToDays_(_ value: Day)

    @objc(removeDays_Object:)
    @NSManaged public func removeFromDays_(_ value: Day)

    @objc(addDays_:)
    @NSManaged public func addToDays_(_ values: NSSet)

    @objc(removeDays_:)
    @NSManaged public func removeFromDays_(_ values: NSSet)

}
