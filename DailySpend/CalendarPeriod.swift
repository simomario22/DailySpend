//
//  CalendarPeriod.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/1/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

/**
 * A protocol providing a calendar interval in time, independent of time zone.
 */
protocol CalendarIntervalProvider {
    /**
     * The first Date included in the period, in GMT.
     */
    var start: CalendarDateProvider { get }
    
    /**
     * The first Date after `first` *not* included in the period, in GMT.
     */
    var end: CalendarDateProvider? { get }
}

/**
 * A protocol providing a calendar date, independent of time zone.
 */
protocol CalendarDateProvider {
    /**
     * The date this provider represents, in GMT.
     */
    var gmtDate: Date { get }
    
    /**
     * Returns a formatted string for the date represented by this provider.
     */
    func string(formatter: DateFormatter) -> String
}

struct GMTDate : CalendarDateProvider {
    var gmtDate: Date
    init(_ gmtDate: Date) {
        self.gmtDate = gmtDate
    }
    
    func string(formatter: DateFormatter) -> String {
        let origTZ = formatter.timeZone
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let s = formatter.string(from: self.gmtDate)
        
        formatter.timeZone = origTZ
        
        return s
    }
}

/**
 * An interval in time with start and end explicitly specified, but no period
 * attached.
 */
class CalendarInterval : CalendarIntervalProvider {
    private(set) var start: CalendarDateProvider
    private(set) var end: CalendarDateProvider?

    init(start: CalendarDateProvider, end: CalendarDateProvider?) {
        self.start = start
        self.end = end
    }

    init(localStart: Date, localEnd: Date?) {
        self.start = CalendarDay(localDateInDay: localStart).start
        self.end = localEnd != nil ? CalendarDay(localDateInDay: localEnd!).start : nil
    }
}

/**
 * An interval in time based on a `CalendarDay`, `CalendarWeek`, or
 * `CalendarMonth`, of maximum length `period`.
 */
class CalendarPeriod : CalendarIntervalProvider {
    private(set) var start: CalendarDateProvider
    private(set) var end: CalendarDateProvider?
    
    /**
     * The `Period` interval of this period.
     */
    private(set) var period: Period
    
    private var previousStart: CalendarDateProvider // Memoize this for quick subtraction.
    private var isPartialPeriod: Bool = false

    /**
     * Initializes a concrete interval in time.
     *
     * - Parameters:
     *    - calendarDate: A date in the period interval you'd like created.
     *    - period: The interval you'd like to represent.
     *    - intervalStart: The start of any period of this interval.
     *    - endBound: If not `nil`, the end of the period will be bounded by
     *                this value. That is, the end date will be no later than
     *                this value. If this date is in the period interval, this
     *                period will be considered a partial period and the
     *                following period will be `nil`.
     */
    init?(
        calendarDate date: CalendarDateProvider,
        period: Period,
        beginningDateOfPeriod intervalStart: CalendarDateProvider,
        boundingEndDate endBound: CalendarDateProvider?
    ) {
        switch period.scope {
        case .Day:
            // Ensure day is at the beginning of a period.
            // (e.g. make sure it's the first day of a three day period).
            var day = CalendarDay(dateInDay: date)
            let beginningPeriod = CalendarDay(dateInDay: intervalStart)
            let difference = day.daysAfter(startDay: beginningPeriod)
            let offset = difference % period.multiplier
            day = day.subtract(days: offset)
            
            self.start = day.start
            self.end = day.add(days: period.multiplier).start
            self.previousStart = day.subtract(days: period.multiplier).start
        case .Week:
            // Ensure week is at the beginning of a period.
            // (e.g. make sure it's the first week of a three week period).
            var week = CalendarWeek(dateInWeek: date)
            let beginningPeriod = CalendarWeek(dateInWeek: intervalStart)
            let difference = week.weeksAfter(startWeek: beginningPeriod)
            let offset = difference % period.multiplier
            week = week.subtract(weeks: offset)

            self.start = week.start
            self.end = week.add(weeks: period.multiplier).start
            self.previousStart = week.subtract(weeks: period.multiplier).start
        case .Month:
            // Ensure month is at the beginning of a period.
            // (e.g. make sure it's the first month of a three month period).
            var month = CalendarMonth(dateInMonth: date)
            let beginningPeriod = CalendarMonth(dateInMonth: intervalStart)
            let difference = month.monthsAfter(startMonth: beginningPeriod)
            let offset = difference % period.multiplier
            month = month.subtract(months: offset)

            self.start = month.start
            self.end = month.add(months: period.multiplier).start
            self.previousStart = month.subtract(months: period.multiplier).start
        default:
            return nil
        }
        
        if endBound != nil {
            if endBound!.gmtDate < self.start.gmtDate {
                // This is an invalid end bound.
                return nil
            } else if endBound!.gmtDate < self.end!.gmtDate {
                // This end bound is in the interval. Shorten the interval.
                self.end = endBound!
                self.isPartialPeriod = true
            }
        }
        
        self.period = period
    }
    
    /**
     * Returns the number of intervals of length `period` that are contained
     * within this interval.
     */
    func numberOfSubPeriodsOfLength(period: Period) -> Int {
        if self.period < period || period.scope == .None {
            return 0
        }

        let lastDayInThisCalendarPeriod = CalendarDay(dateInDay: self.end!).subtract(days: 1)
        if self.start.gmtDate == lastDayInThisCalendarPeriod.start.gmtDate {
            return 0
        }
        
        let lastSubPeriod = CalendarPeriod(
            calendarDate: lastDayInThisCalendarPeriod.start,
            period: period,
            beginningDateOfPeriod: self.start,
            boundingEndDate: self.end
        )!
        
        let index = lastSubPeriod.periodIndexWithin(superPeriod: self)
        return index != nil ? index! + 1 : 0
    }
    
    /**
     * Returns the index of this interval within a larger interval.
     *
     * For example, if the period for this CalendarPeriod is 2 days, and its
     * interval begins on the fourth day of the month, and the passed
     * `superPeriod` is the month that this interval is in, this function will
     * return `1`, the second index.
     *
     * If this period is not an even multiple away from, or is not contained by
     * the larger period, or if the passed `superPeriod` is smaller, then this
     * function will return nil.
     */
    func periodIndexWithin(superPeriod: CalendarPeriod) -> Int? {
        if superPeriod.period < period ||
            start.gmtDate >= superPeriod.end!.gmtDate ||
            start.gmtDate < superPeriod.start.gmtDate {
            return nil
        }

        let beginningPeriod = CalendarDay(dateInDay: superPeriod.start)
        var difference: Int
        var remainder: Int
        switch period.scope {
        case .Day:
            let day = CalendarDay(dateInDay: self.start)
            difference = day.daysAfter(startDay: beginningPeriod)
            remainder = 0
        case .Week:
            let week = CalendarWeek(dateInWeek: self.start)
            (difference, remainder) = week.weeksAfter(start: beginningPeriod)
        case .Month:
            let month = CalendarMonth(dateInMonth: self.start)
            (difference, remainder) = month.monthsAfter(start: beginningPeriod)
        default:
            return nil
        }
        
        if remainder == 0 && difference % self.period.multiplier == 0 {
            return difference / self.period.multiplier
        } else {
            return nil
        }
    }

    /**
     * Returns true if this interval contains the date, false otherwise.
     */
    func contains(date: CalendarDateProvider) -> Bool {
        return date.gmtDate >= start.gmtDate && date.gmtDate < end!.gmtDate
    }
    
    func nextCalendarPeriod() -> CalendarPeriod? {
        if isPartialPeriod {
            return nil
        }
        
        return CalendarPeriod(
            calendarDate: end!,
            period: period,
            beginningDateOfPeriod: start,
            boundingEndDate: nil
        )!
    }
    
    func previousCalendarPeriod() -> CalendarPeriod {
        return CalendarPeriod(
            calendarDate: previousStart,
            period: period,
            beginningDateOfPeriod: start,
            boundingEndDate: nil
        )!
    }
}

/**
 * An abstract unit of time.
 */
enum PeriodScope: Int {
    case None = -1
    case Day = 0
    case Week = 1
    case Month = 2
    
    func string() -> String {
        switch self {
        case .None:
            return "None"
        case .Day:
            return "Day"
        case .Week:
            return "Week"
        case .Month:
            return "Month"
        }
    }
    
    init(_ value: String) {
        switch value {
        case "Day":
            self = .Day
        case "Week":
            self = .Week
        case "Month":
            self = .Month
        default:
            self = .None
        }
    }
    
    /**
     * Returns `true` if this date is at the beginning a `PeriodScope`.
     */
    func scopeConformsToDate(_ date: Date) -> Bool {
        // This date is untrusted, but we will test it like a GMT date to see
        // if it conforms to the PeriodScope.
        let gmtDate = GMTDate(date)
        
        switch self {
        case .None:
            return true
        case .Day:
            return CalendarDay(dateInDay: gmtDate).start.gmtDate == date
        case .Week:
            return CalendarWeek(dateInWeek: gmtDate).start.gmtDate == date
        case .Month:
            return CalendarMonth(dateInMonth: gmtDate).start.gmtDate == date
        }
    }
}

extension PeriodScope : Comparable {
    static func == (lhs: PeriodScope, rhs: PeriodScope) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    static func < (lhs: PeriodScope, rhs: PeriodScope) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/**
 * Abstract interval of time, represented by a multiplier for a `PeriodScope` unit.
 */
struct Period {
    var scope: PeriodScope
    var multiplier: Int
    
    func string() -> String {
        return multiplier == 1 ? scope.string() : "\(multiplier) " + scope.string() + "s"
    }
    
    static var none: Period {
        return Period(scope: .None, multiplier: 0)
    }
}

extension Period : Comparable {
    static func == (lhs: Period, rhs: Period) -> Bool {
        return lhs.scope == rhs.scope && lhs.multiplier == rhs.multiplier
    }
    
    static func < (lhs: Period, rhs: Period) -> Bool {
        if lhs.scope < rhs.scope {
            return true
        } else if lhs.scope > rhs.scope {
            return false
        } else {
            return lhs.multiplier < rhs.multiplier
        }
    }
}
