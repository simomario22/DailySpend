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

    @NSManaged public var month_: NSDate?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var dailyBaseTargetSpend_: NSDecimalNumber?
    @NSManaged public var days_: NSSet?

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
