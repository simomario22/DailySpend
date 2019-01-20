//
//  PaySchedule+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/19/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData


extension PaySchedule {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PaySchedule> {
        return NSFetchRequest<PaySchedule>(entityName: "PaySchedule")
    }

    @NSManaged public var adjustMonthAmountAutomatically_: Bool
    @NSManaged public var amount_: NSDecimalNumber?
    @NSManaged public var dateCreated_: NSDate?
    @NSManaged public var end_: NSDate?
    @NSManaged public var payFrequency_: Int64
    @NSManaged public var payFrequencyMultiplier_: Int64
    @NSManaged public var period_: Int64
    @NSManaged public var periodMultiplier_: Int64
    @NSManaged public var start_: NSDate?
    @NSManaged public var goal_: Goal?

}
