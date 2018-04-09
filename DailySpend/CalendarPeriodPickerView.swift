//
//  CalendarPeriodPickerView.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/2/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

protocol CalendarPeriodPickerViewDelegate {
    func changedToDate(date: Date, scope: PeriodScope)
}

class CalendarPeriodPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    let startYear = 1
    let numYears = 10000
    let numMonths = 12
    let numWeeks = 52
    let gmtCal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = TimeZone(secondsFromGMT: 0)!
        df.dateStyle = .short
        return df
    }()
    
    var scope: PeriodScope {
        didSet {
            updatePickerComponents()
            reloadAllComponents()
        }
    }
    var value: Date {
        didSet {
            updatePickerComponents()
            reloadAllComponents()
        }
    }
    
    var calendarPickerDelegate: CalendarPeriodPickerViewDelegate?
    
    var day: CalendarDay {
        return CalendarDay(dateInGMTDay: value)
    }
    
    var week: CalendarWeek {
        return CalendarWeek(dateInGMTWeek: value)
    }
    
    var month: CalendarMonth {
        return CalendarMonth(dateInGMTMonth: value)
    }

    init() {
        self.value = Date()
        self.scope = .Day
        super.init(frame: CGRect.zero)
        self.delegate = self
        self.dataSource = self
        updatePickerComponents()
    }
    
    func updatePickerComponents() {
        switch scope {
        case .Day:
            let componentSet: Set<Calendar.Component> = [.day, .month, .year]
            let dateComponents = gmtCal.dateComponents(componentSet, from: self.value)
            selectRow(dateComponents.month! - 1, inComponent: 0, animated: false)
            selectRow(dateComponents.day! - 1, inComponent: 1, animated: false)
            selectRow(dateComponents.year! - startYear, inComponent: 2, animated: false)
        case .Week:
            let componentSet: Set<Calendar.Component> = [.weekOfYear, .year]
            let dateComponents = gmtCal.dateComponents(componentSet, from: self.value)
            selectRow(dateComponents.weekOfYear! - 1, inComponent: 0, animated: false)
            selectRow(dateComponents.year! - startYear, inComponent: 1, animated: false)
        case .Month:
            let componentSet: Set<Calendar.Component> = [.month, .year]
            let dateComponents = gmtCal.dateComponents(componentSet, from: self.value)
            selectRow(dateComponents.month! - 1, inComponent: 0, animated: false)
            selectRow(dateComponents.year! - startYear, inComponent: 1, animated: false)
        case .None: break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func weekNameForNumber(_ weekNumber: Int, in year: Int) -> String {
        let components = DateComponents(year: year, weekday: 1, weekOfYear: weekNumber)
        let date = gmtCal.date(from: components)!
        return dateFormatter.string(from: date)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch scope {
        case .Day:
            return 3
        case .Week, .Month:
            return 2
        case .None:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch scope {
        case .Day:
            switch component {
            case 0:
                return numMonths
            case 1:
                return month.daysInMonth
            case 2:
                return numYears
            default:
                return 0
            }
        case .Week:
            switch component {
            case 0:
                return numWeeks
            case 1:
                return numYears
            default:
                return 0
            }
        case .Month:
            switch component {
            case 0:
                return numMonths
            case 1:
                return numYears
            default:
                return 0
            }
        case .None:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch scope {
        case .Day:
            switch component {
            case 0:
                return Calendar.current.monthSymbols[row]
            case 1:
                return "\(row + 1)"
            case 2:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .Week:
            switch component {
            case 0:
                return "Week of \(weekNameForNumber(row + 1, in: day.year))"
            case 1:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .Month:
            switch component {
            case 0:
                return Calendar.current.monthSymbols[row]
            case 1:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .None:
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch scope {
        case .Day:
            let month = selectedRow(inComponent: 0) + 1
            let day = selectedRow(inComponent: 1) + 1
            let year = selectedRow(inComponent: 2) + startYear
            let components = DateComponents(year: year, month: month, day: day)
            self.value = gmtCal.date(from: components)!
            if component == 1 {
                reloadComponent(0)
            }
        case .Week:
            let weekNum = selectedRow(inComponent: 0) + 1
            let year = selectedRow(inComponent: 1) + startYear
            let components = DateComponents(year: year, weekday: 1, weekOfYear: weekNum)
            self.value = gmtCal.date(from: components)!
            if component == 1 {
                reloadComponent(0)
            }
        case .Month:
            let monthNum = selectedRow(inComponent: 0) + 1
            let year = selectedRow(inComponent: 1) + startYear
            let components = DateComponents(year: year, month: monthNum)
            self.value = gmtCal.date(from: components)!
        case .None: break
        }
        calendarPickerDelegate?.changedToDate(date: self.value, scope: self.scope)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        <#code#>
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let width = self.frame.size.width
        let font = UIFont(name: "SFUIDisplay", size: 21.0)
        switch scope {
        case .Day:
            switch component {
            case 0:
                let longestMonth = Calendar.current.monthSymbols.max { $0.count < $1.count }
                longestMonth.
                return
            case 1:
                return "\(row + 1)"
            case 2:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .Week:
            switch component {
            case 0:
                return "Week of \(weekNameForNumber(row + 1, in: day.year))"
            case 1:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .Month:
            switch component {
            case 0:
                return Calendar.current.monthSymbols[row]
            case 1:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .None:
            return ""
        }
    }
}
