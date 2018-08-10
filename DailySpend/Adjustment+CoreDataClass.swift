//
//  Adjustment+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 10/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Adjustment)
class Adjustment: NSManagedObject {
    func json(jsonIds: [NSManagedObjectID: Int]) -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let amountPerDay = amountPerDay {
            let num = amountPerDay as NSNumber
            jsonObj["amountPerDay"] = num
        } else {
            Logger.debug("couldn't unwrap amountPerDay in Adjustment")
            return nil
        }
        
        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Adjustment")
            return nil
        }
        
        if let date = firstDayEffective?.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["firstDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Adjustment")
            return nil
        }
        
        if let date = lastDayEffective?.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["lastDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap lastDateEffective in Adjustment")
            return nil
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Adjustment")
            return nil
        }

        if let goals = goals {
            var goalJsonIds = [Int]()
            for goal in goals {
                if let jsonId = jsonIds[goal.objectID] {
                    goalJsonIds.append(jsonId)
                } else {
                    Logger.debug("a goal didn't have an associated jsonId in Adjustment")
                    return nil
                }
            }
            jsonObj["goals"] = goalJsonIds
        } else {
            Logger.debug("couldn't unwrap goals in Adjustment")
            return nil
        }

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
                      jsonIds: [Int: NSManagedObjectID]) -> Adjustment? {
        let adjustment = Adjustment(context: context)
        
        if let amountPerDay = json["amountPerDay"] as? NSNumber {
            let decimal = Decimal(amountPerDay.doubleValue)
            if decimal == 0 {
                Logger.debug("amountPerDay equal to 0 in Adjustment")
                return nil
            }
            adjustment.amountPerDay = decimal
        } else {
            Logger.debug("couldn't unwrap amountPerDay in Adjustment")
            return nil
        }
        
        if let dateNumber = json["firstDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay.gmtDate != date {
                // The date isn't a beginning of day
                Logger.debug("The firstDateEffective isn't a beginning of day in Adjustment")
                return nil
            }
            adjustment.firstDayEffective = calDay
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Adjustment")
            return nil
        }
        
        if let dateNumber = json["lastDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay.gmtDate != date ||
                calDay < adjustment.firstDayEffective! {
                // The date isn't a beginning of day
                Logger.debug("The lastDateEffective isn't a beginning of day or is earlier than firstDateEffective in Adjustment")
                return nil
            }
            adjustment.lastDayEffective = calDay
        } else {
            Logger.debug("couldn't unwrap lastDateEffective in Adjustment")
            return nil
        }
        
        if let shortDescription = json["shortDescription"] as? String {
            if shortDescription.count == 0 {
                Logger.debug("shortDescription empty in Adjustment")
                return nil
            }
            adjustment.shortDescription = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Adjustment")
            return nil
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Adjustment")
                return nil
            }
            adjustment.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in Adjustment")
            return nil
        }
        
        if let goalJsonIds = json["goals"] as? Array<Int> {
            for goalJsonId in goalJsonIds {
                if let objectID = jsonIds[goalJsonId],
                    let goal = context.object(with: objectID) as? Goal {
                    adjustment.addGoal(goal)
                } else {
                    Logger.debug("a goal didn't have an associated objectID in Adjustment")
                    return nil
                }
            }
        } else {
            Logger.debug("couldn't unwrap goals in Adjustment")
            return nil
        }
        
        return adjustment
    }
    
    class func get(context: NSManagedObjectContext,
                   predicate: NSPredicate? = nil,
                   sortDescriptors: [NSSortDescriptor]? = nil,
                   fetchLimit: Int = 0) -> [Adjustment]? {
        let fetchRequest: NSFetchRequest<Adjustment> = Adjustment.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        
        let adjustmentResults = try? context.fetch(fetchRequest)
        
        return adjustmentResults
    }
    
    /**
     * Accepts all members of Adjustment. If the passed variables, attached to
     * corresponding variables on an Adjustment object, will form a valid
     * object, this function will assign the passed variables to this object
     * and return `(valid: true, problem: nil)`. Otherwise, this function will
     * return `(valid: false, problem: ...)` with problem set to a user
     * readable string describing why this adjustment wouldn't be valid.
     */
    func propose(shortDescription: String?? = nil,
                 amountPerDay: Decimal?? = nil,
                 firstDayEffective: CalendarDay?? = nil,
                 lastDayEffective: CalendarDay?? = nil,
                 dateCreated: Date?? = nil) -> (valid: Bool, problem: String?) {
        
        let _shortDescription = shortDescription ?? self.shortDescription
        let _amountPerDay = amountPerDay ?? self.amountPerDay
        let _firstDayEffective = firstDayEffective ?? self.firstDayEffective
        let _lastDayEffective = lastDayEffective ?? self.lastDayEffective
        let _dateCreated = dateCreated ?? self.dateCreated
        
        if _shortDescription == nil || _shortDescription!.count == 0 {
            return (false, "This adjustment must have a description.")
        }
        
        if _amountPerDay == nil || _amountPerDay! == 0 {
            return (false, "This adjustment must have an amount specified.")
        }
        
        if _firstDayEffective == nil || _lastDayEffective == nil ||
            _firstDayEffective! > _lastDayEffective! {
            return (false, "The first day effective be before the last day effective.")
        }
        
        if _dateCreated == nil {
            return (false, "The adjustment must have a date created.")
        }
        
        self.shortDescription = _shortDescription
        self.amountPerDay = _amountPerDay
        self.firstDayEffective = _firstDayEffective
        self.lastDayEffective = _lastDayEffective
        self.dateCreated = _dateCreated
        return (true, nil)
    }
    
    // Accessor functions (for Swift 3 classes)
    
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
    
    var shortDescription: String? {
        get {
            return shortDescription_
        }
        set {
            shortDescription_ = newValue
        }
    }
    
    var amountPerDay: Decimal? {
        get {
            return amountPerDay_ as Decimal?
        }
        set {
            if newValue != nil {
                amountPerDay_ = NSDecimalNumber(decimal: newValue!)
            } else {
                amountPerDay_ = nil
            }
        }
    }
    
    var firstDayEffective: CalendarDay? {
        get {
            if let day = firstDateEffective_ as Date? {
                return CalendarDay(dateInGMTDay: day)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                firstDateEffective_ = newValue!.gmtDate as NSDate
            } else {
                firstDateEffective_ = nil
            }
        }
    }
    
    var lastDayEffective: CalendarDay? {
        get {
            if let day = lastDateEffective_ as Date? {
                return CalendarDay(dateInGMTDay: day)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                lastDateEffective_ = newValue!.gmtDate as NSDate
            } else {
                lastDateEffective_ = nil
            }
        }
    }
    
    /**
     * `goals` sorted in a deterministic way.
     */
    var sortedGoals: [Goal]? {
        if let g = goals {
            return g.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    var goals: Set<Goal>? {
        get {
            return goals_ as! Set?
        }
        set {
            if newValue != nil {
                goals_ = NSSet(set: newValue!)
            } else {
                goals_ = nil
            }
        }
    }
    
    func addGoal(_ goal: Goal) {
        addToGoals_(goal)
    }
    
    func removeGoal(_ goal: Goal) {
        removeFromGoals_(goal)
    }
}

