//
//  Pause+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/26/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData


extension Pause {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pause> {
        return NSFetchRequest<Pause>(entityName: "Pause")
    }

    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var firstDateEffective_: NSDate?
    @NSManaged public var lastDateEffective_: NSDate?
    @NSManaged public var shortDescription_: String?
    @NSManaged public var goals_: NSSet?

}

// MARK: Generated accessors for goals_
extension Pause {

    @objc(addGoals_Object:)
    @NSManaged public func addToGoals_(_ value: Goal)

    @objc(removeGoals_Object:)
    @NSManaged public func removeFromGoals_(_ value: Goal)

    @objc(addGoals_:)
    @NSManaged public func addToGoals_(_ values: NSSet)

    @objc(removeGoals_:)
    @NSManaged public func removeFromGoals_(_ values: NSSet)

}
