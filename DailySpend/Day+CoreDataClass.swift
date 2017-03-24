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
    
    // Helper functions
    func totalAdjustments() -> Decimal {
        var total: Decimal = 0
        for dayAdjustment in self.adjustments! {
            total += dayAdjustment.amount!
        }
        
        for monthAdjustment in self.month!.adjustments! {
            let date = self.date! as Date
            let dateEffective = monthAdjustment.dateEffective! as Date
            if date > dateEffective  {
                // This affects this day.
                let daysAcross = date.daysInMonth - dateEffective.day + 1
                // This is the amount of this adjustment that effects this day.
                total += monthAdjustment.amount! / Decimal(daysAcross)
            }
        }
        return total
    }
    
    /*
     * Return the month object that a day is in, or nil if it doesn't exist.
     */
    class func get(context: NSManagedObjectContext, date: Date) -> Day? {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date_ == %@, ", date.beginningOfDay as CVarArg)
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
    
    class func create(context: NSManagedObjectContext, date: Date, month: Month) {
        let day = Day(context: context)
        day.date = date
        day.month = month
        day.baseTargetSpend = day.month!.baseDailyTargetSpend
        day.actualSpend = 0
    }
    
    // Accessor functions (for Swift 3 classes)
    public var actualSpend: Decimal? {
        get {
            return actualSpend_ as Decimal?
        }
        set {
            if newValue == nil {
                actualSpend_ = NSDecimalNumber(decimal: newValue!)
            } else {
                actualSpend_ = nil
            }
        }
    }
    
    public var baseTargetSpend: Decimal? {
        get {
            return baseTargetSpend_ as Decimal?
        }
        set {
            if newValue == nil {
                baseTargetSpend_ = NSDecimalNumber(decimal: newValue!)
            } else {
                baseTargetSpend_ = nil
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
