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

public enum Period: Int {
    case Day = 0
    case Week = 1
    case Month = 2
    
    func string() -> String {
        switch self {
        case .Day:
            return "Day"
        case .Week:
            return "Week"
        case .Month:
            return "Month"
        }
    }
}

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

        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Goal")
            return nil
        }
        
        if let date = start?.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["start"] = num
        } else {
            Logger.debug("couldn't unwrap start in Goal")
            return nil
        }
        
        if let date = end?.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["end"] = num
        } else {
            Logger.debug("couldn't unwrap end in Goal")
            return nil
        }
        
        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Goal")
            return nil
        }
        
        jsonObj["period"] = period.rawValue as NSNumber
        jsonObj["periodMultiplier"] = periodMultiplier as NSNumber
        
        jsonObj["reconcileFrequency"] = reconcileFrequency.rawValue as NSNumber
        jsonObj["reconcileFrequencyMultiplier"] = reconcileFrequencyMultiplier as NSNumber

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
        
        if let dateNumber = json["start"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay.gmtDate != date {
                // The date isn't a beginning of day
                Logger.debug("The start date isn't a beginning of day in Goal")
                return .Failure
            }
            goal.start = calDay
        } else {
            Logger.debug("couldn't unwrap start in Goal")
            return .Failure
        }
        
        if let dateNumber = json["end"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay.gmtDate != date ||
                calDay < goal.start! {
                // The date isn't a beginning of day
                Logger.debug("The end date isn't a beginning of day or is earlier than start in Goal")
                return .Failure
            }
            goal.end = calDay
        } else {
            Logger.debug("couldn't unwrap end in Goal")
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
        
        if let periodNumber = json["period"] as? NSNumber {
            if let period = Period(rawValue: periodNumber.intValue) {
                goal.period = period
            } else {
                Logger.debug("period wasn't a valid number in Goal")
                return .Failure
            }
        } else {
            Logger.debug("couldn't unwrap period in Goal")
            return .Failure
        }
        
        if let periodMultiplierNumber = json["periodMultiplier"] as? NSNumber {
            let periodMultiplier = periodMultiplierNumber.intValue
            if periodMultiplier < 0 {
                Logger.debug("periodMultiplier was less than 0 Goal")
                return .Failure
            }
            goal.periodMultiplier = periodMultiplier
        } else {
            Logger.debug("couldn't unwrap periodMultiplier in Goal")
            return .Failure
        }
        
        if let reconcileFrequencyNumber = json["reconcileFrequency"] as? NSNumber {
            if let reconcileFrequency = Period(rawValue: reconcileFrequencyNumber.intValue) {
                goal.reconcileFrequency = reconcileFrequency
            } else {
                Logger.debug("reconcileFrequency wasn't a valid number in Goal")
                return .Failure
            }
        } else {
            Logger.debug("couldn't unwrap reconcileFrequency in Goal")
            return .Failure
        }
        
        if let reconcileFrequencyMultiplierNumber = json["reconcileFrequencyMultiplier"] as? NSNumber {
            let reconcileFrequencyMultiplier = reconcileFrequencyMultiplierNumber.intValue
            if reconcileFrequencyMultiplier < 0 {
                Logger.debug("reconcileFrequencyMultiplier was less than 0 Goal")
                return .Failure
            }
            goal.reconcileFrequencyMultiplier = reconcileFrequencyMultiplier
        } else {
            Logger.debug("couldn't unwrap reconcileFrequencyMultiplier in Goal")
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
    
    public var archived: Bool {
        get {
            return archived_
        }
        set {
            archived_ = newValue
        }
    }
    
    public var period: Period {
        get {
            return Period(rawValue: Int(period_))!
        }
        set {
            period_ = Int64(newValue.rawValue)
        }
    }
    
    public var periodMultiplier: Int {
        get {
            return Int(periodMultiplier_)
        }
        set {
            periodMultiplier_ = Int64(newValue)
        }
    }
    
    public var reconcileFrequency: Period {
        get {
            return Period(rawValue: Int(period_))!
        }
        set {
            period_ = Int64(newValue.rawValue)
        }
    }
    
    public var reconcileFrequencyMultiplier: Int {
        get {
            return Int(periodMultiplier_)
        }
        set {
            periodMultiplier_ = Int64(newValue)
        }
    }
    
    public var start: CalendarDay? {
        get {
            if let day = start_ as Date? {
                return CalendarDay(dateInGMTDay: day)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                // Get relevant days.
                start_ = newValue!.gmtDate as NSDate
            } else {
                start_ = nil
            }
        }
    }
    
    public var end: CalendarDay? {
        get {
            if let day = end_ as Date? {
                return CalendarDay(dateInGMTDay: day)
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
    
    public var sortedExpenses: [Expense]? {
        if let e = expenses {
            return e.sorted(by: { $0.transactionDate! < $1.transactionDate! })
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

