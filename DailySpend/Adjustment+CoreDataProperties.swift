//
//  Adjustment+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 10/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData

extension Adjustment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Adjustment> {
        return NSFetchRequest<Adjustment>(entityName: "Adjustment")
    }

    @NSManaged public var shortDescription_: String?
    @NSManaged public var firstDateEffective_: NSDate?
    @NSManaged public var lastDateEffective_: NSDate?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var amountPerDay_: NSDecimalNumber?
    @NSManaged public var daysAffected_: NSSet?

}

// MARK: Generated accessors for daysAffected_
extension Adjustment {

    @objc(addDaysAffected_Object:)
    @NSManaged public func addToDaysAffected_(_ value: Day)

    @objc(removeDaysAffected_Object:)
    @NSManaged public func removeFromDaysAffected_(_ value: Day)

    @objc(addDaysAffected_:)
    @NSManaged public func addToDaysAffected_(_ values: NSSet)

    @objc(removeDaysAffected_:)
    @NSManaged public func removeFromDaysAffected_(_ values: NSSet)

}
