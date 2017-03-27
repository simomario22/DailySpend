//
//  MonthAdjustment+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

@objc(MonthAdjustment)
public class MonthAdjustment: NSManagedObject {
    // Accessor functions (for Swift 3 classes)

    public var amount: Decimal? {
        get {
            return amount_ as Decimal?
        }
        set {
            if newValue != nil {
                amount_ = NSDecimalNumber(decimal: newValue!)
            } else {
                amount_ = nil
            }
        }
    }
    
    public var dateEffective: Date? {
        get {
            return dateEffective_ as Date?
        }
        set {
            if newValue != nil {
                dateEffective_ = newValue! as NSDate
            } else {
                dateEffective_ = nil
            }
        }
    }
    
    public var dateCreated: Date? {
        get {
            return dateCreated_ as Date?
        }
        set {
            if newValue != nil {
                dateCreated_ = newValue! as NSDate
            } else {
                dateCreated_ = nil
            }
        }
    }
    
    public var reason: String? {
        get {
            return reason_
        }
        set {
            reason_ = newValue
        }
    }
    
    public var month: Month? {
        get {
            return month_
        }
        set {
            month_ = newValue
        }
    }

}
