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

public enum CreateGoalFromJsonStatus {
    case Success(Goal)
    case Failure
    case NeedsOtherGoalsToBeCreatedFirst
}

@objc(Goal)
public class Goal: NSManagedObject {
    
    public func json(jsonIds: [NSManagedObjectID: Int]) -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let amount = amount {
            let num = amount as NSNumber
            jsonObj["amount"] = num
        } else {
            Logger.debug("couldn't unwrap amount in Goal")
            return nil
        }
        
        jsonObj["archived"] = archived
        
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
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["start"] = num
        } else {
            Logger.debug("couldn't unwrap start in Goal")
            return nil
        }
        
        if let date = end {
            let num = date.timeIntervalSince1970 as NSNumber
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
    
    public func serialize(jsonIds: [NSManagedObjectID: Int]) -> Data? {
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
        
        if let archived = json["archived"] as? NSNumber {
            goal.archived = archived.boolValue
        } else {
            Logger.debug("couldn't unwrap archived in Goal")
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
            goal.start = date
        } else {
            Logger.debug("couldn't unwrap start in Goal")
            return .Failure
        }
        
        if let dateNumber = json["end"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            if !Goal.scopeConformsToDate(date, scope: goal.period.scope) ||
                date < goal.start! {
                // The date isn't a beginning of day
                Logger.debug("The start date isn't at the beginning of the period or is earlier than start in Goal")
                return .Failure
            }
            goal.end = date
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
    
    private class func scopeConformsToDate(_ date: Date, scope: PeriodScope) -> Bool {
        if scope == .None {
            return PeriodScope.Day.scopeConformsToDate(date)
        } else {
            return scope.scopeConformsToDate(date)
        }
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
        start: Date?? = nil,
        end: Date?? = nil,
        period: Period? = nil,
        payFrequency: Period? = nil,
        parentGoal: Goal?? = nil,
        archived: Bool? = nil,
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
        let _archived = archived ?? self.archived
        let _alwaysCarryOver = alwaysCarryOver ?? self.alwaysCarryOver
        let _adjustMonthAmountAutomatically = adjustMonthAmountAutomatically ?? self.adjustMonthAmountAutomatically
        let _dateCreated = dateCreated ?? self.dateCreated

        if _shortDescription == nil || _shortDescription!.count == 0 {
            return (false, "This goal must have a description.")
        }
        
        if _amount == nil || _amount! == 0 {
            return (false, "This goal must have an amount specified.")
        }
        
        if _start == nil || !Goal.scopeConformsToDate(_start!, scope: _period.scope) {
            return (false, "The goal must have a start date at the beginning of it's period.")
        }
        
        
        if _end != nil {
            if !Goal.scopeConformsToDate(_end!, scope: _period.scope) {
                return (false, "If this goal has an end date, it must be at the start of a period.")
            }
            
            if _end! < _start! {
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
        self.archived = _archived
        self.alwaysCarryOver = _alwaysCarryOver
        self.adjustMonthAmountAutomatically = _adjustMonthAmountAutomatically
        self.dateCreated = _dateCreated
        
        return (true, nil)
    }
    
    /**
     * Returns the expenses in a particular period, or all the expenses if this
     * is not a recurring goal, from most recently created to least recently.
     */
    public func getExpenses(period: CalendarPeriod) -> [Expense] {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        
        if isRecurring {
            let fs = "ANY goals_ = %@ AND transactionDate_ >= %@ AND transactionDate_ < %@"
            fetchRequest.predicate = NSPredicate(format: fs, self, period.start as CVarArg, period.end as CVarArg)
        } else {
            let fs = "ANY goals_ = %@"
            fetchRequest.predicate = NSPredicate(format: fs, self)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated_", ascending: false)]
        
        let expenseResults = try! context.fetch(fetchRequest)
        
        return expenseResults
    }
    
    public var hasIncrementalPayment: Bool {
        return self.payFrequency.scope != .None
    }
    
    public var isRecurring: Bool {
        return self.period.scope != .None
    }
    
    public var archived: Bool {
        get {
            return archived_
        }
        set {
            archived_ = newValue
        }
    }
    
    public var alwaysCarryOver: Bool {
        get {
            return alwaysCarryOver_
        }
        set {
            alwaysCarryOver_ = newValue
        }
    }
    
    public var adjustMonthAmountAutomatically: Bool {
        get {
            return adjustMonthAmountAutomatically_
        }
        set {
            adjustMonthAmountAutomatically_ = newValue
        }
    }
    
    public var period: Period {
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

    public var payFrequency: Period {
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
    
    public var start: Date? {
        get {
            if let day = start_ as Date? {
                return day
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                // Get relevant days.
                start_ = newValue! as NSDate
            } else {
                start_ = nil
            }
        }
    }
    
    public var end: Date? {
        get {
            if let day = end_ as Date? {
                return day
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                // Get relevant days.
                end_ = newValue! as NSDate
            } else {
                end_ = nil
            }
        }
    }
    
    public var amount: Decimal? {
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
    
    public var shortDescription: String? {
        get {
            return shortDescription_
        }
        set {
            shortDescription_ = newValue
        }
    }
    
    public var dateCreated: Date? {
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
    public var sortedExpenses: [Expense]? {
        if let e = expenses {
            return e.sorted(by: { $0.transactionDay! < $1.transactionDay! })
        } else {
            return nil
        }
    }
    
    public var expenses: Set<Expense>? {
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
    
    public var sortedAdjustments: [Adjustment]? {
        if let a = adjustments {
            return a.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    public var adjustments: Set<Adjustment>? {
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
    
    public var sortedPauses: [Pause]? {
        if let p = pauses {
            return p.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    public var pauses: Set<Pause>? {
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
    
    public var parentGoal: Goal? {
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
    
    public var childGoals: Set<Goal>? {
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
