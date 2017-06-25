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
    public func json() -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let amount = amount {
            let num = amount as NSNumber
            jsonObj["amount"] = num
        } else {
            return nil
        }
        
        if let shortDescription = shortDescription {
            jsonObj["shortDescription"] = shortDescription
        } else {
            return nil
        }
        
        if let notes = notes {
            jsonObj["notes"] = notes
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
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
                      json: [String: Any]) -> Expense? {
        let expense = Expense(context: context)
        
        if let amount = json["amount"] as? NSNumber {
            let decimal = Decimal(amount.doubleValue)
            if decimal <= 0 {
                return nil
            }
            expense.amount = decimal
        } else {
            return nil
        }
        
        if let shortDescription = json["shortDescription"] as? String {
            if shortDescription.characters.count == 0 {
                return nil
            }
            expense.shortDescription = shortDescription
        } else {
            return nil
        }
        
        if let notes = json["notes"] as? String {
            expense.notes = notes
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                return nil
            }
            expense.dateCreated = date
        } else {
            return nil
        }
        
        return expense
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
    
    
    public var day: Day? {
        get {
            return day_
        }
        set {
            day_ = newValue
        }
    }


}
