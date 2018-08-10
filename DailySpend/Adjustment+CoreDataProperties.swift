//
//  Adjustment+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/26/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData


extension Adjustment {

    @nonobjc class func fetchRequest() -> NSFetchRequest<Adjustment> {
        return NSFetchRequest<Adjustment>(entityName: "Adjustment")
    }

    @NSManaged var amountPerDay_: NSDecimalNumber?
    @NSManaged var dateCreated_: NSDate?
    @NSManaged var firstDateEffective_: NSDate?
    @NSManaged var lastDateEffective_: NSDate?
    @NSManaged var shortDescription_: String?
    @NSManaged var goals_: NSSet?

}

// MARK: Generated accessors for goals_
extension Adjustment {

    @objc(addGoals_Object:)
    @NSManaged func addToGoals_(_ value: Goal)

    @objc(removeGoals_Object:)
    @NSManaged func removeFromGoals_(_ value: Goal)

    @objc(addGoals_:)
    @NSManaged func addToGoals_(_ values: NSSet)

    @objc(removeGoals_:)
    @NSManaged func removeFromGoals_(_ values: NSSet)

}
