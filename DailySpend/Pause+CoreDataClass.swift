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
public class Pause: NSManagedObject {
    public func json() -> [String: Any]? {
        var jsonObj = [String: Any]()

        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Pause")
            return nil
        }
        
        if let date = firstDayEffective?.gmtDate {
            let num = date.timeIntervalSince1970 as NSNumber
            jsonObj["firstDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Pause")
            return nil
        }
        
        if let date = lastDayEffective?.gmtDate {
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
        
        return jsonObj
    }
    
    public func serialize() -> Data? {
        if let jsonObj = self.json() {
            let serialization = try? JSONSerialization.data(withJSONObject: jsonObj)
            return serialization
        }
        
        return nil
    }
    
    class func create(context: NSManagedObjectContext,
                      json: [String: Any]) -> Pause? {
        let pause = Pause(context: context)
        
        if let dateNumber = json["firstDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay.gmtDate != date {
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
            let calDay = CalendarDay(dateInGMTDay: date)
            if calDay.gmtDate != date ||
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
            if shortDescription.characters.count == 0 {
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
        
        let pauses = Pause.getPauses(context: context)
        for otherPause in pauses! {
            if otherPause.objectID != pause.objectID && pause.overlapsWith(pause: otherPause)! {
                Logger.debug("pause overlapped with another pause")
                return nil
            }
        }
        
        // Get relevant days.
        let relevantDays = Day.getRelevantDaysForPause(pause: pause, context: context)
        pause.daysAffected = Set<Day>(relevantDays)
        

        
        return pause
    }
    
    class func getPauses(context: NSManagedObjectContext,
                        predicate: NSPredicate? = nil,
                        sortDescriptors: [NSSortDescriptor]? = nil) -> [Pause]? {
        let fetchRequest: NSFetchRequest<Pause> = Pause.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        let pauseResults = try? context.fetch(fetchRequest)
        
        return pauseResults
    }
    
    /*
     * Return the pause that affects a certain day.
     */
    class func getRelevantPauseForDay(day: Day, context: NSManagedObjectContext) -> Pause? {
        let fetchRequest: NSFetchRequest<Pause> = Pause.fetchRequest()
        let pred = NSPredicate(format: "firstDateEffective_ <= %@ AND lastDateEffective_ >= %@",
                               day.calendarDay!.gmtDate as CVarArg, day.calendarDay!.gmtDate as CVarArg)
        fetchRequest.predicate = pred
        let sortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        fetchRequest.sortDescriptors = [sortDesc]
        let pauseResults = try! context.fetch(fetchRequest)

        if pauseResults.count > 1 {
            fatalError("There are overlapping pauses.")
        }
        
        return pauseResults.isEmpty ? nil : pauseResults[0]
    }
    
    func validate(context: NSManagedObjectContext) -> (valid: Bool, problem: String?) {
        if self.shortDescription == nil || self.shortDescription!.characters.count == 0 {
            return (false, "This pause must have a description.")
        }
        
        if self.firstDayEffective == nil || self.lastDayEffective == nil ||
            self.firstDayEffective! > self.lastDayEffective! {
            return (false, "The first day effective must not be after the last day effective.")
        }
        
        if self.dateCreated == nil {
            return (false, "The pause must have a date created.")
        }
        
        let pauses = Pause.getPauses(context: context)
        for pause in pauses! {
            if pause.objectID != self.objectID && self.overlapsWith(pause: pause)! {
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
    
    // Accessor functions (for Swift 3 classes)

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
    
    public var shortDescription: String? {
        get {
            return shortDescription_
        }
        set {
            shortDescription_ = newValue
        }
    }
    
    public var firstDayEffective: CalendarDay? {
        get {
            if let day = firstDateEffective_ as Date? {
                return CalendarDay(dateInGMTDay: day)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                // Get relevant days.
                firstDateEffective_ = newValue!.gmtDate as NSDate

                let relevantDays = Day.getRelevantDaysForPause(pause: self, context: context)
                self.daysAffected = Set<Day>(relevantDays)
            } else {
                self.daysAffected = Set<Day>()
                firstDateEffective_ = nil
            }
        }
    }
    
    public var lastDayEffective: CalendarDay? {
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
                
                let relevantDays = Day.getRelevantDaysForPause(pause: self, context: context)
                self.daysAffected = Set<Day>(relevantDays)
            } else {
                lastDateEffective_ = nil
            }
        }
    }

    
    public var sortedDaysAffected: [Day]? {
        if let affected = daysAffected {
            return affected.sorted(by: { $0.calendarDay! < $1.calendarDay! })
        } else {
            return nil
        }
    }
    
    public var daysAffected: Set<Day>? {
        get {
            return daysAffected_ as! Set?
        }
        set {
            if newValue != nil {
                daysAffected_ = NSSet(set: newValue!)
            } else {
                daysAffected_ = nil
            }
        }
    }
}