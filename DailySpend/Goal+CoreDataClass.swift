//
//  Goal+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/26/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData

enum CreateGoalFromJsonStatus {
    case Success(Goal)
    case Failure
    case NeedsOtherGoalsToBeCreatedFirst
}

@objc(Goal)
class Goal: NSManagedObject {
    
    func json(jsonIds: [NSManagedObjectID: Int]) -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let amount = amount {
            let num = amount as NSNumber
            jsonObj["amount"] = num
        } else {
            Logger.debug("couldn't unwrap amount in Goal")
            return nil
        }

        jsonObj["alwaysCarryOver"] = alwaysCarryOver

        jsonObj["adjustMonthAmountAutomatically"] = adjustMonthAmountAutomatically

        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Goal")
            return nil
        }
        
        if let date = start {
            let num = date.gmtDate.timeIntervalSince1970 as NSNumber
            jsonObj["start"] = num
        } else {
            Logger.debug("couldn't unwrap start in Goal")
            return nil
        }
        
        if let date = end {
            let num = date.gmtDate.timeIntervalSince1970 as NSNumber
            jsonObj["end"] = num
        }
        
        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Goal")
            return nil
        }
        
        jsonObj["period"] = period.scope.rawValue as NSNumber
        jsonObj["periodMultiplier"] = period.multiplier as NSNumber
        
        jsonObj["payFrequency"] = payFrequency.scope.rawValue as NSNumber
        jsonObj["payFrequencyMultiplier"] = payFrequency.multiplier as NSNumber

        if let parentGoal = parentGoal {
            jsonObj["parentGoal"] = jsonIds[parentGoal.objectID]
        }
        
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
    
    class func create(context: NSManagedObjectContext,
                      json: [String: Any],
                      jsonIds: [Int: NSManagedObjectID]) -> CreateGoalFromJsonStatus {
        let goal = Goal(context: context)
        
        if let amount = json["amount"] as? NSNumber {
            let decimal = Decimal(amount.doubleValue)
            if decimal == 0 {
                Logger.debug("amount equal to 0 in Goal")
                return .Failure
            }
            goal.amount = decimal
        } else {
            Logger.debug("couldn't unwrap amount in Goal")
            return .Failure
        }
        
        if let alwaysCarryOver = json["alwaysCarryOver"] as? NSNumber {
            goal.alwaysCarryOver = alwaysCarryOver.boolValue
        } else {
            Logger.debug("couldn't unwrap alwaysCarryOver in Goal")
            return .Failure
        }
        
        if let adjustMonthAmountAutomatically = json["adjustMonthAmountAutomatically"] as? NSNumber {
            goal.adjustMonthAmountAutomatically = adjustMonthAmountAutomatically.boolValue
        } else {
            Logger.debug("couldn't unwrap adjustMonthAmountAutomatically in Goal")
            return .Failure
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Goal")
                return .Failure
            }
            goal.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in Goal")
            return .Failure
        }
        
        if let periodNumber = json["period"] as? NSNumber,
            let periodMultiplierNumber = json["periodMultiplier"] as? NSNumber {
            let p = PeriodScope(rawValue: periodNumber.intValue)
            let m = periodMultiplierNumber.intValue
            if p != nil && m >= 0 {
                goal.period = Period(scope: p!, multiplier: m)
            } else {
                Logger.debug("period or its multiplier wasn't a valid number in Goal")
                return .Failure
            }
        } else {
            Logger.debug("couldn't unwrap period or its multiplier in Goal")
            return .Failure
        }
        
        if let dateNumber = json["start"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            if !Goal.scopeConformsToDate(date, scope: goal.period.scope) {
                // The date isn't a beginning of a period
                Logger.debug("The start date isn't at the beginning of the period")
                return .Failure
            }
            goal.start = GMTDate(date)
        } else {
            Logger.debug("couldn't unwrap start in Goal")
            return .Failure
        }
        
        if let dateNumber = json["end"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            if !Goal.scopeConformsToDate(date, scope: goal.period.scope) ||
                date < goal.start!.gmtDate {
                // The date isn't a beginning of day
                Logger.debug("The start date isn't at the beginning of the period or is earlier than start in Goal")
                return .Failure
            }
            goal.end = GMTDate(date)
        } else {
            goal.end = nil
        }
        
        if let shortDescription = json["shortDescription"] as? String {
            if shortDescription.count == 0 {
                Logger.debug("shortDescription empty in Goal")
                return .Failure
            }
            goal.shortDescription = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Goal")
            return .Failure
        }
        
        if let payFrequencyNumber = json["payFrequency"] as? NSNumber,
           let payFrequencyMultiplierNumber = json["payFrequencyMultiplier"] as? NSNumber {
            let p = PeriodScope(rawValue: payFrequencyNumber.intValue)
            let m = payFrequencyMultiplierNumber.intValue
            if p != nil && m >= 0 {
                goal.payFrequency = Period(scope: p!, multiplier: m)
            } else {
                Logger.debug("payFrequency or its multiplier wasn't a valid number in Goal")
                return .Failure
            }
        } else {
            Logger.debug("couldn't unwrap payFrequency or its multiplier in Goal")
            return .Failure
        }
        
        if let parentGoalJsonId = json["parentGoal"] as? NSNumber {
            if let objectID = jsonIds[parentGoalJsonId.intValue],
                let parentGoal = context.object(with: objectID) as? Goal {
                goal.parentGoal = parentGoal
            } else {
                return .NeedsOtherGoalsToBeCreatedFirst
            }
        }

        return .Success(goal)
    }
    
    class func get(context: NSManagedObjectContext,
                   predicate: NSPredicate? = nil,
                   sortDescriptors: [NSSortDescriptor]? = nil,
                   fetchLimit: Int = 0) -> [Goal]? {
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        
        let goalResults = try? context.fetch(fetchRequest)
        
        return goalResults
    }
    
    /**
     * Returns `true` if `date` is at the start of a gmt `scope` (e.g. day,
     * week, month); `false` otherwise.
     */
    private class func scopeConformsToDate(_ date: Date, scope: PeriodScope) -> Bool {
        if scope == .None {
            return PeriodScope.Day.scopeConformsToDate(date)
        } else {
            return scope.scopeConformsToDate(date)
        }
    }
    
    
    struct IndentedGoal {
        var goal: Goal
        var indentation: Int
        init(_ goal: Goal, _ indentation: Int) {
            self.goal = goal
            self.indentation = indentation
        }
    }
    
    /**
     * Returns all goals in a hierarchical fashion, wrapped in `IndentedGoal`
     * structs. Goals are sorted within the hierarchy by `shortDescription`.
     * - Parameters:
     *    - excludeGoal: a function that returns true if the goal and its
     *                   children are to be excluded from the indented goals.
     */
    class func getIndentedGoals(excludeGoal: (Goal) -> Bool) -> [IndentedGoal] {
        guard let topLevelGoals = Goal.get(
            context: context,
            predicate: NSPredicate(format: "parentGoal_ == nil"),
            sortDescriptors: [NSSortDescriptor(key: "shortDescription_", ascending: true)]
            ) else {
                return []
        }
        
        return makeIndentedGoals(children: topLevelGoals, indentation: 0, excluded: excludeGoal)
    }
    
    /**
     * Returns all goals in a hierarchical fashion, wrapped in `IndentedGoal`
     * structs. Goals are sorted within the hierarchy by `shortDescription`.
     * - Parameters:
     *    - excludedGoals: goals to exclude from the hierarchy, along with
     *                     their children.
     */
    class func getIndentedGoals(excludedGoals: Set<Goal>?) -> [IndentedGoal] {
        return getIndentedGoals(excludeGoal: { (goal) -> Bool in
            return excludedGoals?.contains(goal) ?? false
        })
    }
    
    /**
     * Recurses into goals to create a set of goals with proper
     * indentation levels, based on their place in the hierarchy.
     * - Parameters:
     *    - children: Child goals to be made into indented goals
     *    - indentation: The level of indentation fo assign to each passed child
     * - Returns: An array of sorted goals and their children, excluding goals
     that are in the excludedGoals set
     */
    private class func makeIndentedGoals(children: [Goal]?, indentation: Int, excluded: (Goal) -> Bool) -> [IndentedGoal] {
        return children?.flatMap({ childGoal -> [IndentedGoal] in
            if excluded(childGoal) {
                return []
            }
            let children = makeIndentedGoals(
                children: childGoal.sortedChildGoals,
                indentation: indentation + 1,
                excluded: excluded
            )
            return [IndentedGoal(childGoal, indentation)] + children
        }) ?? []
    }
    
    func isParentOf(goal: Goal) -> Bool {
        var parent = goal.parentGoal
        while parent != nil {
            if parent == self {
                return true
            }
            parent = parent!.parentGoal
        }
        return false
    }
    
    /**
     * Accepts all members of Goal. If the passed variables, attached to
     * corresponding variables on an Goal object, will form a valid
     * object, this function will assign the passed variables to this object
     * and return `(valid: true, problem: nil)`. Otherwise, this function will
     * return `(valid: false, problem: ...)` with problem set to a user
     * readable string describing why this adjustment wouldn't be valid.
     */
    func propose(
        shortDescription: String?? = nil,
        amount: Decimal?? = nil,
        start: CalendarDateProvider?? = nil,
        end: CalendarDateProvider?? = nil,
        period: Period? = nil,
        payFrequency: Period? = nil,
        parentGoal: Goal?? = nil,
        alwaysCarryOver: Bool? = nil,
        adjustMonthAmountAutomatically: Bool? = nil,
        dateCreated: Date?? = nil
    ) -> (valid: Bool, problem: String?) {
        let _amount = amount ?? self.amount
        let _shortDescription = shortDescription ?? self.shortDescription
        let _start = start ?? self.start
        let _end = end ?? self.end
        let _period = period ?? self.period
        let _payFrequency = payFrequency ?? self.payFrequency
        let _parentGoal = parentGoal ?? self.parentGoal
        let _alwaysCarryOver = alwaysCarryOver ?? self.alwaysCarryOver
        let _adjustMonthAmountAutomatically = adjustMonthAmountAutomatically ?? self.adjustMonthAmountAutomatically
        let _dateCreated = dateCreated ?? self.dateCreated

        if _shortDescription == nil || _shortDescription!.count == 0 {
            return (false, "This goal must have a description.")
        }
        
        if _amount == nil || _amount! == 0 {
            return (false, "This goal must have an amount specified.")
        }
        
        if _start == nil || !Goal.scopeConformsToDate(_start!.gmtDate, scope: _period.scope) {
            return (false, "The goal must have a start date at the beginning of it's period.")
        }
        
        
        if _end != nil {
            if !Goal.scopeConformsToDate(_end!.gmtDate, scope: _period.scope) {
                return (false, "If this goal has an end date, it must be at the start of a period.")
            }
            
            if _end!.gmtDate < _start!.gmtDate {
                return (false, "If this goal has an end date, it must be on or after the start date.")
            }
        }
        
        if _period.scope != .None && _payFrequency > _period {
            return (false, "The pay freqency must have a lesser or equal interval than that of the period.")
        }
        
        if _parentGoal == self {
            return (false, "A goal cannot be a parent of itself.")
        }
        
        if _dateCreated == nil {
            return (false, "The goal must have a date created.")
        }
        
        self.amount = _amount
        self.shortDescription = _shortDescription
        self.start = _start
        self.end = _end
        self.period = _period
        self.payFrequency = _payFrequency
        self.parentGoal = _parentGoal
        self.alwaysCarryOver = _alwaysCarryOver
        self.adjustMonthAmountAutomatically = _adjustMonthAmountAutomatically
        self.dateCreated = _dateCreated
        
        return (true, nil)
    }
    
    /**
     * Compute the balance amount in this goal on a particular day.
     *
     * - Parameters:
     *    - day: The day to compute the balance for.
     *
     * - Returns: The balance on `day`, taking into account periods,
     *            interval pay, and expenses.
     */
     func balance(for day: CalendarDay) -> Decimal {
        guard let expenseInterval = periodInterval(for: day.start),
              let amount = adjustedAmountForDateInPeriod(day.start) else {
            return 0
        }
        let totalExpenseAmount = getExpenses(interval: expenseInterval)
            .reduce(0, {(amount, expense) -> Decimal in
            return amount + (expense.amount ?? 0)
        })

        var totalPaidAmount: Decimal = 0
        if hasIncrementalPayment {
            guard let expensePeriod = expenseInterval as? CalendarPeriod else {
                return 0
            }
            let paymentsPerPeriod = expensePeriod.numberOfSubPeriodsOfLength(period: self.payFrequency)
            if paymentsPerPeriod == 0 {
                return 0
            }
            let incrementalAmount = amount / Decimal(paymentsPerPeriod)
            guard let incrementInterval = incrementalPaymentInterval(for: day.start) as? CalendarPeriod,
                  let index = incrementInterval.periodIndexWithin(superPeriod: expensePeriod) else {
                return 0
            }
            
            totalPaidAmount = incrementalAmount * Decimal(index + 1)
        } else {
            totalPaidAmount = amount
        }
        
        return totalPaidAmount - totalExpenseAmount
    }
    
    /**
     * The amount per period, adjusted for the days in the current month or
     * months for this period, if necessary.
     */
    func adjustedAmountForDateInPeriod(_ date: CalendarDateProvider) -> Decimal? {
        guard let amount = amount else {
            return nil
        }
        if adjustMonthAmountAutomatically && period.scope == .Month {
            var totalDays = 0
            guard let interval = periodInterval(for: date) else {
                return nil
            }
            // Start with the first month in the interval.
            var month = CalendarMonth(interval: interval)
            for _ in 0..<period.multiplier {
                totalDays += month.daysInMonth
                month = month.add(months: 1)
            }
            
            let perDayAmount = amount / 30
            return Decimal(totalDays) * perDayAmount
        } else {
            return amount
        }
    }
    
    /**
     * Returns the expenses in a particular period, or all the expenses if this
     * is not a recurring goal, from most recently created to least recently.
     *
     * - Parameters:
     *    - period: The `CalendarInterval` for which to fetch expenses.
     *              If period is nil, will return all expenses for the goal.
     */
    func getExpenses(interval: CalendarIntervalProvider) -> [Expense] {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        
        let descendants = allChildDescendants()
        var fs = "(goal_ = %@ OR goal_ IN %@) AND transactionDate_ >= %@"
        if let end = interval.end {
            fs += " AND transactionDate_ < %@"
            fetchRequest.predicate = NSPredicate(format: fs, self, descendants ?? [], interval.start.gmtDate as CVarArg, end.gmtDate as CVarArg)
        } else {
            fetchRequest.predicate = NSPredicate(format: fs, self, self.childGoals ?? [], interval.start.gmtDate as CVarArg)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated_", ascending: false)]
        
        let expenseResults = try! context.fetch(fetchRequest)
        
        return expenseResults
    }
    
    /**
     * Returns a set containg all of this goal's decendents:
     * This goal's children, their children, etc.
     */
    func allChildDescendants() -> Set<Goal>? {
        guard let childGoals = childGoals else {
            return nil
        }
        
        var descendants = Set<Goal>(childGoals)
        for goal in childGoals {
            if let childGoalDescendants = goal.allChildDescendants() {
                descendants = descendants.union(childGoalDescendants)
            }
        }
        
        return descendants
    }

    /**
     * Returns the period starting when the most recent incremental payment
     * prior to `date` was made, and ending when the following incremental
     * payment will be made.
     *
     * If there is no incremental payment set for this goal, the current period
     * interval is returned instead.
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
            beginningDateOfPeriod: period.start
        )
    }

    /**
     * Returns the current period of this goal, or nil if start is not set.
     */
    func periodInterval(for date: CalendarDateProvider) -> CalendarIntervalProvider? {
        guard let start = self.start else {
            return nil
        }
        
        if !isRecurring {
            return CalendarInterval(start: start, end: self.exclusiveEnd)
        }
        
        return CalendarPeriod(
            calendarDate: date,
            period: period,
            beginningDateOfPeriod: self.start!
        )
    }

    var hasIncrementalPayment: Bool {
        return self.payFrequency.scope != .None
    }
    
    var isRecurring: Bool {
        return self.period.scope != .None
    }
    
    var archived: Bool {
        return end != nil && CalendarDay(dateInDay: end!) > CalendarDay()
    }
    
    var alwaysCarryOver: Bool {
        get {
            return alwaysCarryOver_
        }
        set {
            alwaysCarryOver_ = newValue
        }
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
        let period = CalendarPeriod(
            calendarDate: end,
            period: self.period,
            beginningDateOfPeriod: end
        )
        return period?.end
    }
    
    var amount: Decimal? {
        get {
            return amount_ as Decimal?
        }
        set {
            if newValue != nil {
                amount_ = NSDecimalNumber(decimal: newValue!)
            } else {
                amount_ = nil
            }
        }
    }
    
    var shortDescription: String? {
        get {
            return shortDescription_
        }
        set {
            shortDescription_ = newValue
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
    
    /**
     * `expenses` sorted in a deterministic way.
     */
    var sortedExpenses: [Expense]? {
        if let e = expenses {
            return e.sorted(by: { $0.transactionDay! < $1.transactionDay! })
        } else {
            return nil
        }
    }
    
    var expenses: Set<Expense>? {
        get {
            return expenses_ as! Set?
        }
        set {
            if newValue != nil {
                expenses_ = NSSet(set: newValue!)
            } else {
                expenses_ = nil
            }
        }
    }
    
    var sortedAdjustments: [Adjustment]? {
        if let a = adjustments {
            return a.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    var adjustments: Set<Adjustment>? {
        get {
            return adjustments_ as! Set?
        }
        set {
            if newValue != nil {
                adjustments_ = NSSet(set: newValue!)
            } else {
                adjustments_ = nil
            }
        }
    }
    
    var sortedPauses: [Pause]? {
        if let p = pauses {
            return p.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    var pauses: Set<Pause>? {
        get {
            return pauses_ as! Set?
        }
        set {
            if newValue != nil {
                pauses_ = NSSet(set: newValue!)
            } else {
                pauses_ = nil
            }
        }
    }
    
    var parentGoal: Goal? {
        get {
            return parentGoal_
        }
        set {
            if newValue != nil {
                parentGoal_ = newValue
            } else {
                parentGoal_ = nil
            }
        }
    }
    
    var sortedChildGoals: [Goal]? {
        if let g = childGoals {
            return g.sorted(by: { $0.shortDescription! < $1.shortDescription! })
        } else {
            return nil
        }
    }
    
    var childGoals: Set<Goal>? {
        get {
            return childGoals_ as! Set?
        }
        set {
            if newValue != nil {
                childGoals_ = NSSet(set: newValue!)
            } else {
                childGoals_ = nil
            }
        }
    }
}
