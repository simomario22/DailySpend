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
        
        let sortDesc = NSSortDescriptor(key: "month_", ascending: true)
        let allMonths = Month.get(context: context, sortDescriptors: [sortDesc])!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        
        
        for (index, month) in allMonths.enumerated() {
            print("allMonths[\(index)]")
            
            let humanMonth = dateFormatter.monthSymbols[month.calendarMonth!.month - 1]
            let humanMonthYear = humanMonth + " \(month.calendarMonth!.year)"
            
            let fullDate = month.calendarMonth!.string(formatter: dateFormatter)
            
            print("\(humanMonthYear) - \(fullDate)")
            print("month.dailyBaseTargetSpend: \(month.dailyBaseTargetSpend!)")
            print("month.dateCreated: \(dateFormatter.string(from: month.dateCreated!))")
            print("")
            
            if (month.days!.count > 0) {
                print("\tDays:")
            } else {
                print("\tNo Days.")
            }
            for day in month.sortedDays! {
                print("\tday.baseTargetSpend: \(day.baseTargetSpend!)")
                print("\tday.date: \(day.calendarDay!.string(formatter: dateFormatter))")
                print("\tday.dateCreated: \(dateFormatter.string(from: day.dateCreated!))")
                print("")
                
                if (day.expenses!.count > 0) {
                    print("\t\tExpenses:")
                } else {
                    print("\t\tNo Expenses.")
                }
                for expense in day.sortedExpenses! {
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
                }
                print("")
                
                if let pause = day.pause {
                    print("\t\tPause:")
                    let created = dateFormatter.string(from: pause.dateCreated!)
                    let first = pause.firstDayEffective!.string(formatter: dateFormatter)
                    let last = pause.lastDayEffective!.string(formatter: dateFormatter)
                    
                    print("\t\tpause.shortDescription: \(pause.shortDescription!)")
                    print("\t\tpause.dateCreated: \(created)")
                    print("\t\tpause.firstDayEffective: \(first)")
                    print("\t\tpause.lastDayEffective: \(last)")
                    print("")
                    
                } else {
                    print("\t\tNo Pause.")
                }
                print("")
                
                if (day.adjustments!.count > 0) {
                    print("\t\tAdjustments:")
                } else {
                    print("\t\tNo Adjustments.")
                }
                for adjustment in day.sortedAdjustments! {
                    print("\t\tAdjustment:")
                    let created = dateFormatter.string(from: adjustment.dateCreated!)
                    let first = adjustment.firstDayEffective!.string(formatter: dateFormatter)
                    let last = adjustment.lastDayEffective!.string(formatter: dateFormatter)
                    
                    print("\t\tadjustment.amountPerDay: \(adjustment.amountPerDay!)")
                    print("\t\tadjustment.shortDescription: \(adjustment.shortDescription!)")
                    print("\t\tadjustment.dateCreated: \(created)")
                    print("\t\tadjustment.firstDayEffective: \(first)")
                    print("\t\tadjustment.lastDayEffective: \(last)")
                    print("")
                    
                }
                print("")
            }
            print("")
        }
        
        
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
