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
            Logger.debug("couldn't unwrap date in Day")
            return nil
        }
        
        if let exps = sortedExpenses {
            var jsonExps = [[String: Any]]()
            for expense in exps {
                if let jsonExp = expense.json() {
                    jsonExps.append(jsonExp)
                } else {
                    Logger.debug("couldn't unwrap jsonExp in Day")
                    return nil
                }
            }
            jsonObj["expenses"] = jsonExps
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Day")
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
                // The date is after today, the date isn't a beginning of day,
                // or this day already exists.
                Logger.debug("The date is after today, the date isn't a " +
                    "beginning of day, or this day already exists in Day")
                return nil
            }
            day.calendarDay = calDay
        } else {
            Logger.debug("couldn't unwrap date in Day")
            return nil
        }
        
        if let jsonExps = json["expenses"] as? [[String: Any]] {
            for jsonExp in jsonExps {
                if let expense = Expense.create(context: context, json: jsonExp) {
                    expense.day = day
                } else {
                    Logger.debug("couldn't create expense in Day")
                    return nil
                }
            }
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Day")
                return nil
            }
            day.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in Day")
            return nil
        }
        
        
        // Get relevant Pause.
        let relevantPause = Pause.getRelevantPauseForDay(day: day, context: context)
        day.pause = relevantPause
        
        // Get relevant Adjustments.
        let relevantAdjustments = Adjustment.getRelevantAdjustmentsForDay(day: day, context: context)
        day.adjustments = Set<Adjustment>(relevantAdjustments)
        
        return day
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

    class func get(context: NSManagedObjectContext,
                   predicate: NSPredicate? = nil,
                   sortDescriptors: [NSSortDescriptor]? = nil,
                   fetchLimit: Int = 0) -> [Day]? {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        let dayResults = try? context.fetch(fetchRequest)

        return dayResults
    }
    
    class private func getRelevantDaysForRange(firstDay: CalendarDay,
                                               lastDay: CalendarDay,
                                               context: NSManagedObjectContext) -> [Day] {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        let pred = NSPredicate(format: "date_ >= %@ AND date_ <= %@",
        firstDay.gmtDate as CVarArg, lastDay.gmtDate as CVarArg)
        fetchRequest.predicate = pred
        let sortDesc = NSSortDescriptor(key: "date_", ascending: true)
        fetchRequest.sortDescriptors = [sortDesc]
        let dayResults = try! context.fetch(fetchRequest)
    
        return dayResults
    }

    /*
     * Return the Days affected by a particular Pause.
     */
    class func getRelevantDaysForPause(_ pause: Pause, context: NSManagedObjectContext) -> [Day] {
        guard let firstDayEffective = pause.firstDayEffective,
            let lastDayEffective = pause.lastDayEffective else {
            return []
        }
        return getRelevantDaysForRange(firstDay: firstDayEffective,
                                       lastDay: lastDayEffective,
                                       context: context)
    }
    
    /*
     * Return the Days affected by a particular Adjustment.
     */
    class func getRelevantDaysForAdjustment(_ adjustment: Adjustment, context: NSManagedObjectContext) -> [Day] {
        guard let firstDayEffective = adjustment.firstDayEffective,
            let lastDayEffective = adjustment.lastDayEffective else {
                return []
        }
        return getRelevantDaysForRange(firstDay: firstDayEffective,
                                       lastDay: lastDayEffective,
                                       context: context)
    }

    class func create(context: NSManagedObjectContext, calDay: CalendarDay, month: Month) -> Day {
        let day = Day(context: context)
        day.calendarDay = calDay
        day.month = month
        day.dateCreated = Date()
        
        // Get relevant Pause.
        let relevantPause = Pause.getRelevantPauseForDay(day: day, context: context)
        day.pause = relevantPause
        
        // Get relevant Adjustments.
        let relevantAdjustments = Adjustment.getRelevantAdjustmentsForDay(day: day, context: context)
        day.adjustments = Set<Adjustment>(relevantAdjustments)
        
        return day
    }
    
    /*
     * Creates consecutive days in data store inclusive of beginning date and
     * exclusive of ending date
     */
    class func createDays(context: NSManagedObjectContext, from: CalendarDay, to: CalendarDay) -> Int {
        if from > to {
            return 0
        }
        var numCreated = 0
        var currentDay = from
        while (currentDay != to) {
            let calMonth = CalendarMonth(day: currentDay)
            if let month = Month.get(context: context, calMonth: calMonth) {
                // Create the day
                _ = Day.create(context: context, calDay: currentDay, month: month)
                numCreated += 1
                currentDay = currentDay.add(days: 1)
            } else {
                // This month doesn't yet exist.
                // Create the month, then call this function again.
                _ = Month.create(context: context, calMonth: calMonth)
            }
        }
        return numCreated
    }
    
    // Accessor functions (for Swift 3 classes)
    /**
     * The amount spent on this day
     */
    public func totalExpenses() -> Decimal {
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
    
    
    /**
     * The amount that the baseTargetSpend for this day should be adjusted by
     * due to recorded Adjustments.
     */
    func totalAdjustments() -> Decimal {
        var total: Decimal = 0
        
        for adjustment in adjustments ?? [] {
            total += adjustment.amountPerDay ?? 0
        }
        
        return total
    }
    
    /**
     * The amount spent on this day, affected by expenses and pauses.
     */
    public func amountSpent() -> Decimal {
        if pause != nil {
            // Since this day is paused, there is no money accrued.
            return 0
        }
        
        var spent: Decimal = 0
        
        for expense in expenses ?? [] {
            spent += expense.amount ?? 0
        }
        
        return spent
    }

    
    /**
     * The amount accured on this day, after adjustments and pauses.
     */
    public func fullTargetSpend() -> Decimal {
        if pause != nil {
            // Since this day is paused, there is no money accrued.
            return 0
        }
        
        // Assume 0 if there is no base target spend.
        let base = self.baseTargetSpend ?? 0;
        
        return base + totalAdjustments()
    }
    
    /**
     * The amount to be carried to the day following this day, including all
     * expenses, pauses, and adjustments from days this month.
     */
    public func leftToCarry() -> Decimal {
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
                dailySpend += day.fullTargetSpend()
                dailySpend -= day.amountSpent()
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
    
    public var sortedAdjustments: [Adjustment]? {
        if let adj = adjustments {
            return adj.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    public var adjustments: Set<Adjustment>? {
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
    
    public var pause: Pause? {
        get {
            return pause_
        }
        set {
            pause_ = newValue
        }
    }
    
    @objc(addAdjustmentsObject:)
    public func addToAdjustments(_ value: Adjustment) {
        addToAdjustments_(value)
    }
    
    @objc(removeAdjustmentsObject:)
    public func removeFromAdjustments(_ value: Adjustment) {
        removeFromAdjustments_(value)
    }
    
    @objc(addAdjustments:)
    public func addToAdjustments(_ values: Set<Adjustment>) {
        addToAdjustments_(NSSet(set: values))
    }
    
    @objc(removeAdjustments:)
    public func removeFromAdjustments(_ values: Set<Adjustment>) {
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
    public func addToExpenses(_ values: Set<Expense>) {
        removeFromExpenses_(NSSet(set: values))
    }
    
    @objc(removeExpenses:)
    public func removeFromExpenses(_ values: Set<Expense>) {
        removeFromExpenses_(NSSet(set: values))
    }
}
