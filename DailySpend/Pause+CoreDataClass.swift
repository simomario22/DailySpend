//
//  Pause+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

@objc(Pause)
class Pause: NSManagedObject {
    func json(jsonIds: [NSManagedObjectID: Int]) -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Pause")
            return nil
        }
        
        if let date = firstDayEffective?.start.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["firstDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Pause")
            return nil
        }
        
        if let date = lastDayEffective?.start.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["lastDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap lastDateEffective in Pause")
            return nil
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Pause")
            return nil
        }
        
        if let goals = goals {
            var goalJsonIds = [Int]()
            for goal in goals {
                if let jsonId = jsonIds[goal.objectID] {
                    goalJsonIds.append(jsonId)
                } else {
                    Logger.debug("a goal didn't have an associated jsonId in Expense")
                    return nil
                }
            }
            jsonObj["goals"] = goalJsonIds
        } else {
            Logger.debug("couldn't unwrap goals in Expense")
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
                      jsonIds: [Int: NSManagedObjectID]) -> Pause? {
        let pause = Pause(context: context)
        
        if let dateNumber = json["firstDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInDay: GMTDate(date))
            if calDay.start.gmtDate != date {
                // The date isn't a beginning of day
                Logger.debug("The firstDateEffective isn't a beginning of day in Pause")
                return nil
            }
            pause.firstDayEffective = calDay
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Pause")
            return nil
        }
        
        if let dateNumber = json["lastDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInDay: GMTDate(date))
            if calDay.start.gmtDate != date ||
                calDay < pause.firstDayEffective! {
                // The date isn't a beginning of day
                Logger.debug("The lastDateEffective isn't a beginning of day or is earlier than firstDateEffective in Pause")
                return nil
            }
            pause.lastDayEffective = calDay
        } else {
            Logger.debug("couldn't unwrap lastDateEffective in Pause")
            return nil
        }
        
        if let shortDescription = json["shortDescription"] as? String {
            if shortDescription.count == 0 {
                Logger.debug("shortDescription empty in Pause")
                return nil
            }
            pause.shortDescription = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Pause")
            return nil
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Pause")
                return nil
            }
            pause.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in Pause")
            return nil
        }
        
        let pauses = Pause.get(context: context)
        for otherPause in pauses! {
            if otherPause.objectID != pause.objectID && pause.overlapsWith(pause: otherPause)! {
                Logger.debug("pause overlapped with another pause")
                return nil
            }
        }
        
        if let goalJsonIds = json["goals"] as? Array<Int> {
            for goalJsonId in goalJsonIds {
                if let objectID = jsonIds[goalJsonId],
                    let goal = context.object(with: objectID) as? Goal {
                    pause.addGoal(goal)
                } else {
                    Logger.debug("a goal didn't have an associated objectID in Pause")
                    return nil
                }
            }
        } else {
            Logger.debug("couldn't unwrap goals in Pause")
            return nil
        }
        
        return pause
    }
    
    class func get(context: NSManagedObjectContext,
                   predicate: NSPredicate? = nil,
                   sortDescriptors: [NSSortDescriptor]? = nil,
                   fetchLimit: Int = 0) -> [Pause]? {
        let fetchRequest: NSFetchRequest<Pause> = Pause.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        
        let pauseResults = try? context.fetch(fetchRequest)
        
        return pauseResults
    }
    
    func propose(context: NSManagedObjectContext,
                 shortDescription: String?? = nil,
                 firstDayEffective: CalendarDay?? = nil,
                 lastDayEffective: CalendarDay?? = nil,
                 dateCreated: Date?? = nil) -> (valid: Bool, problem: String?) {
        let _shortDescription = shortDescription ?? self.shortDescription
        let _firstDayEffective = firstDayEffective ?? self.firstDayEffective
        let _lastDayEffective = lastDayEffective ?? self.lastDayEffective
        let _dateCreated = dateCreated ?? self.dateCreated
        
        if _shortDescription == nil || _shortDescription!.count == 0 {
            return (false, "This pause must have a description.")
        }
        
        if _firstDayEffective == nil || _lastDayEffective == nil ||
            _firstDayEffective! > _lastDayEffective! {
            return (false, "The first day effective must be before the last day effective.")
        }
        
        if _dateCreated == nil {
            return (false, "The pause must have a date created.")
        }
        
        // Check for overlapping pauses.
        let fetchRequest: NSFetchRequest<Pause> = Pause.fetchRequest()
        let pred = NSPredicate(format: "%@ <= lastDateEffective_ AND %@ >= firstDateEffective_",
                               _firstDayEffective!.start.gmtDate as CVarArg,
                               _lastDayEffective!.start.gmtDate as CVarArg)
        fetchRequest.predicate = pred
        let pauseResults = try! context.fetch(fetchRequest)
        
        if pauseResults.count > 1 {
            Logger.warning("There are overlapping pauses.")
        }
        
        if let pause = pauseResults.first {
            if pause.objectID != self.objectID {
                // This a different pause whose date range overlaps with ours.
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy"
                let formattedFirstDate = pause.firstDayEffective!.string(formatter: dateFormatter)
                let formattedLastDate = pause.lastDayEffective!.string(formatter: dateFormatter)
                
                return (false,
                        "The date range overlaps with another pause with the description " +
                            "\"\(pause.shortDescription!)\" from \(formattedFirstDate) to " +
                            "\(formattedLastDate). Change the date range so it doesn't overlap " +
                    "with any other pauses.")
            }
        }
        
        self.shortDescription = _shortDescription
        self.firstDayEffective = _firstDayEffective
        self.lastDayEffective = _lastDayEffective
        self.dateCreated = _dateCreated
        return (true, nil)
    }
    
    func overlapsWith(pause: Pause) -> Bool? {
        guard self.firstDayEffective != nil &&
            self.lastDayEffective != nil &&
            pause.firstDayEffective != nil &&
            pause.lastDayEffective != nil else {
                return nil
        }
        return self.firstDayEffective! <= pause.lastDayEffective! &&
            self.lastDayEffective! >= pause.firstDayEffective!
    }
    
    func humanReadableRange() -> String {
        // Format the dates like 3/6 or 3/6/16.
        let thisYear = CalendarDay().year
        let dateFormatter = DateFormatter()
        if firstDayEffective!.year == thisYear &&
            lastDayEffective!.year == thisYear {
            dateFormatter.dateFormat = "M/d"
        } else {
            dateFormatter.dateFormat = "M/d/yy"
        }
        
        let firstDay = firstDayEffective!.string(formatter: dateFormatter)
        if firstDayEffective! == lastDayEffective! {
            return "\(firstDay)"
        } else {
            let lastDay = lastDayEffective!.string(formatter: dateFormatter)
            return "\(firstDay) - \(lastDay)"
        }
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
    
    var firstDayEffective: CalendarDay? {
        get {
            if let day = firstDateEffective_ as Date? {
                return CalendarDay(dateInDay: GMTDate(day))
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                firstDateEffective_ = newValue!.start.gmtDate as NSDate
            } else {
                firstDateEffective_ = nil
            }
        }
    }
    
    var lastDayEffective: CalendarDay? {
        get {
            if let day = lastDateEffective_ as Date? {
                return CalendarDay(dateInDay: GMTDate(day))
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                lastDateEffective_ = newValue!.start.gmtDate as NSDate
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

