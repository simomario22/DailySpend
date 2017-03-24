//
//  MonthAdjustment+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData


extension MonthAdjustment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MonthAdjustment> {
        return NSFetchRequest<MonthAdjustment>(entityName: "MonthAdjustment");
    }

    @NSManaged public var amount_: NSDecimalNumber?
    @NSManaged public var dateEffective_: NSDate?
    @NSManaged public var reason_: String?
    @NSManaged public var month_: Month?

}
