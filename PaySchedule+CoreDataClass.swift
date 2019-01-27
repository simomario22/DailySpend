//
//  PaySchedule+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/19/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData

@objc(PaySchedule)
class PaySchedule: NSManagedObject {

    func json(jsonIds: [NSManagedObjectID: Int]) -> [String: Any]? {
        var jsonObj = [String: Any]()

        if let amount = amount {
            let num = amount as NSNumber
            jsonObj["amount"] = num
        } else {
            Logger.debug("couldn't unwrap amount in PaySchedule")
            return nil
        }

        jsonObj["adjustMonthAmountAutomatically"] = adjustMonthAmountAutomatically

        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in PaySchedule")
            return nil
        }

        if let date = start {
            let num = date.gmtDate.timeIntervalSince1970 as NSNumber
            jsonObj["start"] = num
        } else {
            Logger.debug("couldn't unwrap start in PaySchedule")
            return nil
        }

        if let date = end {
            let num = date.gmtDate.timeIntervalSince1970 as NSNumber
            jsonObj["end"] = num
        }

        jsonObj["period"] = period.scope.rawValue as NSNumber
        jsonObj["periodMultiplier"] = period.multiplier as NSNumber

        jsonObj["payFrequency"] = payFrequency.scope.rawValue as NSNumber
        jsonObj["payFrequencyMultiplier"] = payFrequency.multiplier as NSNumber

        jsonObj["jsonId"] = jsonIds[objectID]

        return jsonObj
    }

    func serialize(jsonIds: [NSManagedObjectID: Int]) -> Data? {
        if let jsonObj = self.json(jsonIds: jsonIds) {
            let serialization = try? JSONSerialization.data(withJSONObject: jsonObj)
            return serialization
        }

        return nil
    }

    class func create(
        context: NSManagedObjectContext,
        json: [String: Any],
        jsonIds: [Int: NSManagedObjectID]
    ) -> (PaySchedule?, Bool) {
        var _amount: Decimal?
        var _adjustMonthAmountAutomatically: Bool?
        var _dateCreated: Date?
        var _period: Period?
        var _payFrequency: Period?
        var _start: GMTDate?
        var _end: GMTDate?

        if let amount = json["amount"] as? NSNumber {
            _amount = Decimal(amount.doubleValue)
        }

        if let adjustMonthAmountAutomatically = json["adjustMonthAmountAutomatically"] as? NSNumber {
            _adjustMonthAmountAutomatically = adjustMonthAmountAutomatically.boolValue
        }

        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            _dateCreated = date
        }

        if let periodNumber = json["period"] as? NSNumber,
            let periodMultiplierNumber = json["periodMultiplier"] as? NSNumber {
            let p = PeriodScope(rawValue: periodNumber.intValue)
            let m = periodMultiplierNumber.intValue
            _period = p != nil ? Period(scope: p!, multiplier: m) : nil
        }

        if let dateNumber = json["start"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            _start = GMTDate(date) // We'll treat this as a GMT date.
        }

        if let dateNumber = json["end"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            _end = GMTDate(date) // We'll treat this as a GMT date.
        }

        if let payFrequencyNumber = json["payFrequency"] as? NSNumber,
            let payFrequencyMultiplierNumber = json["payFrequencyMultiplier"] as? NSNumber {
            let p = PeriodScope(rawValue: payFrequencyNumber.intValue)
            let m = payFrequencyMultiplierNumber.intValue
            _payFrequency = p != nil ? Period(scope: p!, multiplier: m) : nil
        }

        var schedule: PaySchedule!
        context.performAndWait {
            schedule = PaySchedule(context: context)
            let validation = schedule.propose(
                amount: _amount,
                start: _start,
                end: _end,
                period: _period,
                payFrequency: _payFrequency,
                adjustMonthAmountAutomatically: _adjustMonthAmountAutomatically,
                dateCreated: _dateCreated
            )

            if !validation.valid {
                context.rollback()
                Logger.debug(validation.problem!)
            }
        }

        return (schedule, schedule != nil)
    }

    class func get(
        context: NSManagedObjectContext,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int = 0
    ) -> [PaySchedule]? {
        let fetchRequest: NSFetchRequest<PaySchedule> = PaySchedule.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit

        let scheduleResults = try? context.fetch(fetchRequest)

        return scheduleResults
    }

    /**
     * Accepts all members of PaySchedule. If the passed variables, attached to
     * corresponding variables on an PaySchedule object, will form a valid
     * object, this function will assign the passed variables to this object
     * and return `(valid: true, problem: nil)`. Otherwise, this function will
     * return `(valid: false, problem: ...)` with problem set to a user
     * readable string describing why this adjustment wouldn't be valid.
     */
    func propose(
        amount: Decimal?? = nil,
        start: CalendarDateProvider?? = nil,
        end: CalendarDateProvider?? = nil,
        period: Period? = nil,
        payFrequency: Period? = nil,
        adjustMonthAmountAutomatically: Bool? = nil,
        goal: Goal? = nil,
        dateCreated: Date?? = nil
    ) -> (valid: Bool, problem: String?) {
        let _amount = amount ?? self.amount
        let _start = start ?? self.start
        let _end = end ?? self.end
        let _period = period ?? self.period
        let _payFrequency = payFrequency ?? self.payFrequency
        let _adjustMonthAmountAutomatically = adjustMonthAmountAutomatically ?? self.adjustMonthAmountAutomatically
        let _goal = goal ?? self.goal
        let _dateCreated = dateCreated ?? self.dateCreated

        if _goal == nil {
            return (false, "This pay schedule must be associated with a goal.")
        }

        if _amount == nil || _amount! == 0 {
            return (false, "This pay schedule must have an amount greater than 0 specified.")
        }

        if _start == nil || CalendarDay(dateInDay: _start)?.start.gmtDate != _start?.gmtDate {
            return (false, "This pay schedule must have a valid start date.")
        }

        if _end != nil && (CalendarDay(dateInDay: _end)?.start.gmtDate != _end?.gmtDate || _end!.gmtDate < _start!.gmtDate) {
            return (false, "If this pay schedule has an end date, it must be on or after the start date.")
        }

        if _period.scope != .None && _period.multiplier <= 0 ||
            _payFrequency.scope != .None && _payFrequency.multiplier <= 0 {
            return (false, "The period and pay frequency must have a multiplier greater than 0.")
        }

        if _period.scope != .None && _payFrequency > _period {
            return (false, "The pay freqency for this pay schedule must have a lesser or equal interval than that of the period.")
        }

        if _dateCreated == nil {
            return (false, "The pay schedule must have a date created.")
        }

        self.amount = _amount
        self.start = _start
        self.end = _end
        self.period = _period
        self.payFrequency = _payFrequency
        self.adjustMonthAmountAutomatically = _adjustMonthAmountAutomatically
        self.goal = _goal
        self.dateCreated = _dateCreated

        return (true, nil)
    }

    /**
     * Returns the total paid amount on a given day, taking into account
     * intervals, period scope length differences and a pay schedule, if there
     * is one.
     *
     * - Parameters:
     *    - day: The day to compute the total paid amount on.
     */
    func calculateTotalPaidAmount(for day: CalendarDay) -> Decimal? {
        guard let interval = periodInterval(for: day.start),
              let amount = unboundedPayAmountForPeriod(interval) else {
            return nil
        }

        if !isRecurring {
            return amount.roundToNearest(th: 100)
        }

        // Coerce a CalendarPeriod, since this is recurring.
        guard let period = interval as? CalendarPeriod else {
            return nil
        }

        if !hasIncrementalPayment {
            let boundsAdjustedPeriodAmount = getBoundsAdjustedPay(period: period, unboundedAmount: amount)
            // The period may have bounds, so calculate the bounds adjusted
            // amount for the period.
            return boundsAdjustedPeriodAmount.roundToNearest(th: 100)
        }


        guard let incrementPeriod = self.incrementalPaymentInterval(for: day.start) else {
            return nil
        }

        let periodFirstDay = CalendarDay(dateInDay: period.start)
        let incrementLastDay = CalendarDay(dateInDay: incrementPeriod.end)!.subtract(days: 1)
        let lengthInDays = Decimal(incrementLastDay.daysAfter(startDay: periodFirstDay)) + 1

        // The amount to be paid per day.
        let multiplier = Decimal(self.period.multiplier)
        var dailyIncrementalAmount: Decimal = self.amount! / multiplier

        switch self.period.scope {
        case .Week:
            let daysInWeek = Decimal(CalendarWeek.typicalDaysInWeek)
            dailyIncrementalAmount = dailyIncrementalAmount / daysInWeek
        case .Month:
            if !self.adjustMonthAmountAutomatically {
                // Same amount is paid out per day regardless of month length.
                let daysInPeriod = Decimal(period.lengthInDays())
                dailyIncrementalAmount = self.amount! / daysInPeriod
            } else {
                let daysInMonth = Decimal(CalendarMonth.typicalDaysInMonth)
                dailyIncrementalAmount = dailyIncrementalAmount / daysInMonth
            }
        case .None, .Day: break
        }

        let incrementalAmountPaid = lengthInDays * dailyIncrementalAmount
        return incrementalAmountPaid.roundToNearest(th: 100)
    }

    /**
     * Given a CalendarPeriod `period`, bounded or not, and an amount paid for
     * an unbounded period, give the amount to be paid for this period, reducing
     * it proportionally to the reduction in length due to bounding.
     */
    private func getBoundsAdjustedPay(period: CalendarPeriod, unboundedAmount: Decimal) -> Decimal {
        if period.partialPeriodLengthReductionInDays == 0 {
            // This is not a partial period, so don't bother with calculations.
            return unboundedAmount
        }

        let lengthInDays = period.lengthInDays()
        let unboundedLengthInDays = lengthInDays + period.partialPeriodLengthReductionInDays

        let amountPerDay = unboundedAmount / Decimal(unboundedLengthInDays)

        let totalAmount = amountPerDay * Decimal(lengthInDays)
        return totalAmount
    }

    /**
     * The amount per period, adjusted based on the number of days in the
     * month(s) if necessary based on `adjustMonthAmountAutomatically`.
     */
    private func unboundedPayAmountForPeriod(_ interval: CalendarIntervalProvider) -> Decimal? {
        guard let amount = amount else {
            return nil
        }
        if adjustMonthAmountAutomatically && period.scope == .Month {
            var totalDays = 0
            // Start with the first month in the interval.
            var month = CalendarMonth(interval: interval)
            for _ in 0..<period.multiplier {
                totalDays += month.daysInMonth
                month = month.add(months: 1)
            }

            let perDayAmount = amount / Decimal(30 * period.multiplier)
            let adjustedAmount = Decimal(totalDays) * perDayAmount
            return adjustedAmount
        } else {
            return amount
        }
    }

    /**
     * Returns the period starting when the most recent incremental payment
     * prior to `date` was made, and ending when the following incremental
     * payment will be made.
     *
     * If there is no incremental payment set for this schedule, the current
     * period interval is returned instead.
     */
    func incrementalPaymentInterval(for date: CalendarDateProvider) -> CalendarIntervalProvider? {
        guard let period = periodInterval(for: date) else {
            return nil
        }

        if !hasIncrementalPayment {
            return period
        }

        return CalendarPeriod(
            calendarDate: date,
            period: payFrequency,
            beginningDateOfPeriod: period.start,
            boundingStartDate: self.start,
            boundingEndDate: period.end
        )!
    }

    /**
     * Returns the period that `date` is in for this goal, or nil if start is
     * not set or date is not in any of this goal's periods.
     */
    func periodInterval(for date: CalendarDateProvider) -> CalendarIntervalProvider? {
        guard let start = self.start else {
            return nil
        }

        if date.gmtDate < start.gmtDate ||
            (self.exclusiveEnd != nil && date.gmtDate >= self.exclusiveEnd!.gmtDate) {
            return nil
        }

        if !isRecurring {
            return CalendarInterval(start: start, end: self.exclusiveEnd)
        }

        return CalendarPeriod(
            calendarDate: date,
            period: period,
            beginningDateOfPeriod: self.start!,
            boundingStartDate: self.start,
            boundingEndDate: self.exclusiveEnd
        )!
    }

    var hasIncrementalPayment: Bool {
        return self.payFrequency.scope != .None
    }

    var isRecurring: Bool {
        return self.period.scope != .None
    }

    var adjustMonthAmountAutomatically: Bool {
        get {
            return adjustMonthAmountAutomatically_
        }
        set {
            adjustMonthAmountAutomatically_ = newValue
        }
    }

    var period: Period {
        get {
            let p = PeriodScope(rawValue: Int(period_))!
            let m = Int(periodMultiplier_)
            return Period(scope: p, multiplier: m)
        }
        set {
            period_ = Int64(newValue.scope.rawValue)
            periodMultiplier_ = Int64(newValue.multiplier)
        }
    }

    var payFrequency: Period {
        get {
            let p = PeriodScope(rawValue: Int(payFrequency_))!
            let m = Int(payFrequencyMultiplier_)
            return Period(scope: p, multiplier: m)
        }
        set {
            payFrequency_ = Int64(newValue.scope.rawValue)
            payFrequencyMultiplier_ = Int64(newValue.multiplier)
        }
    }

    var start: CalendarDateProvider? {
        get {
            if let day = start_ as Date? {
                return GMTDate(day)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                start_ = newValue!.gmtDate as NSDate
            } else {
                start_ = nil
            }
        }
    }

    /**
     * The first day of the last period included in the goal, or none if nil.
     * Note that this should only be used in user facing situations. For
     * calculations and ranges, use `exclusiveEnd`.
     */
    var end: CalendarDateProvider? {
        get {
            if let day = end_ as Date? {
                return GMTDate(day)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                // Get relevant days.
                end_ = newValue!.gmtDate as NSDate
            } else {
                end_ = nil
            }
        }
    }

    /**
     * Returns the first date after this period has ended.
     */
    var exclusiveEnd: CalendarDateProvider? {
        guard let end = end else {
            return nil
        }
        return CalendarDay(dateInDay: end).end
    }

    var amount: Decimal? {
        get {
            return amount_ as Decimal?
        }
        set {
            if newValue != nil {
                amount_ = NSDecimalNumber(decimal: newValue!.roundToNearest(th: 100))
            } else {
                amount_ = nil
            }
        }
    }

    var dateCreated: Date? {
        get {
            return dateCreated_ as Date?
        }
        set {
            if newValue != nil {
                dateCreated_ = newValue! as NSDate
            } else {
                dateCreated_ = nil
            }
        }
    }

    var goal: Goal? {
        get {
            return goal_
        }

        set {
            goal_ = newValue
        }
    }

}
