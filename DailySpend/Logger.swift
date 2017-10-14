//
//  Logger.swift
//  DailySpend
//
//  Created by Josh Sherick on 8/19/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class Logger {
    
    private static func isTesting() -> Bool {
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
            
            if (month.adjustments!.count > 0) {
                print("\tMonthAdjustments:")
            } else {
                print("\tNo MonthAdjustments.")
            }
            for monthAdjustment in month.sortedAdjustments! {
                let created = dateFormatter.string(from: monthAdjustment.dateCreated!)
                let effective = monthAdjustment.calendarDayEffective!.string(formatter: dateFormatter)
                print("\tmonthAdjustment.amount: \(monthAdjustment.amount!)")
                print("\tmonthAdjustment.dateCreated: \(created)")
                print("\tmonthAdjustment.dateEffective: \(effective)")
                print("\tmonthAdjustment.reason: \(monthAdjustment.reason!)")
                print("")
            }
            
            
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
                
                if (day.adjustments!.count > 0) {
                    print("\t\tDayAdjustments:")
                } else {
                    print("\t\tNo DayAdjustments.")
                }
                for dayAdjustment in day.sortedAdjustments! {
                    let created = dateFormatter.string(from: dayAdjustment.dateCreated!)
                    let affected = dayAdjustment.calendarDayAffected!.string(formatter: dateFormatter)
                    print("\t\tdayAdjustment.amount: \(dayAdjustment.amount!)")
                    print("\t\tdayAdjustment.dateAffected: \(created)")
                    print("\t\tdayAdjustment.dateCreated: \(affected)")
                    print("\t\tdayAdjustment.reason: \(dayAdjustment.reason!)")
                    print("")
                }
                
                
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
            }
            print("")
        }
        
        
        let pauseSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        let allPauses = Pause.get(context: context, sortDescriptors: [pauseSortDesc])!

        print("allPauses:")
        print("\(allPauses.count) pauses")
        
        for pause in allPauses {
            
            print("\t\tPause:")
            let created = dateFormatter.string(from: pause.dateCreated!)
            let first = pause.firstDayEffective!.string(formatter: dateFormatter)
            let last = pause.lastDayEffective!.string(formatter: dateFormatter)
            
            print("\t\tpause.shortDescription: \(pause.shortDescription!)")
            print("\t\tpause.dateCreated: \(created)")
            print("\t\tpause.firstDayEffective: \(first)")
            print("\t\tpause.lastDayEffective: \(last)")
            print("")
        }
    }
}
