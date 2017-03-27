//
//  DayAdjustment+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData


extension DayAdjustment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DayAdjustment> {
        return NSFetchRequest<DayAdjustment>(entityName: "DayAdjustment");
    }

    @NSManaged public var amount_: NSDecimalNumber?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var dateAffected_: NSDate?
    @NSManaged public var reason_: String?
    @NSManaged public var day_: Day?

}
