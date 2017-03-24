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
    // Helper functions
    
    
    /*
     * Return the total number of adjustments to be added to the base total for
     * this month.
     */
    func totalAdjustments() -> Decimal {
        var total: Decimal = 0
        for monthAdjustment in self.adjustments! {
            total += monthAdjustment.amount!
        }
        
        for day in self.days! {
            for dayAdjustment in day.adjustments! {
                total += dayAdjustment.amount!
            }
        }
        return total
    }
    
    /*
     * Return the month object that a day is in, or nil if it doesn't exist.
     */
    class func get(context: NSManagedObjectContext, dateInMonth day: Date) -> Month? {
        let month = day.month
        let year = day.year
        // Fetch all months equal to the month and year
        let fetchRequest: NSFetchRequest<Month> = Month.fetchRequest()
        fetchRequest.predicate =
            NSCompoundPredicate(type: .and,
                                subpredicates: [NSPredicate(format: "month_ == %d, ", month),
                                                NSPredicate(format: "year_ == %d, ", year)])
        var monthResults: [Month] = []
        monthResults = try! context.fetch(fetchRequest)
        if monthResults.count < 1 {
            // No month exists.
            return nil
        } else if monthResults.count > 1 {
            // Multiple months exist.
            fatalError("Error: multiple months exist for \(month)/\(year)")
        }
        return monthResults[0]
    }
    
    /*
     * Create and return a month.
     */
    class func create(context: NSManagedObjectContext, dateInMonth date: Date) -> Month {
        let dailySpend = Decimal(UserDefaults.standard.double(forKey: "dailyTargetSpend"))
        
        let month = Month(context: context)
        month.month = date
        month.daysInMonth = date.daysInMonth
        month.baseDailyTargetSpend = dailySpend
        month.targetSpend = month.baseDailyTargetSpend! * Decimal(month.daysInMonth)
        month.actualSpend = 0
        
        return month
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
    public var baseDailyTargetSpend: Decimal? {
        get {
            return baseDailyTargetSpend_ as Decimal?
        }
        set {
            if newValue != nil {
                baseDailyTargetSpend_ = NSDecimalNumber(decimal: newValue!)
            } else {
                baseDailyTargetSpend_ = nil
            }
        }
    }
    
    
    public var daysInMonth: Int {
        get {
            return Int(daysInMonth_)
        }
        set {
            daysInMonth_ = Int64(newValue)
        }
    }
    public var month: Date? {
        get {
            return month_ as Date?
        }
        set {
            if newValue != nil {
                month_ = newValue! as NSDate
            } else {
                month_ = nil
            }
        }
    }
    
    public var targetSpend: Decimal? {
        get {
            return targetSpend_ as Decimal?
        }
        set {
            if newValue != nil {
                targetSpend_ = NSDecimalNumber(decimal: newValue!)
            } else {
                targetSpend_ = nil
            }
        }
    }
    
    public var adjustments: Set<MonthAdjustment>? {
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
    
    @objc(addAdjustmentsObject:)
    public func addToAdjustments(_ value: MonthAdjustment) {
        addToAdjustments_(value)
    }
    
    @objc(removeAdjustmentsObject:)
    public func removeFromAdjustments(_ value: MonthAdjustment) {
        removeFromAdjustments_(value)
    }
    
    @objc(addAdjustments:)
    public func addToAdjustments(_ values: Set<MonthAdjustment>) {
        addToAdjustments_(NSSet(set: values))
    }
    
    @objc(removeAdjustments:)
    public func removeFromAdjustments(_ values: Set<MonthAdjustment>) {
        removeFromAdjustments_(NSSet(set: values))
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
