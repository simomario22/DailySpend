//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class CalendarDay {
    private var date: Date
    
    /*
     * @param date A date representing a point in time that is in the
     * desired day when using the GMT time zone.
     */
    init?(dateInDay date: CalendarDateProvider?) {
        guard let date = date else {
            return nil
        }
        // Set date to the beginning of the GMT day.
        self.date = CalendarDay.gmtCal.startOfDay(for: date.gmtDate)
    }


    /*
     * @param date A date representing a point in time that is in the
     * desired day when using the GMT time zone.
     */
    init(dateInDay date: CalendarDateProvider) {
        // Set date to the beginning of the GMT day.
        self.date = CalendarDay.gmtCal.startOfDay(for: date.gmtDate)
    }
    /*
     * @param localDateInDay A date representing a point in time that is in the
     * desired day when using the system's current time zone.
     */
    convenience init(localDateInDay date: Date) {
        // Convert to the beginning of this date's day in GMT
        let systemCal = Calendar(identifier: .gregorian)

        let componentSet: Set<Calendar.Component> = [.year, .month, .day]

        let dateComponents = systemCal.dateComponents(componentSet, from: date)

        let dateInSameDayInGMT = CalendarDay.gmtCal.date(from: dateComponents)!

        self.init(dateInDay: GMTDate(dateInSameDayInGMT))
    }

    convenience init() {
        self.init(localDateInDay: Date())
    }
    
    private init(trustedDate: Date) {
        self.date = trustedDate
    }

    /*
     * Returns a CalendarDay after adding a certain number of days.
     */
    func add(days: Int) -> CalendarDay {
        let cal = CalendarDay.gmtCal
        let newDate = cal.date(byAdding: .day, value: days, to: self.date)!
        return CalendarDay(trustedDate: newDate)
    }

    func subtract(days: Int) -> CalendarDay {
        return self.add(days: -days)
    }
    
    /**
     * Returns the number of days that this day is after `startDay`.
     * If this day is before start day, this function will return a negative
     * number.
     */
    func daysAfter(startDay: CalendarDay) -> Int {
        return CalendarDay.gmtCal.dateComponents(
            [.day],
            from: startDay.start.gmtDate,
            to: self.date
        ).day!
    }

    static func daysInRange(start: CalendarDay, end: CalendarDay) -> Int {
        return abs(
            CalendarDay.gmtCal.dateComponents(
                [.day],
                from: start.start.gmtDate,
                to: end.start.gmtDate
            ).day!
        )
    }

    func string(formatter: DateFormatter, friendly: Bool = false) -> String {
        if friendly {
            let today = CalendarDay()
            if self == today {
                return "Today"
            } else if self == today.add(days: 1) {
                return "Tomorrow"
            } else if self == today.subtract(days: 1) {
                return "Yesterday"
            }
        }
        let origTZ = formatter.timeZone
        formatter.timeZone = CalendarDay.gmtTimeZone

        let s = formatter.string(from: date)

        formatter.timeZone = origTZ

        return s
    }

    var day: Int {
        return CalendarDay.gmtCal.component(.day, from: self.date)
    }
    
    var weekOfMonth: Int {
        return CalendarDay.gmtCal.component(.weekOfMonth, from: self.date)
    }

    var month: Int {
        return CalendarDay.gmtCal.component(.month, from: self.date)
    }

    var year: Int {
        return CalendarDay.gmtCal.component(.year, from: self.date)
    }

    static var gmtTimeZone: TimeZone {
        return TimeZone(secondsFromGMT: 0)!
    }

    private static var _gmtCal: Calendar?
    private static var gmtCal: Calendar {
        if let cal = CalendarDay._gmtCal {
            return cal
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = CalendarDay.gmtTimeZone
        CalendarDay._gmtCal = cal
        return cal
    }
    
    var period: PeriodScope {
        return .Day
    }
}

extension CalendarDay: CalendarIntervalProvider {
    /*
     * This represents a point in time that is 12:00:00am on the day that this
     * CalendarDay represents.
     */
    var start: CalendarDateProvider {
        return GMTDate(date)
    }
    
    var end: CalendarDateProvider? {
        return self.add(days: 1).start
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

extension CalendarDay: Comparable {
    static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.start.gmtDate == rhs.start.gmtDate
    }

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.start.gmtDate < rhs.start.gmtDate
    }

    static func > (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.start.gmtDate > rhs.start.gmtDate
    }

    static func <= (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.start.gmtDate <= rhs.start.gmtDate
    }

    static func >= (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.start.gmtDate >= rhs.start.gmtDate
    }
}
