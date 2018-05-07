//
//  Logger.swift
//  DailySpend
//
//  Created by Josh Sherick on 8/19/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class Logger {
    
    static func isTesting() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier!
        return bundleID.contains("com.joshsherick.DailySpendTesting")
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
        let expenses = Expense.get(context: context,sortDescriptors: [sortDesc])!
        let goals = Goal.get(context: context, sortDescriptors: [sortDesc])!

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
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
            print("\tgoal.dateCreated: \(date(goal.dateCreated))")
            print("\tgoal.adjustMonthAmountAutomatically: \(goal.adjustMonthAmountAutomatically)")
            print("\tgoal.alwaysCarryOver: \(goal.alwaysCarryOver)")
            print("\tgoal.amount: \(String(describing: goal.amount))")
            print("\tgoal.archived: \(goal.archived)")
            print("\tgoal.end: \(date(goal.end))")
            print("\tgoal.hasIncrementalPayment: \(goal.hasIncrementalPayment)")
            print("\tgoal.isRecurring: \(goal.isRecurring)")
            print("\tgoal.payFrequency: \(goal.payFrequency)")
            print("\tgoal.period: \(goal.period)")
            print("\tgoal.shortDescription: \(String(describing: goal.shortDescription))")
            print("\tgoal.start: \(date(goal.start))")
            print("")
        }
        
        if (expenses.count > 0) {
            print("\t\tExpenses:")
        } else {
            print("\t\tNo Expenses.")
        }
        for expense in expenses {
            let created = dateFormatter.string(from: expense.dateCreated!)
            print("\t\texpense.amount: \(expense.amount!)")
            print("\t\texpense.dateCreated: \(created)")
            print("\t\texpense.notes: \(expense.notes ?? "")")
            print("\t\texpense.shortDescription: \(expense.shortDescription!)")
            print("")
            
            if (expense.images!.count > 0) {
                print("\t\t\tImages:")
            } else {
                print("\t\t\tNo Images.")
            }
            for image in expense.sortedImages! {
                let created = dateFormatter.string(from: expense.dateCreated!)
                print("\t\t\timage.imageName: \(image.imageName!)")
                print("\t\t\timage.dateCreated: \(created)")
                print("")
            }
            
            if (expense.goals!.count > 0) {
                print("\t\t\tImages:")
            } else {
                print("\t\t\tNo Images.")
            }
            for image in expense.sortedImages! {
                let created = dateFormatter.string(from: expense.dateCreated!)
                print("\t\t\timage.imageName: \(image.imageName!)")
                print("\t\t\timage.dateCreated: \(created)")
                print("")
            }

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
            print("Adjustment:")
            let created = dateFormatter.string(from: adjustment.dateCreated!)
            let first = adjustment.firstDayEffective!.string(formatter: dateFormatter)
            let last = adjustment.lastDayEffective!.string(formatter: dateFormatter)
            
            print("adjustment.amountPerDay: \(adjustment.amountPerDay!)")
            print("adjustment.shortDescription: \(adjustment.shortDescription!)")
            print("adjustment.dateCreated: \(created)")
            print("adjustment.firstDayEffective: \(first)")
            print("adjustment.lastDayEffective: \(last)")
            print("")
        }
    }
}
