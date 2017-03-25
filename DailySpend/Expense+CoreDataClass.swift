//
//  Expense+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

@objc(Expense)
public class Expense: NSManagedObject {
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
    
    public var date: Date? {
        get {
            return date_ as Date?
        }
        set {
            if newValue != nil {
                date_ = newValue! as NSDate
            } else {
                date_ = nil
            }
        }
    }
    
    public var recordedDate: Date? {
        get {
            return recordedDate_ as Date?
        }
        set {
            if newValue != nil {
                recordedDate_ = newValue! as NSDate
            } else {
                recordedDate_ = nil
            }
        }
    }
    
    public var shortDescription: String? {
        get {
            return shortDescription_
        }
        set {
            shortDescription_ = newValue
        }
    }
    
    public var notes: String? {
        get {
            return notes_
        }
        set {
            notes_ = newValue
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
