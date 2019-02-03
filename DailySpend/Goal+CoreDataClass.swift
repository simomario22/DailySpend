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

@objc(Goal)
class Goal: NSManagedObject {
    enum CreateFromJsonStatus {
        case Success(Goal)
        case Failure
        case NeedsOtherGoalsToBeCreatedFirst
    }
    
    func json(jsonIds: [NSManagedObjectID: Int]) -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        jsonObj["carryOverBalance"] = carryOverBalance

        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Goal")
            return nil
        }
        
        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Goal")
            return nil
        }
        
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
    
    class func create(
        context: NSManagedObjectContext,
        json: [String: Any],
        jsonIds: [Int: NSManagedObjectID]
    ) -> CreateFromJsonStatus {
        let goal = Goal(context: context)

        if let carryOverBalance = json["carryOverBalance"] as? NSNumber {
            goal.carryOverBalance = carryOverBalance.boolValue
        } else {
            Logger.debug("couldn't unwrap carryOverBalance in Goal")
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
    
    /**
     * A representation of a goal along with that goal's depth in the
     * hierarchy.
     */
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
    class func getIndentedGoals(context: NSManagedObjectContext, excludeGoal: (Goal) -> Bool) -> [IndentedGoal] {
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
    class func getIndentedGoals(context: NSManagedObjectContext, excludedGoals: Set<Goal>? = nil) -> [IndentedGoal] {
        return getIndentedGoals(context: context, excludeGoal: { (goal) -> Bool in
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
     *            that are in the excludedGoals set
     */
    private class func makeIndentedGoals(children: [Goal]?, indentation: Int, excluded: (Goal) -> Bool) -> [IndentedGoal] {
        return children?.flatMap({ childGoal -> [IndentedGoal] in
            let children = makeIndentedGoals(
                children: childGoal.sortedChildGoals,
                indentation: indentation + 1,
                excluded: excluded
            )

            if excluded(childGoal) {
                return children
            } else {
                return [IndentedGoal(childGoal, indentation)] + children
            }
        }) ?? []
    }
    
    /**
     * Returns true if this goal is a parent (possibly by multiple levels)
     * of the passed goal.
     */
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
        parentGoal: Goal?? = nil,
        carryOverBalance: Bool? = nil,
        dateCreated: Date?? = nil
    ) -> (valid: Bool, problem: String?) {
        let _shortDescription = shortDescription ?? self.shortDescription
        let _parentGoal = parentGoal ?? self.parentGoal
        let _carryOverBalance = carryOverBalance ?? self.carryOverBalance
        let _dateCreated = dateCreated ?? self.dateCreated

        if _shortDescription == nil || _shortDescription!.count == 0 {
            return (false, "This goal must have a description.")
        }

        if paySchedules == nil || paySchedules!.isEmpty {
            return (false, "This goal must have at least one pay schedule.")
        }

        var previousEnd: CalendarDateProvider? = sortedPaySchedules!.first!.exclusiveEnd
        let count = sortedPaySchedules!.count
        for (i, schedule) in sortedPaySchedules!.enumerated() {
            if schedule.start == nil {
                return (false, "This goal's schedules all must have a start date.")
            }

            if i == 0 {
                continue
            }

            if previousEnd == nil {
                if i != count - 1 {
                    // This is not the last pay schedule but it doesn't have an end date.
                    return (false, "This goal's pay schedules must not overlap.")
                }
            } else if previousEnd!.gmtDate < schedule.start!.gmtDate {
                return (false, "This goal's must not have any gaps between pay schedules.")
            } else if previousEnd!.gmtDate > schedule.start!.gmtDate {
                return (false, "This goal's pay schedules must not overlap.")
            }

            previousEnd = schedule.exclusiveEnd
        }

        let interval = CalendarInterval(start: self.firstPaySchedule()!.start!, end: self.lastPaySchedule()!.end)!

        if let parent = _parentGoal {
            if parent == self {
                return (false, "This goal cannot be a parent of itself.")
            }

            if self.childGoals?.contains(parent) ?? false {
                return (false, "This goal's parent cannot be its child.")
            }


            let parentInterval = CalendarInterval(start: parent.firstPaySchedule()!.start!, end: parent.lastPaySchedule()!.end)!
            if !parentInterval.contains(interval: interval) {
                return (false, "This goal's start and end date must be within it's parent's start and end date.")
            }
        }
        
        if let children = self.childGoals {
            for child in children {
                let childInterval = CalendarInterval(start: child.firstPaySchedule()!.start!, end: child.lastPaySchedule()!.end)!
                if !interval.contains(interval: childInterval) {
                    return (false, "All of the start and end dates for this goal's children must be within this goal's start and end date.")
                }

            }
        }

        if _dateCreated == nil {
            return (false, "The goal must have a date created.")
        }
        
        self.shortDescription = _shortDescription
        self.parentGoal = _parentGoal
        self.carryOverBalance = _carryOverBalance
        self.dateCreated = _dateCreated
        
        return (true, nil)
    }

    /**
     * Returns the expenses in a particular period, or all the expenses if this
     * is not a recurring goal, from most recent transaction to least recent
     * transaction, or if the transaction day is the same, from most recently
     * created to least recently.
     *
     * - Parameters:
     *    - interval: The `CalendarInterval` for which to fetch expenses.
     */
    func getExpenses(context: NSManagedObjectContext, interval: CalendarIntervalProvider) -> [Expense] {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        
        let descendants = allChildDescendants()
        var fs = "(goal_ = %@ OR goal_ IN %@) AND transactionDate_ >= %@"
        if let end = interval.end {
            fs += " AND transactionDate_ < %@"
            fetchRequest.predicate = NSPredicate(format: fs, self, descendants ?? [], interval.start.gmtDate as CVarArg, end.gmtDate as CVarArg)
        } else {
            fetchRequest.predicate = NSPredicate(format: fs, self, descendants ?? [], interval.start.gmtDate as CVarArg)
        }
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "transactionDate_", ascending: false),
            NSSortDescriptor(key: "dateCreated_", ascending: false)
        ]
        
        let expenseResults = try! context.fetch(fetchRequest)
        
        return expenseResults
    }
    
    /**
     * Returns the adjustments overlapping with a particular period, or all the
     * adjustments if this is not a recurring goal, from most recent begin day
     * to least recent begin day, or if the begin day is the same, from most
     * recently created to least recently.
     *
     * - Parameters:
     *    - interval: The `CalendarInterval` for which to fetch overlapping
     *              adjustments.
     */
    func getAdjustments(context: NSManagedObjectContext, interval: CalendarIntervalProvider, includeCarryOver: Bool = true) -> [Adjustment] {
        let descendants = allChildDescendants()

        let isValidCarryOver = Adjustment.AdjustmentType.isValidCarryOverAdjustmentPredicateString()
        let isNotCarryOver = "(NOT " + Adjustment.AdjustmentType.isCarryOverAdjustmentPredicateString() + ")"

        let isGoalOrDecendant = "(goal_ = $goal OR goal_ IN $goalDescendants)"
        let isGoal = "(goal_ = $goal)"
        let isInInterval = "(lastDateEffective_ >= $intervalStart" + (interval.end == nil ? ")" : " AND firstDateEffective_ < $intervalEnd)")
        var formatString = "(\(isNotCarryOver) AND \(isGoalOrDecendant) AND \(isInInterval))"
        if includeCarryOver {
            formatString += " OR (\(isValidCarryOver) AND \(isGoal) AND \(isInInterval))"
        }

        let predicateTemplate = NSPredicate(format: formatString)
        let predicate = predicateTemplate.withSubstitutionVariables([
            "goal": self,
            "goalDescendants": descendants ?? Set<Goal>(),
            "intervalStart": interval.start.gmtDate,
            "intervalEnd": interval.end?.gmtDate ?? Date()
        ])

        let adjustmentResults = Adjustment.get(
            context: context,
            predicate: predicate,
            sortDescriptors: [
                NSSortDescriptor(key: "firstDateEffective_", ascending: false),
                NSSortDescriptor(key: "dateCreated_", ascending: false)
            ]
        ) ?? []

        return adjustmentResults
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
        guard let schedule = activePaySchedule(on: date) else {
            return nil
        }
        return schedule.incrementalPaymentInterval(for: date)
    }

    /**
     * Returns the period that `date` is in for this goal, or nil if start is
     * not set or date is not in any of this goal's periods.
     */
    func periodInterval(for date: CalendarDateProvider) -> CalendarIntervalProvider? {
        guard let schedule = activePaySchedule(on: date) else {
            return nil
        }
        return schedule.periodInterval(for: date)
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
        guard let schedule = activePaySchedule(on: day.start) else {
            return nil
        }
        return schedule.calculateTotalPaidAmount(for: day)
    }


    /**
     * Returns an initial period for a goal based on when it starts relative to
     * today.
     *
     * If the goal ends before today, it will return the final period.
     * If the goal is active today, it will return the current period.
     * If the goal begins after today, it will return the first period.
     * If this goal has no pay schedules, it will return `nil`.
     */
    func getInitialPeriod(style: GoalPeriod.PeriodStyle) -> GoalPeriod? {
        if self.isArchived {
            guard let schedule = lastPaySchedule() else {
                return nil
            }
            // Safe to unwrap `schedule.end` because if a goal is archived it
            // must have an end.
            return GoalPeriod(goal: self, date: schedule.end!, style: style)
        } else if self.hasFutureStart {
            guard let schedule = firstPaySchedule() else {
                return nil
            }
            return GoalPeriod(goal: self, date: schedule.start!, style: style)
        } else {
            return GoalPeriod(goal: self, date: CalendarDay().start, style: style)
        }
    }

    /**
     * Returns the active pay schedule for a goal on a given day, or `nil` if
     * none exists or the goal is not associated with a valid managed object
     * context.
     *
     * - Parameters:
     *    - date: The `GMTDate` on which to search for active pay schedules.
     */
    func activePaySchedule(on date: CalendarDateProvider) -> PaySchedule? {
        guard let context = self.managedObjectContext else {
            Logger.debug("Goal not associated with a managed object context.")
            return nil
        }

        var schedule: PaySchedule?
        context.performAndWait {
            let formatString = "$goal = goal_ AND $date >= start_ AND (end_ == nil OR $date <= end_)"
            let predicateTemplate = NSPredicate(format: formatString)
            let predicate = predicateTemplate.withSubstitutionVariables([
                "goal": self,
                "date": date.gmtDate
            ])
            let results = PaySchedule.get(context: context, predicate: predicate)
            if results?.count != 1 {
                return
            }
            schedule = results!.first
        }

        return schedule
    }

    /**
     * Returns the first pay schedule result after applying the sort descriptor
     * passed.
     */
    private func getOnePaySchedule(key: String, ascending: Bool) -> PaySchedule? {
        guard let context = self.managedObjectContext else {
            Logger.debug("Goal not associated with a managed object context.")
            return nil
        }

        var schedule: PaySchedule?
        context.performAndWait {
            let formatString = "$goal = goal_"
            let predicateTemplate = NSPredicate(format: formatString)
            let predicate = predicateTemplate.withSubstitutionVariables([
                "goal": self,
                ])
            let sortDescriptors = [NSSortDescriptor(key: key, ascending: ascending)]
            let results = PaySchedule.get(
                context: context,
                predicate: predicate,
                sortDescriptors: sortDescriptors,
                fetchLimit: 1
            )

            schedule = results?.first
        }
        return schedule
    }

    /**
     * Returns the first pay schedule for this goal, if one exists.
     */
    func firstPaySchedule() -> PaySchedule? {
        return getOnePaySchedule(key: "start_", ascending: true)
    }

    /**
     * Returns the last pay schedule for this goal, if one exists.
     */
    func lastPaySchedule() -> PaySchedule? {
        return getOnePaySchedule(key: "start_", ascending: false)
    }

    var isArchived: Bool {
        let end = lastPaySchedule()?.exclusiveEnd
        return end != nil && CalendarDay(dateInDay: end!) <= CalendarDay() || (parentGoal?.isArchived ?? false)
    }
    
    var hasFutureStart: Bool {
        let start = firstPaySchedule()?.start
        return start == nil || CalendarDay(dateInDay: start!) > CalendarDay()
    }
    
    var carryOverBalance: Bool {
        get {
            return carryOverBalance_
        }
        set {
            carryOverBalance_ = newValue
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

    var sortedPaySchedules: [PaySchedule]? {
        if let s = paySchedules {
            return s.sorted(by: { $0.start!.gmtDate < $1.start!.gmtDate })
        } else {
            return nil
        }
    }

    var paySchedules: Set<PaySchedule>? {
        get {
            return paySchedules_ as! Set?
        }
        set {
            if newValue != nil {
                paySchedules_ = NSSet(set: newValue!)
            } else {
                paySchedules_ = nil
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
