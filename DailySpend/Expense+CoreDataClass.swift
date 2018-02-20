//
//  Expense+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

@objc(Expense)
public class Expense: NSManagedObject {
    public func json(jsonIds: [NSManagedObjectID: Int]) -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let amount = amount {
            let num = amount as NSNumber
            jsonObj["amount"] = num
        } else {
            Logger.debug("couldn't unwrap amount in Expense")
            return nil
        }
        
        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Expense")
            return nil
        }
        
        if let notes = notes {
            jsonObj["notes"] = notes
        }

        if let transactionDate = transactionDate {
            let num = transactionDate.gmtDate.timeIntervalSince1970 as NSNumber
            jsonObj["transactionDate"] = num
        } else {
            Logger.debug("couldn't unwrap transactionDate in Expense")
            return nil
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Expense")
            return nil
        }
        
        if let imgs = sortedImages {
            var jsonImgs = [[String: Any]]()
            for image in imgs {
                if let jsonImg = image.json() {
                    jsonImgs.append(jsonImg)
                } else {
                    Logger.debug("couldn't unwrap jsonImg in Expense")
                    return nil
                }
            }
            jsonObj["images"] = jsonImgs
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
    
    public func serialize(jsonIds: [NSManagedObjectID: Int]) -> Data? {
        if let jsonObj = self.json(jsonIds: jsonIds) {
            let serialization = try? JSONSerialization.data(withJSONObject: jsonObj)
            return serialization
        }
        
        return nil
    }
    
    class func create(context: NSManagedObjectContext,
                      json: [String: Any],
                      jsonIds: [Int: NSManagedObjectID]) -> Expense? {
        let expense = Expense(context: context)
        
        if let amount = json["amount"] as? NSNumber {
            let decimal = Decimal(amount.doubleValue)
            if decimal <= 0 {
                Logger.debug("amount less than 0 in Expense")
                return nil
            }
            expense.amount = decimal
        } else {
            Logger.debug("couldn't unwrap amount in Expense")
            return nil
        }
        
        if let shortDescription = json["shortDescription"] as? String {
            if shortDescription.count == 0 {
                Logger.debug("shortDescription empty in Expense")
                return nil
            }
            expense.shortDescription = shortDescription
        } else {
            Logger.debug("couldn't unwrap shortDescription in Expense")
            return nil
        }
        
        if let notes = json["notes"] as? String {
            expense.notes = notes
        }
        
        if let jsonImgs = json["images"] as? [[String: Any]] {
            for jsonImg in jsonImgs {
                if let image = Image.create(context: context, json: jsonImg) {
                    image.expense = expense
                } else {
                    Logger.debug("couldn't create image in Expense")
                    return nil
                }
            }
        }
        
        if let transactionDate = json["transactionDate"] as? NSNumber {
            let date = Date(timeIntervalSince1970: transactionDate.doubleValue)
            let calDay = CalendarDay(dateInGMTDay: date);
            if date != calDay.gmtDate {
                Logger.debug("transactionDate after today in Expense")
                return nil
            }
            expense.transactionDate = calDay
        } else {
            Logger.debug("coulnd't unwrap transactionDate in Expense")
            return nil
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Expense")
                return nil
            }
            expense.dateCreated = date
        } else {
            Logger.debug("coulnd't unwrap dateCreated in Expense")
            return nil
        }
        
        if let goalJsonIds = json["goals"] as? Array<Int> {
            for goalJsonId in goalJsonIds {
                if let objectID = jsonIds[goalJsonId],
                    let goal = context.object(with: objectID) as? Goal {
                    expense.addGoal(goal)
                } else {
                    Logger.debug("a goal didn't have an associated objectID in Expense")
                    return nil
                }
            }
        } else {
            Logger.debug("couldn't unwrap goals in Expense")
            return nil
        }
        
        return expense
    }
    
    class func get(context: NSManagedObjectContext,
                   predicate: NSPredicate? = nil,
                   sortDescriptors: [NSSortDescriptor]? = nil,
                   fetchLimit: Int = 0) -> [Expense]? {
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = fetchLimit
        
        let expenseResults = try? context.fetch(fetchRequest)
        
        return expenseResults
    }
    
    // Accessor functions (for Swift 3 classes)
    
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
    
    public var transactionDate: CalendarDay? {
        get {
            if let date = transactionDate_ {
                return CalendarDay(dateInGMTDay: date as Date)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                transactionDate_ = newValue!.gmtDate as NSDate
            } else {
                transactionDate_ = nil
            }
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
    
    public var shortDescription: String? {
        get {
            return shortDescription_
        }
        set {
            shortDescription_ = newValue
        }
    }
    
    public var notes: String? {
        get {
            return notes_
        }
        set {
            notes_ = newValue
        }
    }
    
    public var sortedGoals: [Goal]? {
        if let g = goals {
            return g.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    public var goals: Set<Goal>? {
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
    
    public func addGoal(_ goal: Goal) {
        addToGoals_(goal)
    }
    
    public func removeGoal(_ goal: Goal) {
        removeFromGoals_(goal)
    }
    
    public var sortedImages: [Image]? {
        if let img = images {
            return img.sorted(by: { $0.dateCreated! < $1.dateCreated! })
        } else {
            return nil
        }
    }
    
    public var images: Set<Image>? {
        get {
            return images_ as! Set?
        }
        set {
            if newValue != nil {
                images_ = NSSet(set: newValue!)
            } else {
                images_ = nil
            }
        }
    }
}

