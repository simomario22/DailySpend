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
    @NSManaged var goal_: Goal?

}
