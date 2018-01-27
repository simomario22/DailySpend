//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

public class CalendarWeek {
    private var date: Date

    /*
     * @param dateInGMTMonth A date representing a point in time that is in
     * the desired week when using the GMT time zone.
     */
    init(dateInGMTWeek date: Date) {
        let gmtCal = CalendarWeek.gmtCal
        
        let componentSet: Set<Calendar.Component> = [.year, .month, .weekOfMonth, .weekday]
        
        var dateComponents = gmtCal.dateComponents(componentSet, from: date)
        dateComponents.setValue(1, for: .weekday)
        
        self.date = gmtCal.startOfDay(for: gmtCal.date(from: dateComponents)!)
    }
    
    convenience init(day: CalendarDay) {
        self.init(dateInGMTWeek: day.gmtDate)
    }

    /*
     * @param dateInLocalMonth A date representing a point in time that is in 
     * the desired month when using the system's current time zone.
     */
    convenience init(dateInLocalWeek date: Date) {
        self.init(day: CalendarDay(dateInLocalDay: date))
    }

    
    convenience init() {
        self.init(dateInLocalWeek: Date())
    }
    
    /*
     * Returns a date by adding weeks then months by incrementing those values
     * in that order.
     */
    func add(weeks: Int) -> CalendarWeek {
        let cal = CalendarWeek.gmtCal
        
        // We currently define a week as always being 7 days, so add 7 days
        // times the number of weeks to the interval.
        let interval = self.date.timeIntervalSince(cal.date(byAdding: .day,
                                                            value: weeks * self.daysInWeek,
                                                            to: self.date)!)
        
        // Add interval to a copy of self
        var datePlusInterval = self.date
        datePlusInterval.addTimeInterval(-interval)
        return CalendarWeek(dateInGMTWeek: datePlusInterval)
    }
    
    func subtract(weeks: Int) -> CalendarWeek {
        return self.add(weeks: -weeks)
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

    var daysInWeek: Int {
        return 7
    }

    var weekOfMonth: Int {
        return CalendarWeek.gmtCal.component(.weekOfMonth, from: self.date)
    }
    
    var month: Int {
        return CalendarWeek.gmtCal.component(.month, from: self.date)
    }
    
    var year: Int {
        return CalendarWeek.gmtCal.component(.year, from: self.date)
    }
    
    static var gmtTimeZone: TimeZone {
        return TimeZone(secondsFromGMT: 0)!
    }

    private static var gmtCal: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = CalendarWeek.gmtTimeZone
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

extension CalendarWeek: Comparable {
    static public func == (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.gmtDate == rhs.gmtDate
    }
    
    static public func < (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.gmtDate < rhs.gmtDate
    }
    
    static public func > (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.gmtDate > rhs.gmtDate
    }
    
    static public func <= (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.gmtDate <= rhs.gmtDate
    }
    
    static public func >= (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.gmtDate >= rhs.gmtDate
    }
}
