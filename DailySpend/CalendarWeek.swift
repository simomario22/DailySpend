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
     * @param dateInGMTWeek A date representing a point in time that is in
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
     * @param dateInLocalWeek A date representing a point in time that is in
     * the desired week when using the system's current time zone.
     */
    convenience init(dateInLocalWeek date: Date) {
        self.init(day: CalendarDay(dateInLocalDay: date))
    }


    convenience init() {
        self.init(dateInLocalWeek: Date())
    }
    
    private init(trustedDate: Date) {
        self.date = trustedDate
    }

    /*
     * Returns a date by adding weeks then weeks by incrementing those values
     * in that order.
     */
    func add(weeks: Int) -> CalendarWeek {
        let cal = CalendarWeek.gmtCal
        let newDate = cal.date(byAdding: .day,
                               value: weeks * self.typicalDaysInWeek,
                               to: self.date)!
        return CalendarWeek(trustedDate: newDate)
    }

    func subtract(weeks: Int) -> CalendarWeek {
        return self.add(weeks: -weeks)
    }
    
    /**
     * Returns the number of weeks that this week is after `startWeek`.
     * If this week is before start week, this function will return a negative
     * number.
     */
    func weeksAfter(startWeek: CalendarWeek) -> Int {
        // `weekOfMonth` in this case gives the number we are looking for:
        // the number of weeks between the two we are comparing.
        return CalendarWeek.gmtCal.dateComponents(
            [.weekOfMonth],
            from: startWeek.gmtDate,
            to: self.gmtDate
        ).weekOfMonth!
    }


    func string(formatter: DateFormatter) -> String {
        let origTZ = formatter.timeZone
        formatter.timeZone = CalendarWeek.gmtTimeZone

        let s = formatter.string(from: date)

        formatter.timeZone = origTZ

        return s
    }

    func contains(day: CalendarDay) -> Bool {
        return day.weekOfMonth == self.weekOfMonth && day.month == self.month && day.year == self.year
    }

    var typicalDaysInWeek: Int {
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

    private static var _gmtCal: Calendar?
    private static var gmtCal: Calendar {
        if let cal = CalendarWeek._gmtCal {
            return cal
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = CalendarWeek.gmtTimeZone
        _gmtCal = cal
        return cal
    }

    /*
     * This represents a point in time that is 12:00:00am on the first day of
     * the week that this CalendarWeek represents.
     */
    var gmtDate: Date {
        return date
    }
    
    var period: PeriodScope {
        return .Week
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
