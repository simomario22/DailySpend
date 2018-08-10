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

    @nonobjc class func fetchRequest() -> NSFetchRequest<Pause> {
        return NSFetchRequest<Pause>(entityName: "Pause")
    }

    @NSManaged var dateCreated_: NSDate?
    @NSManaged var firstDateEffective_: NSDate?
    @NSManaged var lastDateEffective_: NSDate?
    @NSManaged var shortDescription_: String?
    @NSManaged var goals_: NSSet?

}

// MARK: Generated accessors for goals_
extension Pause {

    @objc(addGoals_Object:)
    @NSManaged func addToGoals_(_ value: Goal)

    @objc(removeGoals_Object:)
    @NSManaged func removeFromGoals_(_ value: Goal)

    @objc(addGoals_:)
    @NSManaged func addToGoals_(_ values: NSSet)

    @objc(removeGoals_:)
    @NSManaged func removeFromGoals_(_ values: NSSet)

}
