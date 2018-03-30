//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

public class CalendarDay {
    private var date: Date

    /*
     * @param dateInGMTDay A date representing a point in time that is in the
     * desired day when using the GMT time zone.
     */
    init(dateInGMTDay date: Date) {
        // Set date to the beginning of the GMT day.
        self.date = CalendarDay.gmtCal.startOfDay(for: date)
    }
    /*
     * @param dateInLocalDay A date representing a point in time that is in the
     * desired day when using the system's current time zone.
     */
    convenience init(dateInLocalDay date: Date) {
        // Convert to the beginning of this date's day in GMT
        let systemCal = Calendar(identifier: .gregorian)

        let componentSet: Set<Calendar.Component> = [.year, .month, .day]

        let dateComponents = systemCal.dateComponents(componentSet, from: date)

        let dateInSameDayInGMT = CalendarDay.gmtCal.date(from: dateComponents)!

        self.init(dateInGMTDay: dateInSameDayInGMT)
    }

    convenience init() {
        self.init(dateInLocalDay: Date())
    }

    /*
     * Returns a date by adding days then months by incrementing those values
     * in that order.
     */
    func add(days: Int) -> CalendarDay {
        let cal = CalendarDay.gmtCal

        // Get interval for days
        let interval = self.date.timeIntervalSince(cal.date(byAdding: .day,
                                                       value: days,
                                                       to: self.date)!)
        // Add interval to a copy of self
        var datePlusInterval = self.date
        datePlusInterval.addTimeInterval(-interval)
        return CalendarDay(dateInGMTDay: datePlusInterval)
    }

    func subtract(days: Int) -> CalendarDay {
        return self.add(days: -days)
    }

    static func daysInRange(start: CalendarDay, end: CalendarDay) -> Int {
        return abs(CalendarDay.gmtCal.dateComponents([.day],
                                                 from: start.gmtDate,
                                                 to: end.gmtDate).day!)
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

    /*
     * This represents a point in time that is 12:00:00am on the day that this
     * CalendarDay represents.
     */
    var gmtDate: Date {
        return date
    }


}

extension CalendarDay: Comparable {
    static public func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.gmtDate == rhs.gmtDate
    }

    static public func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.gmtDate < rhs.gmtDate
    }

    static public func > (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.gmtDate > rhs.gmtDate
    }

    static public func <= (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.gmtDate <= rhs.gmtDate
    }

    static public func >= (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.gmtDate >= rhs.gmtDate
    }
}
