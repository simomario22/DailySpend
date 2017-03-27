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
    class func get(context: NSManagedObjectContext, dateInMonth date: Date) -> Month? {
        
        let month = date.month
        let year = date.year
        // Fetch all months equal to the month and year
        let fetchRequest: NSFetchRequest<Month> = Month.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "month_ == %@", Date.firstDayOfMonth(dayInMonth: date) as CVarArg)
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
        month.dailyBaseTargetSpend = dailySpend
        month.dateCreated = Date()

        return month
    }
    
    
    
    // Accessor functions (for Swift 3 classes)
    public var actualSpend: Decimal {
        var totalSpend: Decimal = 0
        for day in days! {
            totalSpend += day.actualSpend
        }
        return totalSpend as Decimal
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
    
    
    public var daysInMonth: Int {
        return month!.daysInMonth
    }
    
    public var month: Date? {
        get {
            return month_ as Date?
        }
        set {
            if newValue != nil {
                month_ = Date.firstDayOfMonth(dayInMonth: newValue!) as NSDate
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
    
    public var baseTargetSpend: Decimal {
        return dailyBaseTargetSpend! * Decimal(daysInMonth)
    }
    
    public var fullTargetSpend: Decimal {
        return baseTargetSpend + totalAdjustments()
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
