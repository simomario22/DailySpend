//
//  Logger.swift
//  DailySpend
//
//  Created by Josh Sherick on 8/19/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class Logger {

    static var _isTesting: Bool?
    private static func isTesting() -> Bool {
        if _isTesting != nil {
            return _isTesting!
        }

        guard let bundleID = Bundle.main.bundleIdentifier else {
            return false
        }
        
        _isTesting = bundleID.contains("com.joshsherick.DailySpendTesting")
        return _isTesting!
    }

    private static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        return dateFormatter
    }

    static func debug(_ message: String) {
        if isTesting() {
            print(message)
        }
    }
    
    static func warning(_ message: String) {
        print(message)
    }

    static func printAllCoreData() {
        if !isTesting() {
            return
        }
        
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        let context = appDelegate.persistentContainer.viewContext
        
        let sortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        let expenses = Expense.get(context: context, sortDescriptors: [sortDesc])!
        let goals = Goal.get(context: context, sortDescriptors: [sortDesc])!

        func date(_ d: Date?) -> String {
            if let u = d {
                return dateFormatter.string(from: u)
            } else {
                return "nil"
            }
        }
        
        if (goals.count > 0) {
            print("Goals:")
        } else {
            print("No Goals.")
        }
        for goal in goals {
            print("goal.dateCreated: \(date(goal.dateCreated))")
            print("goal.adjustMonthAmountAutomatically: \(goal.adjustMonthAmountAutomatically)")
            print("goal.alwaysCarryOver: \(goal.alwaysCarryOver)")
            print("goal.amount: \(String(describing: goal.amount))")
            print("goal.start: \(String(describing: goal.start!.string(formatter: dateFormatter)))")
            print("goal.end: \(String(describing: goal.end?.string(formatter: dateFormatter)))")
            print("goal.hasIncrementalPayment: \(goal.hasIncrementalPayment)")
            print("goal.isRecurring: \(goal.isRecurring)")
            print("goal.payFrequency: \(goal.payFrequency)")
            print("goal.period: \(goal.period)")
            print("goal.shortDescription: \(String(describing: goal.shortDescription))")
            print("goal.isArchived: \(goal.isArchived)")
            print("goal.hasFutureStart: \(goal.hasFutureStart)")
            print("goal.parentGoal: \(String(describing: goal.parentGoal?.shortDescription))")
            print("")
        }
        
        if (expenses.count > 0) {
            print("Expenses:")
        } else {
            print("No Expenses.")
        }
        for expense in expenses {
            let created = dateFormatter.string(from: expense.dateCreated!)
            print("expense.amount: \(expense.amount!)")
            print("expense.dateCreated: \(created)")
            print("expense.transactionDay: \(String(describing: expense.transactionDay!.string(formatter: dateFormatter)))")
            print("expense.notes: \(String(describing: expense.notes))")
            print("expense.shortDescription: \(String(describing: expense.shortDescription))")
            print("expense.goal: \(String(describing: expense.goal!.shortDescription))")
            
            if (expense.images!.count > 0) {
                print("\tImages:")
            } else {
                print("\tNo Images.")
            }
            for image in expense.sortedImages! {
                let created = dateFormatter.string(from: expense.dateCreated!)
                print("\timage.imageName: \(image.imageName!)")
                print("\timage.dateCreated: \(created)")
                print("")
            }
            
            if (expense.goal != nil) {
                print("\tGoal: \(expense.goal!.shortDescription!)")
            } else {
                print("\tNo Goals.")
            }
            print("")
        }
        print("")
        
        let pauseSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        let allPauses = Pause.get(context: context, sortDescriptors: [pauseSortDesc])!

        print("allPauses:")
        print("\(allPauses.count) pauses")
        
        for pause in allPauses {
            
            print("Pause:")
            let created = dateFormatter.string(from: pause.dateCreated!)
            let first = pause.firstDayEffective!.string(formatter: dateFormatter)
            let last = pause.lastDayEffective!.string(formatter: dateFormatter)
            
            print("pause.shortDescription: \(pause.shortDescription!)")
            print("pause.dateCreated: \(created)")
            print("pause.firstDayEffective: \(first)")
            print("pause.lastDayEffective: \(last)")
            print("")
        }
        
        
        let adjustmentSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        let allAdjustments = Adjustment.get(context: context, sortDescriptors: [adjustmentSortDesc])!
        
        print("allAdjustments:")
        print("\(allAdjustments.count) adjustments")
        
        for adjustment in allAdjustments {
            if adjustment.firstDayEffective == nil {
                context.delete(adjustment)
                try? context.save()
                continue
            }
            printAdjustment(adjustment)
        }
    }

    static func printAdjustment(_ adjustment: Adjustment) {
        if !isTesting() {
            return
        }

        print("Adjustment:")
        let created = dateFormatter.string(from: adjustment.dateCreated!)
        let first = adjustment.firstDayEffective!.string(formatter: dateFormatter)
        let last = adjustment.lastDayEffective!.string(formatter: dateFormatter)

        print("adjustment.amountPerDay: \(adjustment.amountPerDay!)")
        print("adjustment.shortDescription: \(String(describing: adjustment.shortDescription))")
        print("adjustment.dateCreated: \(created)")
        print("adjustment.firstDayEffective: \(first)")
        print("adjustment.lastDayEffective: \(last)")
        print("adjustment.type: \(adjustment.type)")
        print("adjustment.goal: \(String(describing: adjustment.goal!.shortDescription))")

    }
}
