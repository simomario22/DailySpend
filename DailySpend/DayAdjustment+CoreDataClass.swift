//
//  DayAdjustment+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

@objc(DayAdjustment)
public class DayAdjustment: NSManagedObject {
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
    
    public var dateAffected: Date? {
        get {
            return dateAffected_ as Date?
        }
        set {
            if newValue != nil {
                dateAffected_ = newValue! as NSDate
            } else {
                dateAffected_ = nil
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
    
    public var day: Day? {
        get {
            return day_
        }
        set {
            day_ = newValue
        }
    }
}

