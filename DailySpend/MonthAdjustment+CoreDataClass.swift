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
    
    public func json() -> [String: Any] {
        var jsonObj = [String: Any]()
        
        if let amount = amount {
            let num = amount as NSNumber
            jsonObj["amount"] = num
        }
        
        if let dateEffective = dateEffective {
            let num = dateEffective.timeIntervalSince1970 as NSNumber
            jsonObj["dateEffective"] = num
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
                      json: [String: Any]) -> MonthAdjustment? {
        let monthAdj = MonthAdjustment(context: context)
        
        if let amount = json["amount"] as? NSNumber {
            let decimal = Decimal(amount.doubleValue)
            monthAdj.amount = decimal
        } else {
            return nil
        }
        
        if let dateEffective = json["dateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateEffective.doubleValue)
            monthAdj.dateEffective = date
        } else {
            return nil
        }
        
        if let reason = json["reason"] as? String {
            monthAdj.reason = reason
        } else {
            return nil
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            monthAdj.dateCreated = date
        } else {
            return nil
        }
        
        return monthAdj
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
