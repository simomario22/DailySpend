//
//  CalendarPeriod.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/1/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

/**
 * An interval in time, of length `period`.
 */
public class CalendarPeriod {
    
    /**
     * The first Date included in the period, in GMT.
     */
    private(set) public var start: Date
    
    /**
     * The first Date after `first` *not* included in the period, in GMT.
     */
    private(set) public var end: Date
    
    /**
     * The `Period` interval of this period.
     */
    private(set) public var period: Period
    
    private var previousStart: Date // Memoize this for quick subtraction.
    
    
    /**
     * We need to adjust the start of this period based on the beginning of
     * another period, otherwise we could start on the "off period".
     * For example, starting in the middle of a period in a 2 week period.
     */
    private func adjustForBeginningOfPeriod(_ intervalStart: Date, periodStart: Date) {
        
    }

    /**
     * Initialize a concrete interval in time.
     *
     * @param date A date in the period interval you'd like created, in GMT.
     * @param period The interval you'd like to represent.
     * @param intervalStart The start of any period of this interval.
     */
    init?(dateInGMTPeriod date: Date, period: Period, beginningDateOfPeriod intervalStart: Date) {
        switch period.scope {
        case .Day:
            // Ensure day is at the beginning of a period.
            // (e.g. make sure it's the first day of a three day period).
            var day = CalendarDay(dateInGMTDay: date)
            let beginningPeriod = CalendarDay(dateInGMTDay: intervalStart)
            let difference = day.daysAfter(startDay: beginningPeriod)
            let offset = difference % period.multiplier
            day = day.subtract(days: offset)
            
            self.start = day.gmtDate
            self.end = day.add(days: period.multiplier).gmtDate
            self.previousStart = day.subtract(days: period.multiplier).gmtDate
        case .Week:
            // Ensure week is at the beginning of a period.
            // (e.g. make sure it's the first week of a three week period).
            var week = CalendarWeek(dateInGMTWeek: date)
            let beginningPeriod = CalendarWeek(dateInGMTWeek: intervalStart)
            let difference = week.weeksAfter(startWeek: beginningPeriod)
            let offset = difference % period.multiplier
            week = week.subtract(weeks: offset)

            self.start = week.gmtDate
            self.end = week.add(weeks: period.multiplier).gmtDate
            self.previousStart = week.subtract(weeks: period.multiplier).gmtDate
        case .Month:
            // Ensure month is at the beginning of a period.
            // (e.g. make sure it's the first month of a three month period).
            var month = CalendarMonth(dateInGMTMonth: date)
            let beginningPeriod = CalendarMonth(dateInGMTMonth: intervalStart)
            let difference = month.monthsAfter(startMonth: beginningPeriod)
            let offset = difference % period.multiplier
            month = month.subtract(months: offset)

            self.start = month.gmtDate
            self.end = month.add(months: period.multiplier).gmtDate
            self.previousStart = month.subtract(months: period.multiplier).gmtDate
        default:
            return nil
        }
        
        self.period = period
    }
    
    func nextCalendarPeriod() -> CalendarPeriod {
        return CalendarPeriod(dateInGMTPeriod: end, period: period, beginningDateOfPeriod: start)!
    }
    
    func previousCalendarPeriod() -> CalendarPeriod {
        return CalendarPeriod(dateInGMTPeriod: previousStart, period: period, beginningDateOfPeriod: start)!
    }
}

/**
 * An abstract unit of time.
 */
public enum PeriodScope: Int {
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
    
    func scopeConformsToDate(_ date: Date) -> Bool {
        switch self {
        case .None:
            return true
        case .Day:
            return CalendarDay(dateInGMTDay: date).gmtDate == date
        case .Week:
            return CalendarWeek(dateInGMTWeek: date).gmtDate == date
        case .Month:
            return CalendarMonth(dateInGMTMonth: date).gmtDate == date
        }
    }
}

extension PeriodScope : Comparable {
    static public func == (lhs: PeriodScope, rhs: PeriodScope) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    static public func < (lhs: PeriodScope, rhs: PeriodScope) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/**
 * Abstract interval of time, represented by a multiplier for a `PeriodScope` unit.
 */
public struct Period {
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
    static public func == (lhs: Period, rhs: Period) -> Bool {
        return lhs.scope == rhs.scope && lhs.multiplier == rhs.multiplier
    }
    
    static public func < (lhs: Period, rhs: Period) -> Bool {
        if lhs.scope < rhs.scope {
            return true
        } else if lhs.scope > rhs.scope {
            return false
        } else {
            return lhs.multiplier < rhs.multiplier
        }
    }
}
