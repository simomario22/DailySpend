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

    @nonobjc class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }

    @NSManaged var amount_: NSDecimalNumber?
    @NSManaged var dateCreated_: NSDate?
    @NSManaged var notes_: String?
    @NSManaged var shortDescription_: String?
    @NSManaged var transactionDate_: NSDate?
    @NSManaged var images_: NSSet?
    @NSManaged var goal_: Goal?
}

// MARK: Generated accessors for images_
extension Expense {

    @objc(addImages_Object:)
    @NSManaged func addToImages_(_ value: Image)

    @objc(removeImages_Object:)
    @NSManaged  func removeFromImages_(_ value: Image)

    @objc(addImages_:)
    @NSManaged func addToImages_(_ values: NSSet)

    @objc(removeImages_:)
    @NSManaged func removeFromImages_(_ values: NSSet)

}
