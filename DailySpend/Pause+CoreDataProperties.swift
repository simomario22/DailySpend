//
//  Pause+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData


extension Pause {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pause> {
        return NSFetchRequest<Pause>(entityName: "Pause")
    }

    @NSManaged public var shortDescription_: String?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var firstDateEffective_: NSDate?
    @NSManaged public var lastDateEffective_: NSDate?
    @NSManaged public var daysAffected_: NSSet?

}

// MARK: Generated accessors for daysAffected_
extension Pause {

    @objc(addDaysAffected_Object:)
    @NSManaged public func addToDaysAffected_(_ value: Day)

    @objc(removeDaysAffected_Object:)
    @NSManaged public func removeFromDaysAffected_(_ value: Day)

    @objc(addDaysAffected_:)
    @NSManaged public func addToDaysAffected_(_ values: NSSet)

    @objc(removeDaysAffected_:)
    @NSManaged public func removeFromDaysAffected_(_ values: NSSet)

}
