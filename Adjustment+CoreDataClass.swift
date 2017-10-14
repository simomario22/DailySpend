//
//  Adjustment+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 10/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Adjustment)
public class Adjustment: NSManagedObject {
    public func json() -> [String: Any]? {
        var jsonObj = [String: Any]()

        if let amountPerDay = amountPerDay {
            let num = amountPerDay as NSNumber
            jsonObj["amountPerDay"] = num
        } else {
            Logger.debug("couldn't unwrap amountPerDay in Adjustment")
            return nil
        }

        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Adjustment")
            return nil
        }
        
        if let date = firstDayEffective?.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["firstDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Adjustment")
            return nil
        }
        
        if let date = lastDayEffective?.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["lastDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap lastDateEffective in Adjustment")
            return nil
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Adjustment")
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
                      json: [String: Any]) -> Adjustment? {
        let adjustment = Adjustment(context: context)

        if let amountPerDay = json["amountPerDay"] as? NSNumber {
            let decimal = Decimal(amountPerDay.doubleValue)
            if decimal <= 0 {
                Logger.debug("amountPerDay less than 0 in Adjustment")
                return nil
            }
            adjustment.amountPerDay = decimal
        } else {
            Logger.debug("couldn't unwrap amountPerDay in Adjustment")
            return nil
        }

        if let dateNumber = json["firstDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay.gmtDate != date {
                // The date isn't a beginning of day
                Logger.debug("The firstDateEffective isn't a beginning of day in Adjustment")
                return nil
            }
            adjustment.firstDayEffective = calDay
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Adjustment")
            return nil
        }

        if let dateNumber = json["lastDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay.gmtDate != date ||
                calDay < adjustment.firstDayEffective! {
                // The date isn't a beginning of day
                Logger.debug("The lastDateEffective isn't a beginning of day or is earlier than firstDateEffective in Adjustment")
                return nil
            }
            adjustment.lastDayEffective = calDay
        } else {
            Logger.debug("couldn't unwrap lastDateEffective in Adjustment")
            return nil
        }

        if let shortDescription = json["shortDescription"] as? String {
            if shortDescription.characters.count == 0 {
                Logger.debug("shortDescription empty in Adjustment")
                return nil
            }
            adjustment.shortDescription = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Adjustment")
            return nil
        }

        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Adjustment")
                return nil
            }
            adjustment.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in Adjustment")
            return nil
        }

        // Get relevant days.
        let relevantDays = Day.getRelevantDaysForAdjustment(adjustment: adjustment, context: context)
        adjustment.daysAffected = Set<Day>(relevantDays)

        return adjustment
    }
    
    class func get(context: NSManagedObjectContext,
                   predicate: NSPredicate? = nil,
                   sortDescriptors: [NSSortDescriptor]? = nil,
                   fetchLimit: Int = 0) -> [Adjustment]? {
        let fetchRequest: NSFetchRequest<Adjustment> = Adjustment.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        
        let adjustmentResults = try? context.fetch(fetchRequest)
        
        return adjustmentResults
    }
    
    /*
     * Return the adjustments that affect a certain day.
     */
    class func getRelevantAdjustmentsForDay(day: Day, context: NSManagedObjectContext) -> [Adjustment] {
        let fetchRequest: NSFetchRequest<Adjustment> = Adjustment.fetchRequest()
        let pred = NSPredicate(format: "firstDateEffective_ <= %@ AND lastDateEffective_ >= %@",
                               day.calendarDay!.gmtDate as CVarArg, day.calendarDay!.gmtDate as CVarArg)
        fetchRequest.predicate = pred
        let sortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        fetchRequest.sortDescriptors = [sortDesc]
        let adjustmentResults = try! context.fetch(fetchRequest)
        
        return adjustmentResults
    }
    
    func validate(context: NSManagedObjectContext) -> (valid: Bool, problem: String?) {
        if self.amountPerDay == nil || self.amountPerDay! <= 0 {
            return (false, "This adjustment must have an amount greater than 0.")
        }
        
        if self.shortDescription == nil || self.shortDescription!.characters.count == 0 {
            return (false, "This adjustment must have a description.")
        }
        
        if self.firstDayEffective == nil || self.lastDayEffective == nil ||
            self.firstDayEffective! > self.lastDayEffective! {
            return (false, "The first day effective must not be after the last day effective.")
        }
        
        if self.dateCreated == nil {
            return (false, "The pause must have a date created.")
        }

        return (true, nil)
    }
    
    // Accessor functions (for Swift 3 classes)
    
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
    
    public var shortDescription: String? {
        get {
            return shortDescription_
        }
        set {
            shortDescription_ = newValue
        }
    }
    
    public var amountPerDay: Decimal? {
        get {
            return amountPerDay_ as Decimal?
        }
        set {
            if newValue != nil {
                amountPerDay_ = NSDecimalNumber(decimal: newValue!)
            } else {
                amountPerDay_ = nil
            }
        }
    }
    
    public var firstDayEffective: CalendarDay? {
        get {
            if let day = firstDateEffective_ as Date? {
                return CalendarDay(dateInGMTDay: day)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                // Get relevant days.
                firstDateEffective_ = newValue!.gmtDate as NSDate
                
                let relevantDays = Day.getRelevantDaysForAdjustment(adjustment: self, context: context)
                self.daysAffected = Set<Day>(relevantDays)
            } else {
                self.daysAffected = Set<Day>()
                firstDateEffective_ = nil
            }
        }
    }
    
    public var lastDayEffective: CalendarDay? {
        get {
            if let day = lastDateEffective_ as Date? {
                return CalendarDay(dateInGMTDay: day)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                lastDateEffective_ = newValue!.gmtDate as NSDate
                
                let relevantDays = Day.getRelevantDaysForAdjustment(adjustment: self, context: context)
                self.daysAffected = Set<Day>(relevantDays)
            } else {
                lastDateEffective_ = nil
            }
        }
    }
    
    public var sortedDaysAffected: [Day]? {
        if let affected = daysAffected {
            return affected.sorted(by: { $0.calendarDay! < $1.calendarDay! })
        } else {
            return nil
        }
    }
    
    public var daysAffected: Set<Day>? {
        get {
            return daysAffected_ as! Set?
        }
        set {
            if newValue != nil {
                daysAffected_ = NSSet(set: newValue!)
            } else {
                daysAffected_ = nil
            }
        }
    }
}
