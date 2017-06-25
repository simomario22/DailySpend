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

        if let date = date {
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
            if date > Date() ||
                date.beginningOfDay != date ||
                Day.get(context: context, date: date) != nil {
                return nil
            }
            day.date = date
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
        for dayAdjustment in self.adjustments! {
            total += dayAdjustment.amount!
        }
        
        for monthAdjustment in self.month!.adjustments! {
            let date = self.date! as Date
            let dateEffective = monthAdjustment.dateEffective! as Date
            if date.beginningOfDay >= dateEffective.beginningOfDay  {
                // This affects this day.
                let daysAcross = date.daysInMonth - dateEffective.day + 1
                // This is the amount of this adjustment that affects this day.
                total += monthAdjustment.amount! / Decimal(daysAcross)
            }
        }
        return total
    }
    
    var relevantMonthAdjustments: [MonthAdjustment] {
        // Get all applicable month adjustments.
        var monthAdj: [MonthAdjustment] = []
        for monthAdjustment in self.month!.adjustments! {
            let date = self.date! as Date
            let dateEffective = monthAdjustment.dateEffective! as Date
            if date.beginningOfDay >= dateEffective.beginningOfDay  {
                monthAdj.append(monthAdjustment)
            }
        }
        
        return monthAdj.sorted(by: { $0.dateCreated! < $1.dateCreated! })
    }
    
    /*
     * Return the day object that a date is in, or nil if it doesn't exist.
     */
    class func get(context: NSManagedObjectContext, date: Date) -> Day? {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        let pred = NSPredicate(format: "date_ == %@",
                               date.beginningOfDay as CVarArg)
        fetchRequest.predicate = pred
        var dayResults: [Day] = []
        dayResults = try! context.fetch(fetchRequest)
        if dayResults.count < 1 {
            // No month exists.
            return nil
        } else if dayResults.count > 1 {
            // Multiple months exist.
            fatalError("Error: multiple months exist for \(date)")
        }
        return dayResults[0]
    }
    
    class func create(context: NSManagedObjectContext,
                      date: Date, month: Month) -> Day {
        let day = Day(context: context)
        day.date = date.beginningOfDay
        day.month = month
        day.dateCreated = Date()
        
        return day
    }
    
    /*
     * Creates consecutive days in data store inclusive of beginning date and
     * exclusive of ending date
     */
    class func createDays(context: NSManagedObjectContext, from: Date, to: Date) {
        var currentDate = from
        while (currentDate.beginningOfDay != to.beginningOfDay) {
            if let month = Month.get(context: context, dateInMonth: currentDate) {
                // Create the day
                _ = Day.create(context: context, date: currentDate, month: month)
                currentDate = currentDate.add(days: 1)
            } else {
                // This month doesn't yet exist.
                // Create the month, then call this function again.
                _ = Month.create(context: context, dateInMonth: currentDate)
            }
        }
    }
    
    // Accessor functions (for Swift 3 classes)
    public var actualSpend: Decimal {
        var totalSpend: Decimal = 0
        for expense in expenses! {
           totalSpend += expense.amount!
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
    
    public var fullTargetSpend: Decimal {
        return baseTargetSpend! + totalAdjustments()
    }
    
    public var leftToCarry: Decimal {
        var dailySpend: Decimal = 0
        for day in month!.days! {
            if day.date! <= date! {
                dailySpend += day.baseTargetSpend!
                dailySpend += day.totalAdjustments()
                for expense in day.expenses! {
                    dailySpend -= expense.amount!
                }
            }
        }
        return dailySpend
    }
    
    public var date: Date? {
        get {
            return date_ as Date?
        }
        set {
            if newValue != nil {
                date_ = newValue!.beginningOfDay as NSDate
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
