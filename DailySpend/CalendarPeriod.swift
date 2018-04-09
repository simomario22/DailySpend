//
//  CalendarPeriod.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/1/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

/**
 * This a class that refers to a specific period of time as an interval in days,
 * weeks, or months, abstract from time.
 */
public class CalendarPeriod {
    
    /**
     * The first Date included in the period.
     */
    private(set) public var start: Date
    
    /**
     * The first Date after `first` *not* included in the period.
     */
    private(set) public var end: Date
    
    /**
     * The `Period` interval of this period.
     */
    private(set) public var period: Period
    
    private var previousStart: Date // Memoize this for quick subtraction.

    init?(startOfPeriodInGMTTime start: Date, period: Period) {
        switch period.scope {
        case .Day:
            let day = CalendarDay(dateInGMTDay: start)
            self.start = day.gmtDate
            self.end = day.add(days: period.multiplier).gmtDate
            self.previousStart = day.subtract(days: period.multiplier).gmtDate
        case .Week:
            let week = CalendarWeek(dateInGMTWeek: start)
            self.start = week.gmtDate
            self.end = week.add(weeks: period.multiplier).gmtDate
            self.previousStart = week.subtract(weeks: period.multiplier).gmtDate
        case .Month:
            let month = CalendarMonth(dateInGMTMonth: start)
            self.start = month.gmtDate
            self.end = month.add(months: period.multiplier).gmtDate
            self.previousStart = month.subtract(months: period.multiplier).gmtDate
        default:
            return nil
        }
        
        self.period = period
    }
    
    func nextCalendarPeriod() -> CalendarPeriod {
        return CalendarPeriod(startOfPeriodInGMTTime: end, period: period)!
    }
    
    func previousCalendarPeriod() -> CalendarPeriod {
        return CalendarPeriod(startOfPeriodInGMTTime: previousStart, period: period)!
    }
}

/**
 * This is a type for the scope of the period: currently Day, Week, or Month.
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
 * This is the abstract notion of a period as an interval of time, but does
 * not refer to a specific period.
 */
public struct Period {
    var scope: PeriodScope
    var multiplier: Int
    
    func string() -> String {
        return multiplier == 1 ? scope.string() : "\(multiplier) " + scope.string() + "s"
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
