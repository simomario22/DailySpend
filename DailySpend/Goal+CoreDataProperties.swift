//
//  Goal+CoreDataProperties.swift
//  DailySpend
//
//  Created by Josh Sherick on 2/12/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import Foundation
import CoreData

extension Goal {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Goal> {
        return NSFetchRequest<Goal>(entityName: "Goal")
    }

    @NSManaged var carryOverBalance_: Bool
    @NSManaged var dateCreated_: NSDate?
    @NSManaged var shortDescription_: String?
    @NSManaged var adjustments_: NSSet?
    @NSManaged var expenses_: NSSet?
    @NSManaged var pauses_: NSSet?
    @NSManaged var parentGoal_: Goal?
    @NSManaged var childGoals_: NSSet?
    @NSManaged var paySchedules_: NSSet?
}

/**
 * To be deleted once migration to pay schedules is complete.
 */
extension Goal {
    @NSManaged var amount_: NSDecimalNumber?
    @NSManaged var adjustMonthAmountAutomatically_: Bool
    @NSManaged var end_: NSDate?
    @NSManaged var period_: Int64
    @NSManaged var payFrequency_: Int64
    @NSManaged var payFrequencyMultiplier_: Int64
    @NSManaged var start_: NSDate?
    @NSManaged var periodMultiplier_: Int64

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
        return CalendarDay(dateInDay: end).end
    }

    var amount: Decimal? {
        get {
            return amount_ as Decimal?
        }
        set {
            if newValue != nil {
                amount_ = NSDecimalNumber(decimal: newValue!.roundToNearest(th: 100))
            } else {
                amount_ = nil
            }
        }
    }
}

// MARK: Generated accessors for adjustments_
extension Goal {

    @objc(addAdjustments_Object:)
    @NSManaged func addToAdjustments_(_ value: Adjustment)

    @objc(removeAdjustments_Object:)
    @NSManaged func removeFromAdjustments_(_ value: Adjustment)

    @objc(addAdjustments_:)
    @NSManaged func addToAdjustments_(_ values: NSSet)

    @objc(removeAdjustments_:)
    @NSManaged func removeFromAdjustments_(_ values: NSSet)

}

// MARK: Generated accessors for expenses_
extension Goal {

    @objc(addExpenses_Object:)
    @NSManaged func addToExpenses_(_ value: Expense)

    @objc(removeExpenses_Object:)
    @NSManaged func removeFromExpenses_(_ value: Expense)

    @objc(addExpenses_:)
    @NSManaged func addToExpenses_(_ values: NSSet)

    @objc(removeExpenses_:)
    @NSManaged func removeFromExpenses_(_ values: NSSet)

}

// MARK: Generated accessors for pauses_
extension Goal {

    @objc(addPauses_Object:)
    @NSManaged func addToPauses_(_ value: Pause)

    @objc(removePauses_Object:)
    @NSManaged func removeFromPauses_(_ value: Pause)

    @objc(addPauses_:)
    @NSManaged func addToPauses_(_ values: NSSet)

    @objc(removePauses_:)
    @NSManaged func removeFromPauses_(_ values: NSSet)

}

// MARK: Generated accessors for childGoals_
extension Goal {

    @objc(addChildGoals_Object:)
    @NSManaged func addToChildGoals_(_ value: Goal)

    @objc(removeChildGoals_Object:)
    @NSManaged func removeFromChildGoals_(_ value: Goal)

    @objc(addChildGoals_:)
    @NSManaged func addToChildGoals_(_ values: NSSet)

    @objc(removeChildGoals_:)
    @NSManaged func removeFromChildGoals_(_ values: NSSet)

}
