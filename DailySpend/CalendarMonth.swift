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
        self.init(day: CalendarDay(dateInLocalDay: date))
    }


    convenience init(day: CalendarDay) {
        self.init(dateInGMTMonth: day.gmtDate)
    }

    convenience init() {
        self.init(dateInLocalMonth: Date())
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
            from: startMonth.gmtDate,
            to: self.gmtDate
        ).month!
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
        return CalendarMonth.gmtCal.component(.month, from: self.gmtDate)
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

    /*
     * This represents a point in time that is 12:00:00am on the first day of
     * the month that this CalendarMonth represents.
     */
    var gmtDate: Date {
        return date
    }
    
    var period: PeriodScope {
        return .Month
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
