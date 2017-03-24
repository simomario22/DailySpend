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
    @NSManaged public var date_: NSDate?
    @NSManaged public var shortDescription_: String?
    @NSManaged public var notes_: String?
    @NSManaged public var recordedDate_: NSDate?
    @NSManaged public var day_: Day?

}
