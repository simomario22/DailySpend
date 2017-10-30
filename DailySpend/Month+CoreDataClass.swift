//
//  Month+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

@objc(Month)
public class Month: NSManagedObject {
    
    public func json() -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let month = calendarMonth?.gmtDate {
            let num = month.timeIntervalSince1970 as NSNumber
            jsonObj["month"] = num
        } else {
            Logger.debug("couldn't unwrap month in Month")
            return nil
        }
        
        if let dailyBaseTargetSpend = dailyBaseTargetSpend {
            let num = dailyBaseTargetSpend as NSNumber
            jsonObj["dailyBaseTargetSpend"] = num
        } else {
            Logger.debug("couldn't unwrap dailyBaseTargetSpend in Month")
            return nil
        }
        
        if let days = sortedDays {
            var jsonDays = [[String: Any]]()
            for day in days {
                if let jsonDay = day.json() {
                    jsonDays.append(jsonDay)
                } else {
                    Logger.debug("couldn't unwrap jsonDay in Month")
                    return nil
                }
            }
            jsonObj["days"] = jsonDays
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Month")
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
                      json: [String: Any]) -> Month? {
        
        let month = Month(context: context)
        
        if let dailyBaseTargetSpend = json["dailyBaseTargetSpend"] as? NSNumber {
            let decimal = Decimal(dailyBaseTargetSpend.doubleValue)
            if decimal <= 0 {
                Logger.debug("invalid dailyBaseTargetSpend in Month")
                return nil
            }
            month.dailyBaseTargetSpend = decimal
        } else {
            Logger.debug("couldn't unwrap dateCreated in Month")
            return nil
        }
        
        if let monthNumber = json["month"] as? NSNumber {
            let date = Date(timeIntervalSince1970: monthNumber.doubleValue)
            let calendarMonth = CalendarMonth(dateInGMTMonth: date)
            if calendarMonth > CalendarMonth() ||
                calendarMonth.gmtDate != date ||
                Month.get(context: context, calMonth: calendarMonth) != nil {
                // The date is after today, the date isn't a beginning of day,
                // or this month already exists.
                Logger.debug("The date is after today, the date isn't a " +
                    "beginning of day, or this month already exists in Month")
                return nil
            }
            month.calendarMonth = calendarMonth
        } else {
            Logger.debug("couldn't unwrap month in Month")
            return nil
        }
        
        if let jsonDays = json["days"] as? [[String: Any]] {
            for jsonDay in jsonDays {
                if let day = Day.create(context: context, json: jsonDay) {
                    if !month.calendarMonth!.contains(day: day.calendarDay!) {
                        Logger.debug("day attached to month isn't in Month")
                        return nil
                    }
                    day.month = month
                } else {
                    Logger.debug("couldn't create day in Month")
                    return nil
                }
            }
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Month")
                return nil
            }
            month.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in Month")
            return nil
        }

        return month
    }
    
    // Helper functions
    
    /*
     * Return the month object that a day is in, or nil if it doesn't exist.
     */
    class func get(context: NSManagedObjectContext, calMonth: CalendarMonth) -> Month? {
        // Fetch all months equal to the month and year
        let fetchRequest: NSFetchRequest<Month> = Month.fetchRequest()
        let pred = NSPredicate(format: "month_ == %@", calMonth.gmtDate as CVarArg)
        fetchRequest.predicate = pred
        var monthResults: [Month] = []
        monthResults = try! context.fetch(fetchRequest)
        if monthResults.count < 1 {
            // No month exists.
            return nil
        } else if monthResults.count > 1 {
            // Multiple months exist.
            fatalError("Error: multiple months exist for \(calMonth.month)/\(calMonth.year)")
        }
        return monthResults[0]
    }
    
    class func get(context: NSManagedObjectContext,
                    predicate: NSPredicate? = nil,
                    sortDescriptors: [NSSortDescriptor]? = nil,
                    fetchLimit: Int = 0) -> [Month]? {
        let fetchRequest: NSFetchRequest<Month> = Month.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        let monthResults = try? context.fetch(fetchRequest)

        return monthResults
    }

    /*
     * Create and return a month.
     */
    class func create(context: NSManagedObjectContext, calMonth: CalendarMonth) -> Month {
        let defaults = UserDefaults.standard
        let dailySpend = Decimal(defaults.double(forKey: "dailyTargetSpend"))
        
        let month = Month(context: context)
        month.calendarMonth = calMonth
        month.dailyBaseTargetSpend = dailySpend
        month.dateCreated = Date()

        return month
    }
    
    // Accessor functions (for Swift 3 classes)
    
    /**
     * The amount spent on this day.
     */
    func totalExpenses() -> Decimal {
        var totalSpend: Decimal = 0
        for day in days ?? [] {
            totalSpend += day.totalExpenses()
        }
        return totalSpend
    }
    
    public var dailyBaseTargetSpend: Decimal? {
        get {
            return dailyBaseTargetSpend_ as Decimal?
        }
        set {
            if newValue != nil {
                dailyBaseTargetSpend_ = NSDecimalNumber(decimal: newValue!)
            } else {
                dailyBaseTargetSpend_ = nil
            }
        }
    }
    
    public var daysInMonth: Int? {
        return calendarMonth?.daysInMonth
    }
    
    public var calendarMonth: CalendarMonth? {
        get {
            if let month = month_ as Date? {
                return CalendarMonth(dateInGMTMonth: month)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                month_ = newValue!.gmtDate as NSDate
            } else {
                month_ = nil
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
    
    /*
     * The base amount available to spend this month, NOT taking into account
     * adjustments, pauses, or expenses, but adjusted for the number of days in
     * the month.
     */
    public var baseTargetSpend: Decimal? {
        guard let daysInMonth = daysInMonth,
              let days = days else {
            return nil
        }
        
        // Find the earliest day this month we have a Day object for.
        var earliestDay = daysInMonth + 1
        for day in days {
            guard let dayOfMonth = day.calendarDay?.day else {
                return nil
            }
            if dayOfMonth < earliestDay {
                earliestDay = dayOfMonth
            }
        }
        
        if (earliestDay == 1 || earliestDay > daysInMonth) {
            // This is either a complete month or we're not sure yet
            // If we're not sure yet we'll make the assumption that it is complete
            return dailyBaseTargetSpend! * Decimal(daysInMonth)
        } else {
            // This month started in the middle, so the baseTargetSpend 
            // should exclude the days before we started
            return dailyBaseTargetSpend! * Decimal(daysInMonth - earliestDay + 1)
            
        }
    }
    
    /*
     * The amount available to spend this month, taking into account adjustments
     * and pauses.
     */
    public func fullTargetSpend() -> Decimal {
        var adjustments: Decimal = 0

        for day in days ?? [] {
            adjustments += day.totalAdjustments()
            if day.pause != nil {
                adjustments -= day.baseTargetSpend ?? 0
            }
        }
        
        // Assume 0 if there is no base target spend.
        let base = self.baseTargetSpend ?? 0;

        return base + adjustments
    }
    
    public var sortedDays: [Day]? {
        if let days = days {
            return days.sorted(by: { $0.calendarDay! < $1.calendarDay! })
        } else {
            return nil
        }
    }
    
    public var days: Set<Day>? {
        get {
            return days_ as! Set?
        }
        set {
            if newValue != nil {
                days_ = NSSet(set: newValue!)
            } else {
                days_ = nil
            }
        }
    }
    
    @objc(addDaysObject:)
    public func addToDays(_ value: Day) {
        addToDays_(value)
    }
    
    @objc(removeDaysObject:)
    public func removeFromDays(_ value: Day) {
        removeFromDays_(value)
    }
    
    @objc(addDays:)
    public func addToDays(_ values: Set<Day>) {
        addToDays_(NSSet(set: values))
    }

    @objc(removeDays:)
    public func removeFromDays(_ values: Set<Day>) {
        removeFromDays_(NSSet(set: values))
    }

}
