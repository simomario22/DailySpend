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
    
    public func json() -> [String: Any] {
        var jsonObj = [String: Any]()
        
        if let amount = amount {
            let num = amount as NSNumber
            jsonObj["amount"] = num
        }
        
        if let dateAffected = dateAffected {
            let num = dateAffected.timeIntervalSince1970 as NSNumber
            jsonObj["dateAffected"] = num
        }
        
        if let reason = reason {
            jsonObj["reason"] = reason
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        }
        return jsonObj
    }
    
    public func serialize() -> Data? {
        let jsonObj = self.json()
        let serialization = try? JSONSerialization.data(withJSONObject: jsonObj)
        return serialization
    }
    
    class func create(context: NSManagedObjectContext,
                      json: [String: Any]) -> DayAdjustment {
        let dayAdj = DayAdjustment(context: context)
        
        if let amount = json["amount"] as? NSNumber {
            let decimal = Decimal(amount.doubleValue)
            dayAdj.amount = decimal
        }
        
        if let dateAffected = json["dateAffected"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateAffected.doubleValue)
            dayAdj.dateAffected = date
        }
        
        if let reason = json["reason"] as? String {
            dayAdj.reason = reason
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            dayAdj.dateCreated = date
        }
        
        return dayAdj
    }
    
    
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

