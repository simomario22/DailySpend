//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension Date {
    /*
     * Returns a date by adding days then months by incrementing those values 
     * in that order.
     */
    func add(days: Int = 0, months: Int = 0) -> Date {
        let cal = Calendar(identifier: .gregorian)
        
        // Get interval for days
        var interval = self.timeIntervalSince(cal.date(byAdding: .day, value: days, to: self)!)
        // Get interval for months
        interval += self.timeIntervalSince(cal.date(byAdding: .month, value: months, to: self)!)
        
        // Add interval to a copy of self
        var date = self
        date.addTimeInterval(-interval)
        return date
    }
    
    func subtract(days: Int = 0, months: Int = 0) -> Date {
        return self.add(days: -days, months: -months)
    }
    
    var daysInMonth: Int {
        let cal = Calendar(identifier:.gregorian)
        return cal.range(of: .day, in: .month, for: self)!.count
    }

    var day: Int {
        return Calendar(identifier: .gregorian).component(.day, from: self)
    }
    
    var month: Int {
        return Calendar(identifier: .gregorian).component(.month, from: self)
    }
    
    var year: Int {
        return Calendar(identifier: .gregorian).component(.year, from: self)
    }
    
    var beginningOfDay: Date {
        return Calendar(identifier: .gregorian).startOfDay(for: self)
    }
    
    static func firstDayOfMonth(dayInMonth date: Date) -> Date {
        let cal = Calendar(identifier: .gregorian)
        let compSet: Set<Calendar.Component> = [.year, .month, .day]
        
        var comp = cal.dateComponents(compSet, from: date)
        comp.setValue(1, for: .day)
        comp.setValue(0, for: .hour)
        comp.setValue(0, for: .minute)
        comp.setValue(0, for: .second)
        comp.setValue(0, for: .nanosecond)
        return cal.date(from: comp)!
    }
    
}
