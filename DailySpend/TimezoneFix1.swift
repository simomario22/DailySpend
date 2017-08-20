//
//  TimezoneFix1.swift
//  DailySpend
//
//  Created by Josh Sherick on 8/19/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class TimezoneFix1 {
    static let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    static var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    static func fix() {
        fixDayAdjustments()
        fixMonthAdjustments()
        fixDays()
        fixMonths()
    }
    
    static func closestAmongDayBeforeAndAfter(to date: Date) -> Date {
        let systemCal = Calendar(identifier: .gregorian)
        
        // Create the day containing the date.
        let dayContainingDate = systemCal.startOfDay(for: date)
        
        // Create the day before the day containing the date.
        var dayBeforeDate = systemCal.date(byAdding: .day, value: -1, to: dayContainingDate)!
        dayBeforeDate = systemCal.startOfDay(for: dayBeforeDate)
        
        // Create the day after the day containing the date.
        var dayAfterDate = systemCal.date(byAdding: .day, value: 1, to: dayContainingDate)!
        dayAfterDate = systemCal.startOfDay(for: dayAfterDate)
        
        return closest(to: date, in: [dayContainingDate, dayBeforeDate, dayAfterDate])
    }
    
    static func closest(to date: Date, in dates: [Date]) -> Date {
        var closest = dates.first!
        var closestInterval = abs(date.timeIntervalSince(dates.first!))
        for candidate in dates {
            let interval = abs(date.timeIntervalSince(candidate))
            if interval < closestInterval {
                closest = candidate
                closestInterval = interval
            }
        }
        return closest
    }
}

extension TimezoneFix1 {
    static func fixMonths() {
        var months = getAllMonths()
        // Fix each month's month_ property.
        for month in months {
            // Fix this Month if its month_ isn't set properly.
            if needsFix(month: month) {
                // This needs to be fixed.
                fix(month: month)
            }
        }
        appDelegate.saveContext()
        
        // Merge any months that are now the same month.
        months = getAllMonths()
        while let month = months.popLast() {
            let duplicateMonths = getMonths(calMonth: month.calendarMonth!)
            if duplicateMonths.count > 1 {
                // There are duplicates. Merge them.
                merge(months: duplicateMonths)
                
                // Save the context and reset the months array.
                appDelegate.saveContext()
                months = getAllMonths()
            }
        }
    }
    
    private static func needsFix(month: Month) -> Bool {
        return month.month_! as Date != month.calendarMonth!.gmtDate
    }
    
    private static func fix(month: Month) {
        let date = month.month_! as Date
        let systemCal = Calendar(identifier: .gregorian)
        
        let componentSet: Set<Calendar.Component> = [.year, .month, .day]
        
        // Create the month containing the date.
        var dateComponents = systemCal.dateComponents(componentSet, from: date)
        dateComponents.setValue(1, for: .day)
        let monthContainingDate = systemCal.startOfDay(for: systemCal.date(from: dateComponents)!)
        
        // Create the month before the month containing the date.
        var monthBeforeDate = systemCal.date(byAdding: .month, value: -1, to: monthContainingDate)!
        monthBeforeDate = systemCal.startOfDay(for: monthBeforeDate)
        
        // Create the month after the month containing the date.
        var monthAfterDate = systemCal.date(byAdding: .month, value: 1, to: monthContainingDate)!
        monthAfterDate = systemCal.startOfDay(for: monthAfterDate)
        
        let closestDate = closest(to: date,
                                  in: [monthContainingDate, monthBeforeDate, monthAfterDate])
        
        month.calendarMonth = CalendarMonth(dateInLocalMonth: closestDate)
    }
    
    private static func merge(months: [Month]) {
        var monthsToMerge = months
        let realMonth = monthsToMerge.popLast()!
        
        while let month = monthsToMerge.popLast() {
            for day in month.days! {
                day.month = realMonth
            }
            for monthAdjustment in month.adjustments! {
                monthAdjustment.month = realMonth
            }
            context.delete(month)
        }
    }
    
    private static func getMonths(calMonth: CalendarMonth) -> [Month] {
        let allMonths = getAllMonths()
        var months = [Month]()
        for month in allMonths {
            if month.calendarMonth == calMonth {
                months.append(month)
            }
        }
        return months
    }
    
    private static func getAllMonths() -> [Month] {
        let fetchRequest: NSFetchRequest<Month> = Month.fetchRequest()
        return try! context.fetch(fetchRequest)
    }
}

extension TimezoneFix1 {
    static func fixDays() {
        var days = getAllDays()
        // Fix each day's date_ property.
        for day in days {
            // Fix this Day if its date_ isn't set properly.
            if needsFix(day: day) {
                // This needs to be fixed.
                fix(day: day)
            }
        }
        appDelegate.saveContext()
        
        // Merge any days that are now the same day.
        days = getAllDays()
        while let day = days.popLast() {
            let duplicateDays = getDays(calDay: day.calendarDay!)
            if duplicateDays.count > 1 {
                // There are duplicates. Merge them.
                merge(days: duplicateDays)
                
                // Save the context and reset the months array.
                appDelegate.saveContext()
                days = getAllDays()
            }
        }
    }
    
    private static func getDays(calDay: CalendarDay) -> [Day] {
        let allDays = getAllDays()
        var days = [Day]()
        for day in allDays {
            if day.calendarDay == calDay {
                days.append(day)
            }
        }
        return days
    }
    
    private static func getAllDays() -> [Day] {
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        return try! context.fetch(fetchRequest)
    }
    
    private static func needsFix(day: Day) -> Bool {
        return day.date_! as Date != day.calendarDay!.gmtDate
    }
    
    private static func fix(day: Day) {
        let closestDate = closestAmongDayBeforeAndAfter(to: day.date_! as Date)
        
        day.calendarDay = CalendarDay(dateInLocalDay: closestDate)
    }
    
    private static func merge(days: [Day]) {
        var daysToMerge = days
        let realDay = daysToMerge.popLast()!
        
        while let day = daysToMerge.popLast() {
            for expense in day.expenses! {
                expense.day = realDay
            }
            for dayAdjustment in day.adjustments! {
                dayAdjustment.day = realDay
            }
            context.delete(day)
        }
    }
}

extension TimezoneFix1 {
    static func fixDayAdjustments() {
        let dayAdjustments = getAllDayAdjustments()
        // Fix each day adjustments's date_ property.
        for dayAdjustment in dayAdjustments {
            // Fix this Day if its date_ isn't set properly.
            if needsFix(dayAdjustment: dayAdjustment) {
                // This needs to be fixed.
                fix(dayAdjustment: dayAdjustment)
            }
        }
        appDelegate.saveContext()
    }
    
    private static func getAllDayAdjustments() -> [DayAdjustment] {
        let fetchRequest: NSFetchRequest<DayAdjustment> = DayAdjustment.fetchRequest()
        return try! context.fetch(fetchRequest)
    }
    
    private static func needsFix(dayAdjustment: DayAdjustment) -> Bool {
        return dayAdjustment.dateAffected_! as Date != dayAdjustment.calendarDayAffected!.gmtDate
    }
    
    private static func fix(dayAdjustment: DayAdjustment) {
        let date = dayAdjustment.dateAffected_! as Date
        let closestDate = closestAmongDayBeforeAndAfter(to: date)
        dayAdjustment.calendarDayAffected = CalendarDay(dateInLocalDay: closestDate)
    }
}

extension TimezoneFix1 {
    static func fixMonthAdjustments() {
        let monthAdjustments = getAllMonthAdjustments()
        // Fix each day adjustments's date_ property.
        for monthAdjustment in monthAdjustments {
            // Fix this Day if its date_ isn't set properly.
            if needsFix(monthAdjustment: monthAdjustment) {
                // This needs to be fixed.
                fix(monthAdjustment: monthAdjustment)
            }
        }
        appDelegate.saveContext()
    }
    
    private static func getAllMonthAdjustments() -> [MonthAdjustment] {
        let fetchRequest: NSFetchRequest<MonthAdjustment> = MonthAdjustment.fetchRequest()
        return try! context.fetch(fetchRequest)
    }
    
    private static func needsFix(monthAdjustment: MonthAdjustment) -> Bool {
        return monthAdjustment.dateEffective_! as Date != monthAdjustment.calendarDayEffective!.gmtDate
    }
    
    private static func fix(monthAdjustment: MonthAdjustment) {
        let date = monthAdjustment.dateEffective_! as Date
        let closestDate = closestAmongDayBeforeAndAfter(to: date)
        monthAdjustment.calendarDayEffective = CalendarDay(dateInLocalDay: closestDate)
    }
}
