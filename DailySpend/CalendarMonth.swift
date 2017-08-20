//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

public class CalendarMonth {
    private var date: Date

    /*
     * @param dateInGMTMonth A date representing a point in time that is in
     * the desired month when using the GMT time zone.
     */
    init(dateInGMTMonth date: Date) {
        let gmtCal = CalendarMonth.gmtCal
        
        let componentSet: Set<Calendar.Component> = [.year, .month, .day]
        
        var dateComponents = gmtCal.dateComponents(componentSet, from: date)
        dateComponents.setValue(1, for: .day)
        
        self.date = gmtCal.startOfDay(for: gmtCal.date(from: dateComponents)!)
    }

    /*
     * @param dateInLocalMonth A date representing a point in time that is in 
     * the desired month when using the system's current time zone.
     */
    convenience init(dateInLocalMonth date: Date) {
        // Convert to the beginning of the date's month in GMT
        
        let systemCal = Calendar(identifier: .gregorian)
        
        let componentSet: Set<Calendar.Component> = [.year, .month, .day]
        
        var dateComponents = systemCal.dateComponents(componentSet, from: date)
        dateComponents.setValue(1, for: .day)

        let beginningOfMonthInGMT = CalendarMonth.gmtCal.date(from: dateComponents)!
        
        self.init(dateInGMTMonth: beginningOfMonthInGMT)
    }
    
    convenience init(day: CalendarDay) {
        self.init(dateInGMTMonth: day.gmtDate)
    }
    
    convenience init() {
        self.init(dateInLocalMonth: Date())
    }
    
    /*
     * Returns a date by adding days then months by incrementing those values 
     * in that order.
     */
    func add(months: Int = 0) -> CalendarMonth {
        let cal = CalendarMonth.gmtCal

        // Get interval for months
        let interval = self.date.timeIntervalSince(cal.date(byAdding: .month,
                                                    value: months,
                                                    to: self.date)!)
        
        // Add interval to a copy of self
        var datePlusInterval = self.date
        datePlusInterval.addTimeInterval(-interval)
        return CalendarMonth(dateInGMTMonth: datePlusInterval)
    }
    
    func subtract(months: Int = 0) -> CalendarMonth {
        return self.add(months: -months)
    }
    
    func string(formatter: DateFormatter) -> String {
        let origTZ = formatter.timeZone
        formatter.timeZone = CalendarMonth.gmtTimeZone
        
        let s = formatter.string(from: date)
        
        formatter.timeZone = origTZ

        return s
    }
    
    func contains(day: CalendarDay) -> Bool {
        return day.month == self.month && day.year == self.year
    }

    var daysInMonth: Int {
        return CalendarMonth.gmtCal.range(of: .day, in: .month, for: self.date)!.count
    }

    var month: Int {
        return CalendarMonth.gmtCal.component(.month, from: self.date)
    }
    
    var year: Int {
        return CalendarMonth.gmtCal.component(.year, from: self.date)
    }
    
    static var gmtTimeZone: TimeZone {
        return TimeZone(secondsFromGMT: 0)!
    }

    private static var gmtCal: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = CalendarMonth.gmtTimeZone
        return cal
    }
    
    /*
     * This represents a point in time that is 12:00:00am on the first day of
     * the month that this CalendarMonth represents.
     */
    var gmtDate: Date {
        return date
    }
    
}

extension CalendarMonth: Comparable {
    static public func == (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.gmtDate == rhs.gmtDate
    }
    
    static public func < (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.gmtDate < rhs.gmtDate
    }
    
    static public func > (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.gmtDate > rhs.gmtDate
    }
    
    static public func <= (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.gmtDate <= rhs.gmtDate
    }
    
    static public func >= (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.gmtDate >= rhs.gmtDate
    }
}
