//
//  Expense+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/26/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData


extension Expense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }

    @NSManaged public var amount_: NSDecimalNumber?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var notes_: String?
    @NSManaged public var shortDescription_: String?
    @NSManaged public var transactionDate_: NSDate?
    @NSManaged public var images_: NSSet?
    @NSManaged public var goals_: NSSet?

}

// MARK: Generated accessors for images_
extension Expense {

    @objc(addImages_Object:)
    @NSManaged public func addToImages_(_ value: Image)

    @objc(removeImages_Object:)
    @NSManaged public func removeFromImages_(_ value: Image)

    @objc(addImages_:)
    @NSManaged public func addToImages_(_ values: NSSet)

    @objc(removeImages_:)
    @NSManaged public func removeFromImages_(_ values: NSSet)

}

// MARK: Generated accessors for goals_
extension Expense {

    @objc(addGoals_Object:)
    @NSManaged public func addToGoals_(_ value: Goal)

    @objc(removeGoals_Object:)
    @NSManaged public func removeFromGoals_(_ value: Goal)

    @objc(addGoals_:)
    @NSManaged public func addToGoals_(_ values: NSSet)

    @objc(removeGoals_:)
    @NSManaged public func removeFromGoals_(_ values: NSSet)

}
