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
    
    /**
     * Returns true if this interval contains the date, false otherwise.
     */
    func contains(date: CalendarDateProvider) -> Bool
    
    /**
     * Returns true if this interval contains the entire interval, false
     * otherwise.
     */
    func contains(interval: CalendarIntervalProvider) -> Bool

    /**
     * Returns true if this interval is exactly the same as the passed interval,
     * false otherwise.
     */
    func equals(interval: CalendarIntervalProvider) -> Bool
    
    /**
     * Returns true if any portion of this interval overlaps with any portion
     * of the passed interval.
     */
    func overlaps(with interval: CalendarIntervalProvider) -> Bool
    
    /**
     * Returns the interval of maximum size contained by both intervals, or
     * `nil` if no such intervals exists.
     */
    func overlappingInterval(with interval: CalendarIntervalProvider) -> CalendarIntervalProvider?
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

    /**
     * Returns a formatted string for the date represented by this provider,
     * optionally with human friendly relative dates.
     */
    func string(formatter: DateFormatter, relative: Bool) -> String
}

struct GMTDate : CalendarDateProvider {
    var gmtDate: Date
    init(_ gmtDate: Date) {
        self.gmtDate = gmtDate
    }
    
    func string(formatter: DateFormatter) -> String {
        return self.string(formatter: formatter, relative: false)
    }
    
    func string(formatter: DateFormatter, relative: Bool) -> String {
        if relative {
            let today = CalendarDay()
            let date = self.gmtDate
            if date == today.start.gmtDate {
                return "Today"
            } else if date == today.add(days: 1).start.gmtDate {
                return "Tomorrow"
            } else if date == today.subtract(days: 1).start.gmtDate {
                return "Yesterday"
            }
        }

        let origTZ = formatter.timeZone
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let s = formatter.string(from: self.gmtDate)
        
        formatter.timeZone = origTZ
        
        return s
    }
}

fileprivate func intervalContains(container: CalendarIntervalProvider, containee: CalendarIntervalProvider) -> Bool {
    if container.start.gmtDate > containee.start.gmtDate {
        return false
    }

    if containee.end == nil && container.end != nil {
        return false
    }

    if containee.end != nil && container.end != nil {
        return containee.end!.gmtDate <= container.end!.gmtDate
    }

    return true
}

/**
 * An interval in time with start and end explicitly specified, but no period
 * attached.
 */
class CalendarInterval : CalendarIntervalProvider {
    private(set) var start: CalendarDateProvider
    private(set) var end: CalendarDateProvider?

    init?(start: CalendarDateProvider, end: CalendarDateProvider?) {
        if end != nil && start.gmtDate > end!.gmtDate {
            return nil
        }
        self.start = start
        self.end = end
    }

    init?(localStart: Date, localEnd: Date?) {
        if localEnd != nil && localStart > localEnd! {
            return nil
        }
        self.start = CalendarDay(localDateInDay: localStart).start
        self.end = localEnd != nil ? CalendarDay(localDateInDay: localEnd!).start : nil
    }
    
    /**
     * Returns true if this interval contains the date, false otherwise.
     */
    func contains(date: CalendarDateProvider) -> Bool {
        return date.gmtDate >= start.gmtDate &&
                (end == nil || date.gmtDate < end!.gmtDate)
    }

    /**
     * Returns true if this interval wholly contains the entire interval, false
     * otherwise.
     */
    func contains(interval: CalendarIntervalProvider) -> Bool {
        return intervalContains(container: self, containee: interval)
    }
    
    /**
     * Returns true if any portion of this interval overlaps with any portion
     * of the passed interval.
     */
    func overlaps(with interval: CalendarIntervalProvider) -> Bool {
        if interval.end != nil && self.start.gmtDate > interval.end!.gmtDate {
            return false
        }
        
        if self.end != nil && self.end!.gmtDate < interval.start.gmtDate {
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

    func string(formatter: DateFormatter, relative: Bool) -> String {
        let startString = self.start.string(formatter: formatter, relative: relative)
        if let end = end {
            let endString = end.string(formatter: formatter, relative: relative)
            return "\(startString) – \(endString)"
        } else {
            return "From \(startString) onward"
        }
    }
}

/**
 * An interval in time that represents a period associated with a particular
 * goal.
 */
class GoalPeriod : CalendarIntervalProvider {
    enum PeriodStyle {
        /**
         * Instructs the `GoalPeriod` to represent and iterate between a goal's
         * periods.
         */
        case period
        /**
         * Instructs the `GoalPeriod` to represent and iterate between a goal's
         * pay intervals.
         */
        case payInterval
    }

    var start: CalendarDateProvider
    var end: CalendarDateProvider?
    let goal: Goal
    let style: PeriodStyle

    init?(goal: Goal, date: CalendarDateProvider, style: PeriodStyle) {
        guard let schedule = goal.activePaySchedule(on: date) else {
            return nil
        }

        let scheduleFunction = (style == .period ? schedule.periodInterval : schedule.incrementalPaymentInterval)
        guard let period = scheduleFunction(date) else {
            return nil
        }

        self.goal = goal
        self.style = style
        self.start = period.start
        self.end = period.end
    }

    /**
     * Returns the period following this one in `goal`, depending on `style`.
     * If no such period exists, returns `nil`.
     */
    func nextGoalPeriod() -> GoalPeriod? {
        guard let exclusiveEndDate = CalendarDay(dateInDay: end)?.start else {
            return nil
        }

        return GoalPeriod(goal: goal, date: exclusiveEndDate, style: style)
    }

    /**
     * Returns the period preceeding this one in `goal`, depending on `style`.
     * If no such period exists, returns `nil`.
     */
    func previousGoalPeriod() -> GoalPeriod? {
        let exclusiveStartDate = CalendarDay(dateInDay: start).subtract(days: 1).start
        return GoalPeriod(goal: goal, date: exclusiveStartDate, style: style)
    }

    /**
     * Returns a string representing the interval. If this is representing a
     * recurring pay schedule period, there are options to print friendly or
     * relative intervals.
     *
     * - Parameters:
     *    - friendly: This will use month names and years if not in this year
     *      instead of dates.
     *    - relative: This will use language for relative days, weeks, and
     *      months for the current, previous, and next period.
     */
    func string(friendly: Bool, relative: Bool) -> String {
        let schedule = goal.activePaySchedule(on: self.start)!
        let period = style == .period ? schedule.period : schedule.payFrequency

        let isPartialPeriod = !isDateAtBeginningOfContainingScope(date: self.start, scope: period.scope) ||
            (self.end != nil && !isDateAtBeginningOfContainingScope(date: self.end!, scope: period.scope))

        let scope = friendly && schedule.isRecurring && !isPartialPeriod ? period.scope : .None
        let multiplier = friendly && schedule.isRecurring && !isPartialPeriod ? period.multiplier : (CalendarDay(dateInDay:self.start).end!.gmtDate ==  self.end?.gmtDate ? 1 : 2)

        let firstComponent = stringComponent(date: self.start, scope: scope, relative: relative)
        if multiplier == 1 {
            // Just return the first component - this represents a single
            // iteration of a scope: one day, week, or month.
            if period.scope == .Week {
                let thisWeek = CalendarWeek()
                let week = CalendarWeek(dateInWeek: self.start)
                if !relative || (week != thisWeek && week != thisWeek.add(weeks: 1) && week != thisWeek.subtract(weeks: 1)) {
                    // This is a representation of a week in a .short date
                    // format. Special case here, we'd like to represent one
                    // week differently than multiple in this case.
                    return "Week of " + firstComponent
                }
            }
            return firstComponent
        }

        if let end = self.end {
            // Get inclusive interval.
            let inclusiveEnd = CalendarDay(dateInDay: end).subtract(days: 1)
            let secondComponent = stringComponent(date: inclusiveEnd.start, scope: scope, relative: relative)
            return "\(firstComponent) - \(secondComponent)"
        } else {
            return "From \(firstComponent) onward"
        }
    }

    private func isDateAtBeginningOfContainingScope(date: CalendarDateProvider, scope: PeriodScope) -> Bool {
        switch scope {
        case .Day, .None:
            return CalendarDay(dateInDay: date).start.gmtDate == date.gmtDate
        case .Week:
            return CalendarWeek(dateInWeek: date).start.gmtDate == date.gmtDate
        case .Month:
            return CalendarMonth(dateInMonth: date).start.gmtDate == date.gmtDate
        }
    }

    private func stringComponent(date: CalendarDateProvider, scope: PeriodScope, relative: Bool) -> String {
        let df = DateFormatter()

        switch scope {
        case .Day, .None:
            df.timeStyle = .none
            df.dateStyle = .short
            return CalendarDay(dateInDay: date).string(formatter: df, relative: relative)
        case .Week:
            df.timeStyle = .none
            df.dateStyle = .short
            return CalendarWeek(dateInWeek: date).string(formatter: df, relative: relative)
        case .Month:
            let month = CalendarMonth(dateInMonth: date)
            if month.year == CalendarDay().year {
                df.dateFormat = "MMMM"
            } else {
                df.dateFormat = "MMMM yyyy"
            }
            return month.string(formatter: df, relative: relative)
        }
    }

    /**
     * Returns true if this interval contains the date, false otherwise.
     */
    func contains(date: CalendarDateProvider) -> Bool {
        return date.gmtDate >= start.gmtDate &&
            (end == nil || date.gmtDate < end!.gmtDate)
    }

    /**
     * Returns true if this interval wholly contains the entire interval, false
     * otherwise.
     */
    func contains(interval: CalendarIntervalProvider) -> Bool {
        return intervalContains(container: self, containee: interval)
    }

    /**
     * Returns true if any portion of this interval overlaps with any portion
     * of the passed interval.
     */
    func overlaps(with interval: CalendarIntervalProvider) -> Bool {
        if interval.end != nil && self.start.gmtDate > interval.end!.gmtDate {
            return false
        }

        if self.end != nil && self.end!.gmtDate < interval.start.gmtDate {
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

/**
 * An interval in time based on a `CalendarDay`, `CalendarWeek`, or
 * `CalendarMonth`, of maximum length `period`.
 */
class CalendarPeriod : CalendarIntervalProvider {
    private(set) var start: CalendarDateProvider
    /**
     * The end of the `CalendarPeriod`. This property will never be `nil`.
     */
    private(set) var end: CalendarDateProvider?
    
    /**
     * The `Period` interval of this period.
     */
    private(set) var period: Period
    
    private var previousStart: CalendarDateProvider? // Memoize this for quick subtraction.

    /**
     * The beginning date of any CalendarPeriod in this sequence.
     *
     * If this is a partial period, this may be different than the start date.
     */
    private var beginningDateOfPeriod: CalendarDateProvider
    private var isPartialPeriod: Bool = false

    /**
     * The number of days the length of this period was reduced by in order to
     * bound it with the passed bounds.
     */
    private(set) var partialPeriodLengthReductionInDays = 0

    /**
     * Initializes a concrete interval in time.
     *
     * - Parameters:
     *    - calendarDate: A date in the period interval you'd like created.
     *    - period: The interval you'd like to represent.
     *    - beginningDateOfPeriod: The start of any full period of this interval.
     *    - boundingStartDate: If not `nil`, the start date of the period will
     *      be bounded by this valid. That is, the start date will be no later
     *      than this value. If this date is in the period interval, this
     *      period will be considered a partial period and the preceeding period
     *      will be `nil`.
     *    - boundingEndDate: If not `nil`, the end of the period will be bounded
     *      by this value. That is, the end date will be no later than this
     *      value. If this date is in the period interval, this period will be
     *      considered a partial period and the following period will be `nil`.
     */
    init?(
        calendarDate date: CalendarDateProvider,
        period: Period,
        beginningDateOfPeriod intervalStart: CalendarDateProvider,
        boundingStartDate startBound: CalendarDateProvider?,
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

        self.beginningDateOfPeriod = self.start

        if let endBound = endBound {
            if endBound.gmtDate < self.start.gmtDate {
                // This is an invalid end bound.
                return nil
            } else if endBound.gmtDate < self.end!.gmtDate {
                // This end bound is in the interval. Shorten the interval.

                // Calculate the number of days subtracted. This is used to
                // calculate pay on this day.
                let oldEnd = CalendarDay(dateInDay: self.end!)
                let newEnd = CalendarDay(dateInDay: endBound)
                self.partialPeriodLengthReductionInDays += oldEnd.daysAfter(startDay: newEnd)

                self.end = endBound
                self.isPartialPeriod = true
            }
        }

        if let startBound = startBound {
            if startBound.gmtDate > self.end!.gmtDate {
                // This is an invalid start bound.
                return nil
            } else if startBound.gmtDate > self.start.gmtDate {
                // This start bound is in the interval. Shorten the interval.

                // Calculate the number of days added. This is used to
                // calculate pay on this day.
                let oldStart = CalendarDay(dateInDay: self.start)
                let newStart = CalendarDay(dateInDay: startBound)
                self.partialPeriodLengthReductionInDays += newStart.daysAfter(startDay: oldStart)

                self.start = startBound
                self.beginningDateOfPeriod = intervalStart
                self.previousStart = nil
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
            beginningDateOfPeriod: self.beginningDateOfPeriod,
            boundingStartDate: nil,
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
     * Partial periods are counted the same as full periods.
     *
     * If this period is not is not contained by the larger period,
     * or if the passed `superPeriod` is smaller, then this function will
     * return nil.
     */
    func periodIndexWithin(superPeriod: CalendarPeriod) -> Int? {
        if superPeriod.period < period ||
           !superPeriod.contains(interval: self) {
            return nil
        }

        var difference: Int
        switch period.scope {
        case .Day:
            let day = CalendarDay(dateInDay: self.start)
            let beginningDay = CalendarDay(dateInDay: superPeriod.start)
            difference = day.daysAfter(startDay: beginningDay)
        case .Week:
            let week = CalendarWeek(dateInWeek: self.start)
            let beginningWeek = CalendarWeek(dateInWeek: superPeriod.start)
            difference = week.weeksAfter(startWeek: beginningWeek)
        case .Month:
            let month = CalendarMonth(dateInMonth: self.start)
            let beginningMonth = CalendarMonth(dateInMonth: superPeriod.start)
            difference = month.monthsAfter(startMonth: beginningMonth)
        default:
            return nil
        }

        return difference / self.period.multiplier
    }
    
    func nextCalendarPeriod() -> CalendarPeriod? {
        if isPartialPeriod {
            return nil
        }
        
        return CalendarPeriod(
            calendarDate: end!,
            period: period,
            beginningDateOfPeriod: start,
            boundingStartDate: nil,
            boundingEndDate: nil
        )!
    }
    
    func previousCalendarPeriod() -> CalendarPeriod? {
        if isPartialPeriod {
            return nil
        }

        return CalendarPeriod(
            calendarDate: previousStart!,
            period: period,
            beginningDateOfPeriod: start,
            boundingStartDate: nil,
            boundingEndDate: nil
        )!
    }

    func lengthInDays() -> Int {
        let firstDay = CalendarDay(dateInDay: start)
        let lastDay = CalendarDay(dateInDay: end!)

        return lastDay.daysAfter(startDay: firstDay)
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
        return intervalContains(container: self, containee: interval)
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
        } else if self.end == nil || interval.start.gmtDate < self.end!.gmtDate {
            return CalendarInterval(start: interval.start, end: self.end)
        } else {
            return nil
        }
    }

    func equals(interval: CalendarIntervalProvider) -> Bool {
        return self.start.gmtDate == interval.start.gmtDate && self.end?.gmtDate == interval.end?.gmtDate
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

    func adverbString() -> String {
        switch self {
        case .None:
            return "None"
        case .Day:
            return "Daily"
        case .Week:
            return "Weekly"
        case .Month:
            return "Monthly"
        }
    }

    func pluralString() -> String {
        switch self {
        case .None:
            return "None"
        case .Day:
            return "Days"
        case .Week:
            return "Weeks"
        case .Month:
            return "Months"
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
