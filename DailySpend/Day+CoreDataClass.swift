//
//  Day+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

@objc(Day)
public class Day: NSManagedObject {
    public func json() -> [String: Any]? {
        var jsonObj = [String: Any]()

        if let date = calendarDay?.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["date"] = num
        } else {
            return nil
        }
        
        if let adjs = sortedAdjustments {
            var jsonAdjs = [[String: Any]]()
            for adjustment in adjs {
                if let jsonAdj = adjustment.json() {
                    jsonAdjs.append(jsonAdj)
                } else {
                    return nil
                }
            }
            jsonObj["adjustments"] = jsonAdjs
        }
        
        if let exps = sortedExpenses {
            var jsonExps = [[String: Any]]()
            for expense in exps {
                if let jsonExp = expense.json() {
                    jsonExps.append(jsonExp)
                } else {
                    return nil
                }
            }
            jsonObj["expenses"] = jsonExps
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
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
                      json: [String: Any]) -> Day? {
        let day = Day(context: context)
        
        if let dateNumber = json["date"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay > CalendarDay() ||
                calDay.gmtDate != date ||
                Day.get(context: context, calDay: calDay) != nil {
                return nil
            }
            day.calendarDay = calDay
        } else {
            return nil
        }
        
        if let jsonAdjs = json["adjustments"] as? [[String: Any]] {
            for jsonAdj in jsonAdjs {
                if let dayAdj = DayAdjustment.create(context: context, json: jsonAdj) {
                    dayAdj.day = day
                } else {
                    return nil
                }
            }
        }
        
        if let jsonExps = json["expenses"] as? [[String: Any]] {
            for jsonExp in jsonExps {
                if let expense = Expense.create(context: context, json: jsonExp) {
                    expense.day = day
                } else {
                    return nil
                }
            }
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                return nil
            }
            day.dateCreated = date
        } else {
            return nil
        }
        
        return day
    }
    
    // Helper functions
    func totalAdjustments() -> Decimal {
        var total: Decimal = 0
        
        if let dayAdjustments = self.adjustments {
            for dayAdjustment in dayAdjustments {
                total += dayAdjustment.amount ?? 0
            }
        }
        
        for monthAdjustment in relevantMonthAdjustments {
            let calendarDay = self.calendarDay!
            let calendarDayEffective = monthAdjustment.calendarDayEffective!
            
            let calMonth = CalendarMonth(day: calendarDay)
            let daysAcross = calMonth.daysInMonth - calendarDayEffective.day + 1
            
            if let amount = monthAdjustment.amount {
                // This is the amount of this adjustment that affects this day.
                total += amount / Decimal(daysAcross)
            }
        }
        
        return total
    }
    
    var relevantMonthAdjustments: [MonthAdjustment] {
        guard let calendarDay = self.calendarDay,
              let monthAdjustments = self.month?.adjustments else {
            return []
        }
        
        // Get all applicable month adjustments, those for which this day is 
        // after or on the same day as the effective day.
        var monthAdj: [MonthAdjustment] = []
        for monthAdjustment in monthAdjustments {
            if let calendarDayEffective = monthAdjustment.calendarDayEffective {
                if calendarDay >= calendarDayEffective {
                    // This adjustments affects today.
                    monthAdj.append(monthAdjustment)
                }
            }
        }
        
        return monthAdj.sorted(by: { $0.dateCreated! < $1.dateCreated! })
    }
    
    /*
     * Return the day object that a date is in, or nil if it doesn't exist.
     */
    class func get(context: NSManagedObjectContext, calDay: CalendarDay) -> Day? {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        let pred = NSPredicate(format: "date_ == %@", calDay.gmtDate as CVarArg)
        fetchRequest.predicate = pred
        var dayResults: [Day] = []
        dayResults = try! context.fetch(fetchRequest)
        if dayResults.count < 1 {
            // No month exists.
            return nil
        } else if dayResults.count > 1 {
            // Multiple days exist.
            fatalError("Error: multiple days exist for " +
                        "\(calDay.day)/\(calDay.month)/\(calDay.year)")
        }
        return dayResults[0]
    }
    
    class func create(context: NSManagedObjectContext, calDay: CalendarDay, month: Month) -> Day {
        let day = Day(context: context)
        day.calendarDay = calDay
        day.month = month
        day.dateCreated = Date()
        
        return day
    }
    
    /*
     * Creates consecutive days in data store inclusive of beginning date and
     * exclusive of ending date
     */
    class func createDays(context: NSManagedObjectContext, from: CalendarDay, to: CalendarDay) {
        var currentDay = from
        while (currentDay != to) {
            let calMonth = CalendarMonth(day: currentDay)
            if let month = Month.get(context: context, calMonth: calMonth) {
                // Create the day
                _ = Day.create(context: context, calDay: currentDay, month: month)
                currentDay = currentDay.add(days: 1)
            } else {
                // This month doesn't yet exist.
                // Create the month, then call this function again.
                _ = Month.create(context: context, calMonth: calMonth)
            }
        }
    }
    
    // Accessor functions (for Swift 3 classes)
    public var actualSpend: Decimal {
        var totalSpend: Decimal = 0
        for expense in expenses ?? [] {
           totalSpend += expense.amount ?? 0
        }
        return totalSpend
    }
    
    public var baseTargetSpend: Decimal? {
        get {
            return month?.dailyBaseTargetSpend
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
    
    public var fullTargetSpend: Decimal? {
        guard let baseTargetSpend = baseTargetSpend else {
            return nil
        }
        return baseTargetSpend + totalAdjustments()
    }
    
    public var leftToCarry: Decimal {
        guard let daysThisMonth = month!.days,
              let calendarDay = self.calendarDay else {
            return 0
        }
        var dailySpend: Decimal = 0
        for day in daysThisMonth {
            guard let otherCalDay = day.calendarDay else {
                return 0
            }
            if otherCalDay <= calendarDay {
                dailySpend += day.baseTargetSpend ?? 0
                dailySpend += day.totalAdjustments()
                for expense in day.expenses ?? [] {
                    dailySpend -= expense.amount ?? 0
                }
            }
        }
        return dailySpend
    }
    
    public var calendarDay: CalendarDay? {
        get {
            if let date = date_ as Date? {
                return CalendarDay(dateInGMTDay: date)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                date_ = newValue!.gmtDate as NSDate
            } else {
                date_ = nil
            }
        }
    }
    
    public var sortedAdjustments: [DayAdjustment]? {
        if let adj = adjustments {
            return adj.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    public var adjustments: Set<DayAdjustment>? {
        get {
            return adjustments_ as! Set?
        }
        set {
            if newValue != nil {
                adjustments_ = NSSet(set: newValue!)
            } else {
                adjustments_ = nil
            }
        }
    }
    
    public var sortedExpenses: [Expense]? {
        if let exp = expenses {
            return exp.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    public var expenses: Set<Expense>? {
        get {
            return expenses_ as! Set?
        }
        set {
            if newValue != nil {
                expenses_ = NSSet(set: newValue!)
            } else {
                expenses_ = nil
            }
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
    
    @objc(addAdjustmentsObject:)
    public func addToAdjustments(_ value: DayAdjustment) {
        addToAdjustments_(value)
    }
    
    @objc(removeAdjustmentsObject:)
    public func removeFromAdjustments(_ value: DayAdjustment) {
        removeFromAdjustments_(value)
    }
    
    @objc(addAdjustments:)
    public func addToAdjustments(_ values: Set<DayAdjustment>) {
        addToAdjustments_(NSSet(set: values))
    }
    
    @objc(removeAdjustments:)
    public func removeFromAdjustments(_ values: Set<DayAdjustment>) {
        removeFromAdjustments_(NSSet(set: values))
    }

    
    @objc(addExpensesObject:)
    public func addToExpenses(_ value: Expense) {
        addToExpenses_(value)
    }
    
    @objc(removeExpensesObject:)
    public func removeFromExpenses(_ value: Expense) {
        removeFromExpenses_(value)
    }
    
    @objc(addExpenses:)
    public func addToAdjustments(_ values: Set<Expense>) {
        removeFromExpenses_(NSSet(set: values))
    }
    
    @objc(removeExpenses:)
    public func removeFromExpenses(_ values: Set<Expense>) {
        removeFromExpenses_(NSSet(set: values))
    }
}
