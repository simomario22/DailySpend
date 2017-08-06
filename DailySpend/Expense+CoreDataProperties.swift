//
//  Expense+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData


extension Expense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense");
    }

    @NSManaged public var amount_: NSDecimalNumber?
    @NSManaged public var shortDescription_: String?
    @NSManaged public var notes_: String?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var day_: Day?
    @NSManaged public var images_: NSSet?

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
