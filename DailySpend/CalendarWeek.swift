//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class CalendarWeek {
    private var date: Date

    /*
     * @param dateInGMTWeek A date representing a point in time that is in
     * the desired week when using the GMT time zone.
     */
    init(dateInWeek date: CalendarDateProvider) {
        let gmtCal = CalendarWeek.gmtCal

        let componentSet: Set<Calendar.Component> = [.year, .month, .weekOfMonth, .weekday]

        var dateComponents = gmtCal.dateComponents(componentSet, from: date.gmtDate)
        dateComponents.setValue(1, for: .weekday)

        self.date = gmtCal.startOfDay(for: gmtCal.date(from: dateComponents)!)
    }

    convenience init(dayInWeek: CalendarDay) {
        self.init(dateInWeek: dayInWeek.start)
    }

    /*
     * @param dateInLocalWeek A date representing a point in time that is in
     * the desired week when using the system's current time zone.
     */
    convenience init(localDateInWeek date: Date) {
        self.init(dayInWeek: CalendarDay(localDateInDay: date))
    }


    convenience init() {
        self.init(localDateInWeek: Date())
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
                               value: weeks * CalendarWeek.typicalDaysInWeek,
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
     *
     * Note that this returns the number of weeks
     */
    func weeksAfter(startWeek: CalendarWeek) -> Int {
        // `weekOfMonth` in this case gives the number we are looking for:
        // the number of weeks between the two we are comparing.
        return CalendarWeek.gmtCal.dateComponents(
            [.weekOfMonth],
            from: startWeek.start.gmtDate,
            to: self.date
        ).weekOfMonth!
    }

    /**
     * Returns the number of weeks that this week is after `startWeek`.
     * If this week is before start week, this function will return a negative
     * number.
     *
     * Also returns the remainder of days that didn't fit into an even number
     * of weeks.
     */
    func weeksAfter(start: CalendarDay) -> (Int, Int) {
        // `weekOfMonth` in this case gives the number we are looking for:
        // the number of weeks between the two we are comparing.
        let components = CalendarWeek.gmtCal.dateComponents(
            [.weekOfMonth, .day],
            from: start.start.gmtDate,
            to: self.date
        )
        return (components.weekOfMonth!, components.day!)
    }

    func string(formatter: DateFormatter, relative: Bool = false) -> String {
        if relative {
            let thisWeek = CalendarWeek()
            if self == thisWeek {
                return "This Week"
            } else if self == thisWeek.add(weeks: 1) {
                return "Next Week"
            } else if self == thisWeek.subtract(weeks: 1) {
                return "Last Week"
            }
        }

        let origTZ = formatter.timeZone
        formatter.timeZone = CalendarWeek.gmtTimeZone

        let s = formatter.string(from: date)

        formatter.timeZone = origTZ

        return s
    }

    func contains(day: CalendarDay) -> Bool {
        return day.weekOfMonth == self.weekOfMonth && day.month == self.month && day.year == self.year
    }

    class var typicalDaysInWeek: Int {
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

    
    var period: PeriodScope {
        return .Week
    }
}

extension CalendarWeek: CalendarIntervalProvider {
    /*
     * This represents a point in time that is 12:00:00am on the first day of
     * the week that this CalendarWeek represents.
     */
    var start: CalendarDateProvider {
        return GMTDate(date)
    }
    
    var end: CalendarDateProvider? {
        return self.add(weeks: 1).start
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

    func equals(interval: CalendarIntervalProvider) -> Bool {
        return self.start.gmtDate == interval.start.gmtDate && self.end?.gmtDate == interval.end?.gmtDate
    }
}

extension CalendarWeek: Comparable, Hashable {
    static func == (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.start.gmtDate == rhs.start.gmtDate
    }

    static func < (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.start.gmtDate < rhs.start.gmtDate
    }

    static func > (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.start.gmtDate > rhs.start.gmtDate
    }

    static func <= (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.start.gmtDate <= rhs.start.gmtDate
    }

    static func >= (lhs: CalendarWeek, rhs: CalendarWeek) -> Bool {
        return lhs.start.gmtDate >= rhs.start.gmtDate
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.start.gmtDate)
    }
}
