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
    func json(jsonIds: [NSManagedObjectID: Int]) -> (value: [String: Any]?, failure: Bool) {
        if type == .CarryOverDeleted {
            return (nil, false)
        }
        var jsonObj = [String: Any]()

        jsonObj["shortDescription"] = shortDescription
        jsonObj["adjustmentType"] = type.rawValue
        jsonObj["countedInBalance"] = (type != .CarryOverDeleted)

        if let amountPerDay = amountPerDay {
            let num = amountPerDay as NSNumber
            jsonObj["amountPerDay"] = num
        } else {
            Logger.debug("couldn't unwrap amountPerDay in Adjustment")
            return (nil, true)
        }
        
        if let date = firstDayEffective?.start {
            let num = date.gmtDate.timeIntervalSince1970 as NSNumber
            jsonObj["firstDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Adjustment")
            return (nil, true)
        }
        
        if let date = lastDayEffective?.start {
            let num = date.gmtDate.timeIntervalSince1970 as NSNumber
            jsonObj["lastDateEffective"] = num
        } else {
            Logger.debug("couldn't unwrap lastDateEffective in Adjustment")
            return (nil, true)
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Adjustment")
            return (nil, true)
        }

        if let goal = goal {
            var goalJsonIds = [Int]()
            if let jsonId = jsonIds[goal.objectID] {
                goalJsonIds.append(jsonId)
            } else {
                Logger.debug("a goal didn't have an associated jsonId in Adjustment")
                return (nil, true)
            }
            jsonObj["goals"] = goalJsonIds
        } else {
            Logger.debug("couldn't unwrap goal in Adjustment")
            return (nil, true)
        }
        return (jsonObj, false)
    }
    
    func serialize(jsonIds: [NSManagedObjectID: Int]) -> (data: Data?, failure: Bool) {
        let (jsonObj, failure) = self.json(jsonIds: jsonIds)

        if !failure {
            if let jsonObj = jsonObj {
                let serialization = try? JSONSerialization.data(withJSONObject: jsonObj)
                return (serialization, false)
            } else {
                return (nil, false)
            }
        }
        
        return (nil, true)
    }
    
    class func create(context: NSManagedObjectContext,
                      json: [String: Any],
                      jsonIds: [Int: NSManagedObjectID]) -> (Adjustment?, Bool) {
        let adjustment = Adjustment(context: context)

        if let type = json["adjustmentType"] as? NSNumber {
            if let type = AdjustmentType(rawValue: type.intValue) {
                adjustment.type = type
            } else {
                Logger.debug("invalid adjustment type in Adjustment")
                return (nil, false)
            }
        }
        
        if let amountPerDay = json["amountPerDay"] as? NSNumber {
            let decimal = Decimal(amountPerDay.doubleValue)
            if decimal == 0 {
                Logger.debug("amountPerDay equal to 0 in Adjustment")
                return (nil, false)
            }
            adjustment.amountPerDay = decimal
        } else {
            Logger.debug("couldn't unwrap amountPerDay in Adjustment")
            return (nil, false)
        }
        
        if let dateNumber = json["firstDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInDay: GMTDate(date))
            if calDay.start.gmtDate != date {
                // The date isn't a beginning of day
                Logger.debug("The firstDateEffective isn't a beginning of day in Adjustment")
                return (nil, false)
            }
            adjustment.firstDayEffective = calDay
        } else {
            Logger.debug("couldn't unwrap firstDateEffective in Adjustment")
            return (nil, false)
        }
        
        if let dateNumber = json["lastDateEffective"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
            let calDay = CalendarDay(dateInDay: GMTDate(date))
            if calDay.start.gmtDate != date ||
                calDay < adjustment.firstDayEffective! {
                // The date isn't a beginning of day
                Logger.debug("The lastDateEffective isn't a beginning of day or is earlier than firstDateEffective in Adjustment")
                return (nil, false)
            }
            adjustment.lastDayEffective = calDay
        } else {
            Logger.debug("couldn't unwrap lastDateEffective in Adjustment")
            return (nil, false)
        }
        
        if let shortDescription = json["shortDescription"] as? String {
            if shortDescription.count == 0 {
                Logger.debug("shortDescription empty in Adjustment")
                return (nil, false)
            }
            adjustment.shortDescription = shortDescription
        } else {
            adjustment.shortDescription = nil
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Adjustment")
                return (nil, false)
            }
            adjustment.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in Adjustment")
            return (nil, false)
        }
        
        if let goalJsonIds = json["goals"] as? Array<Int> {
            if goalJsonIds.count > 1 {
                Logger.debug("there were multiple goals associated with an Adjustment")
                return (nil, false)
            }
            for goalJsonId in goalJsonIds {
                if let objectID = jsonIds[goalJsonId],
                    let goal = context.object(with: objectID) as? Goal {
                    adjustment.goal = goal
                } else {
                    Logger.debug("a goal didn't have an associated objectID in Adjustment")
                    return (nil, false)
                }
            }
        } else {
            Logger.debug("couldn't unwrap goals in Adjustment")
            return (nil, false)
        }
        
        return (adjustment, true)
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
    func propose(
        shortDescription: String?? = nil,
         amountPerDay: Decimal?? = nil,
         firstDayEffective: CalendarDay?? = nil,
         lastDayEffective: CalendarDay?? = nil,
         type: AdjustmentType? = nil,
         dateCreated: Date?? = nil,
         goal: Goal? = nil
    ) -> (valid: Bool, problem: String?) {
        
        let _shortDescription = shortDescription ?? self.shortDescription
        let _amountPerDay = amountPerDay ?? self.amountPerDay
        let _firstDayEffective = firstDayEffective ?? self.firstDayEffective
        let _lastDayEffective = lastDayEffective ?? self.lastDayEffective
        let _type = type ?? self.type
        let _dateCreated = dateCreated ?? self.dateCreated
        let _goal = goal ?? self.goal
        
        if _amountPerDay == nil || (_amountPerDay! == 0 && _type != .CarryOver && _type != .CarryOverDeleted) {
            return (false, "This adjustment must have an amount specified.")
        }
        
        if _firstDayEffective == nil || _lastDayEffective == nil ||
            _firstDayEffective! > _lastDayEffective! {
            return (false, "The first day effective be before the last day effective.")
        }
        
        if _dateCreated == nil {
            return (false, "The adjustment must have a date created.")
        }

        let goalStart = _goal?.firstPaySchedule()?.start
        let goalExclusiveEnd = _goal?.lastPaySchedule()?.exclusiveEnd
        
        if goalStart == nil || _firstDayEffective!.start.gmtDate < goalStart!.gmtDate {
            return (false, "This adjustment must begin after its associated goal's start date.")
        }
        
        if goalExclusiveEnd != nil && _lastDayEffective!.start.gmtDate > goalExclusiveEnd!.gmtDate {
            return (false, "This adjustment must end before its associated goal's end date.")
        }
        
        self.shortDescription = _shortDescription
        self.amountPerDay = _amountPerDay
        self.firstDayEffective = _firstDayEffective
        self.lastDayEffective = _lastDayEffective
        self.type = _type
        self.dateCreated = _dateCreated
        self.goal = _goal
        return (true, nil)
    }
    
    /**
     * Returns the amount of money paid by this adjustment during the overlap
     * between the interval for this adjustment and the passed interval.
     */
    func overlappingAmount(with interval: CalendarIntervalProvider) -> Decimal {
        guard let amountPerDay = amountPerDay,
              let overlappingInterval = effectiveInterval?.overlappingInterval(with: interval) else {
            return 0
        }
    
        let firstDay = CalendarDay(dateInDay: overlappingInterval.start)
        
        // We know overlappingInterval.end is not `nil` because our
        // `effectiveInterval` has a non-`nil` `end`.
        let exclusiveLastDay = CalendarDay(dateInDay: overlappingInterval.end)!
        
        let daysApplied = exclusiveLastDay.daysAfter(startDay: firstDay)
        return amountPerDay * Decimal(daysApplied)
    }
    
    func humanReadableInterval() -> String? {
        guard let firstDayEffective = firstDayEffective,
              let lastDayEffective = lastDayEffective else {
            return nil
        }
        
        // Format the dates like 3/6 or 3/6/16.
        let thisYear = CalendarDay().year
        let dateFormatter = DateFormatter()
        if firstDayEffective.year == thisYear &&
            lastDayEffective.year == thisYear {
            dateFormatter.dateFormat = "M/d"
        } else {
            dateFormatter.dateFormat = "M/d/yy"
        }
        
        let firstDay = firstDayEffective.string(formatter: dateFormatter)
        if firstDayEffective == lastDayEffective {
            return "\(firstDay)"
        } else {
            let lastDay = lastDayEffective.string(formatter: dateFormatter)
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
    
    var amountPerDay: Decimal? {
        get {
            return amountPerDay_ as Decimal?
        }
        set {
            if newValue != nil {
                amountPerDay_ = NSDecimalNumber(decimal: newValue!.roundToNearest(th: 100))
            } else {
                amountPerDay_ = nil
            }
        }
    }
    
    /**
     * The exclusive interval containing days when the adjustment should be
     * applied.
     */
    var effectiveInterval: CalendarInterval? {
        get {
            guard
                let firstDateEffective = firstDateEffective_ as Date?,
                let lastDateEffective = lastDateEffective_ as Date?
                else {
                    return nil
            }
            
            let firstDayEffective = GMTDate(firstDateEffective)
            let lastDayEffective = CalendarDay(dateInDay: GMTDate(lastDateEffective))
            return CalendarInterval(start: firstDayEffective, end: lastDayEffective.end)
        }
        set {
            guard let interval = newValue else {
                firstDateEffective_ = nil
                lastDateEffective_ = nil
                return
            }
            
            let lastDayEffective = CalendarDay(dateInDay: interval.end!).subtract(days: 1)
            firstDateEffective_ = CalendarDay(dateInDay: interval.start).start.gmtDate as NSDate
            lastDateEffective_ = lastDayEffective.start.gmtDate as NSDate
        }
    }

    /**
     * The first day the adjustment should be applied.
     */
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
    
    /**
     * The last day the adjustment should be applied.
     */
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
     * This corresponds to the `type` property of an adjustment, telling us more
     * about how it should behave.
     */
    enum AdjustmentType: Int {
        /**
         * This value signifies that the adjustment was explicity created by
         * the user.
         */
        case UserCreated = 0
        
        /**
         * This value signifies that the adjustment was created automatically
         * as a carry over expense.
         */
        case CarryOver = 1
        
        /**
         * This value signifies that the adjustment was created automatically
         * as a carry over expense, but was then deleted by the user. Another
         * carry over expense should not be created, and the value of this
         * expense should not be used.
         */
        case CarryOverDeleted = 2

        /**
         * Returns a string for a fetch request's predicate that will match
         * all types of carry over expenses.
         *
         * Note that the returned string is enclosed in parenthesis, and, if
         * used with other conditions, must be chained using logical operators.
         */
        static func isCarryOverAdjustmentPredicateString() -> String {
            return "(type_ == \(Adjustment.AdjustmentType.CarryOver.rawValue) OR " +
                   "type_ == \(Adjustment.AdjustmentType.CarryOverDeleted.rawValue))"
        }

        /**
         * Returns a string for a fetch request's predicate that will match
         * adjustments that are valid to be counted in a goal's balance (i.e.
         * not deleted carry over adjustments).
         *
         * Note that the returned string is enclosed in parenthesis, and, if
         * used with other conditions, must be chained using logical operators.
         */
        static func isValidCarryOverAdjustmentPredicateString() -> String {
            return "(type_ == \(Adjustment.AdjustmentType.CarryOver.rawValue))"
        }
    }
    
    /**
     * This is the type of this adjustment.
     */
    var type: AdjustmentType {
        get {
            return AdjustmentType(rawValue: Int(type_))!
        }
        set {
            type_ = Int64(newValue.rawValue)
        }
    }

    /**
     * `true` if this adjustment is a carry over adjustment and should be
     * counted as part of a goal's balance, otherwise `false`.
     */
    var isValidCarryOverAdjustmentType: Bool {
        return type == .CarryOver
    }

    /**
     * `true` if this adjustment is a carry over adjustment, deleted or not.
     */
    var isCarryOverAdjustmentType: Bool {
        return type == .CarryOver || type == .CarryOverDeleted
    }

    /**
     * Adjustments can currently only be associated with one goal. This is that
     * goal, if it exists.
     */
    var goal: Goal? {
        get {
            return goal_
        }
        set {
            goal_ = newValue
        }
    }
}

