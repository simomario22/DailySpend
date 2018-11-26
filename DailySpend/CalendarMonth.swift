//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class CalendarMonth {
    private var date: Date

    /*
     * @param dateInGMTMonth A date representing a point in time that is in
     * the desired month when using the GMT time zone.
     */
    init(dateInMonth date: CalendarDateProvider) {
        let gmtCal = CalendarMonth.gmtCal

        let componentSet: Set<Calendar.Component> = [.year, .month, .day]

        var dateComponents = gmtCal.dateComponents(componentSet, from: date.gmtDate)
        dateComponents.setValue(1, for: .day)

        self.date = gmtCal.startOfDay(for: gmtCal.date(from: dateComponents)!)
    }

    /*
     * @param dateInLocalMonth A date representing a point in time that is in
     * the desired month when using the system's current time zone.
     */
    convenience init(localDateInMonth date: Date) {
        self.init(interval: CalendarDay(localDateInDay: date))
    }


    convenience init(interval: CalendarIntervalProvider) {
        self.init(dateInMonth: interval.start)
    }

    convenience init() {
        self.init(localDateInMonth: Date())
    }
    
    private init(trustedDate: Date) {
        self.date = trustedDate
    }

    /*
     * Returns a date by adding days then months by incrementing those values
     * in that order.
     */
    func add(months: Int) -> CalendarMonth {
        let cal = CalendarMonth.gmtCal
        let newDate = cal.date(byAdding: .month, value: months, to: self.date)!
        return CalendarMonth(trustedDate: newDate)
    }

    func subtract(months: Int) -> CalendarMonth {
        return self.add(months: -months)
    }
    
    /**
     * Returns the number of months that this months is after `startMonth`.
     * If this month is before start month, this function will return a
     * negative number.
     */
    func monthsAfter(startMonth: CalendarMonth) -> Int {
        return CalendarMonth.gmtCal.dateComponents(
            [.month],
            from: startMonth.start.gmtDate,
            to: self.date
        ).month!
    }
    
    /**
     * Returns the number of months that this months is after `startMonth`.
     * If this month is before start month, this function will return a
     * negative number.
     *
     * Also returns the remainder of days that didn't fit into an even number
     * of months.
     */
    func monthsAfter(start: CalendarDay) -> (Int, Int) {
        let components = CalendarMonth.gmtCal.dateComponents(
            [.month, .day],
            from: start.start.gmtDate,
            to: self.date
        )
        return (components.month!, components.day!)
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

    func contains(week: CalendarWeek) -> Bool {
        return week.month == self.month && week.year == self.year
    }

    var daysInMonth: Int {
        return CalendarMonth.gmtCal.range(of: .day, in: .month, for: self.date)!.count
    }

    private func sundaysInMonth() -> Int {
        var sundaysInMonth = 0

        var dateComponents = CalendarMonth.gmtCal.dateComponents([.year, .month], from: self.date)
        let originalMonth = dateComponents.month!
        var week = 1
        dateComponents.setValue(week, for: .weekOfMonth)
        dateComponents.setValue(1, for: .weekday)

        func getNewMonth(_ dc: DateComponents) -> Int {
            let newDate = CalendarMonth.gmtCal.date(from: dc)!
            return CalendarMonth.gmtCal.dateComponents([.month], from: newDate).month!
        }

        while originalMonth != getNewMonth(dateComponents) {
            week += 1
            dateComponents.setValue(week, for: .weekOfMonth)
        }

        repeat {
            sundaysInMonth += 1
            week += 1
            dateComponents.setValue(week, for: .weekOfMonth)
        } while originalMonth == getNewMonth(dateComponents)

        return sundaysInMonth
    }

    var weeksInMonth: Int {
        // We are counting a week as "in" a month if the Sunday of that week is
        // in this month.
        return sundaysInMonth()
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

    static var typicalDaysInMonth: Int {
        return 30
    }

    static var typicalWeeksInMonth: Int {
        return 4
    }

    private static var _gmtCal: Calendar?
    private static var gmtCal: Calendar {
        if let cal = CalendarMonth._gmtCal {
            return cal
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = CalendarMonth.gmtTimeZone
        _gmtCal = cal
        return cal
    }
    
    var period: PeriodScope {
        return .Month
    }
}

extension CalendarMonth: CalendarIntervalProvider {
    /*
     * This represents a point in time that is 12:00:00am on the first day of
     * the month that this CalendarMonth represents.
     */
    var start: CalendarDateProvider {
        return GMTDate(date)
    }
    
    var end: CalendarDateProvider? {
        return self.add(months: 1).start
    }

    /**
     * Returns true if this interval contains the date, false otherwise.
     */
    func contains(date: CalendarDateProvider) -> Bool {
        return date.gmtDate >= start.gmtDate && date.gmtDate < end!.gmtDate
    }
    
    /**
     * Returns true if this interval contains the entire interval, false
     * otherwise.
     */
    func contains(interval: CalendarIntervalProvider) -> Bool {
        return self.contains(date: interval.start) &&
            interval.end != nil &&
            self.contains(date: interval.end!)
    }
    
    /**
     * Returns true if any portion of this interval overlaps with any portion
     * of the passed interval.
     */
    func overlaps(with interval: CalendarIntervalProvider) -> Bool {
        if interval.end != nil && self.start.gmtDate > interval.end!.gmtDate {
            return false
        }
        
        if self.end!.gmtDate < interval.start.gmtDate {
            return false
        }
        
        return true
    }
    
    /**
     * Returns the interval of maximum size contained by both intervals, or
     * `nil` if no such intervals exists.
     */
    func overlappingInterval(with interval: CalendarIntervalProvider) -> CalendarIntervalProvider? {
        if self.contains(interval: interval) {
            return interval
        } else if interval.contains(interval: self) {
            return self
        } else if interval.end == nil || self.start.gmtDate < interval.end!.gmtDate {
            return CalendarInterval(start: self.start, end: interval.end)
        } else if interval.start.gmtDate < self.end!.gmtDate {
            return CalendarInterval(start: interval.start, end: self.end)
        } else {
            return nil
        }
    }
}

extension CalendarMonth: Comparable {
    static func == (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.start.gmtDate == rhs.start.gmtDate
    }

    static func < (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.start.gmtDate < rhs.start.gmtDate
    }

    static func > (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.start.gmtDate > rhs.start.gmtDate
    }

    static func <= (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.start.gmtDate <= rhs.start.gmtDate
    }

    static func >= (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        return lhs.start.gmtDate >= rhs.start.gmtDate
    }
}
