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
    
    public func json() -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let amount = amount {
            let num = amount as NSNumber
            jsonObj["amount"] = num
        } else {
            Logger.debug("couldn't unwrap amount in DayAdjustment")
            return nil
        }
        
        if let dateAffected = calendarDayAffected?.gmtDate {
            let num = dateAffected.timeIntervalSince1970 as NSNumber
            jsonObj["dateAffected"] = num
        } else {
            Logger.debug("couldn't unwrap dateAffected in DayAdjustment")
            return nil
        }
        
        if let reason = reason {
            jsonObj["reason"] = reason
        } else {
            Logger.debug("couldn't unwrap reason in DayAdjustment")
            return nil
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in DayAdjustment")
            return nil
        }
        
        return jsonObj
    }
    
    public func serialize() -> Data? {
        if let jsonObj = self.json() {
            let serialization = try? JSONSerialization.data(withJSONObject: jsonObj)
            return serialization
        }
        
        return nil
    }
    
    class func create(context: NSManagedObjectContext,
                      json: [String: Any]) -> DayAdjustment? {
        let dayAdj = DayAdjustment(context: context)
        
        if let amount = json["amount"] as? NSNumber {
            let decimal = Decimal(amount.doubleValue)
            if decimal <= 0 {
                Logger.debug("amount less than 0 in DayAdjustment")
                return nil
            }
            dayAdj.amount = decimal
        } else {
            Logger.debug("couldn't unwrap amount in DayAdjustment")
            return nil
        }
        
        if let dateAffected = json["dateAffected"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateAffected.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay > CalendarDay() ||
                calDay.gmtDate != date {
                // The date is after today or the date isn't a beginning of day.
                Logger.debug("The date is after today or the date isn't a " +
                    "beginning of day in DayAdjustment")
                return nil
            }
            dayAdj.calendarDayAffected = calDay
        } else {
            Logger.debug("couldn't unwrap dateAffected in DayAdjustment")
            return nil
        }
        
        if let reason = json["reason"] as? String {
            if reason.count == 0 {
                Logger.debug("reason is empty in DayAdjustment")
                return nil
            }
            dayAdj.reason = reason
        } else {
            Logger.debug("couldn't unwrap reason in DayAdjustment")
            return nil
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated is after today in DayAdjustment")
                return nil
            }
            dayAdj.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in DayAdjustment")
            return nil
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
    
    public var calendarDayAffected: CalendarDay? {
        get {
            if let dateAffected = dateAffected_ as Date? {
                return CalendarDay(dateInGMTDay: dateAffected)
            } else {
                return nil
            }
            
        }
        set {
            if newValue != nil {
                dateAffected_ = newValue!.gmtDate as NSDate
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

