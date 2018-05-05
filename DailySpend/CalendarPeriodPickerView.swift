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
    let numDays = 31
    let numWeeks = 52
    let numMonthRows = 12 * 1500
    let numDayRows = 31 * 1000
    
    let gmtCal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = TimeZone(secondsFromGMT: 0)!
        df.dateFormat = "M/d"
        return df
    }()
    let font = UIFont(name: "SFUIDisplay", size: 24.0) ?? UIFont.systemFont(ofSize: 24.0)
    
    var centerZeroMonth: Int {
        return Int(ceil(Double((numMonthRows / 2) / numMonths)) * Double(numMonths))
    }
    var centerZeroDay: Int {
        return Int(ceil(Double((numDayRows / 2) / numDays)) * Double(numDays))
    }
    
    // NSCalendar treats the first week of the year as the first week with any
    // day in a particular year. However, we want to treat the first week of
    // the year as the first week with a Sunday in that year. So we sometimes
    // need to offset by one.
    func weekOffsetForYear(_ year: Int) -> Int {
        let components = DateComponents(weekday: 1, weekOfYear: 1, yearForWeekOfYear: year)
        let date = gmtCal.date(from: components)!
        return CalendarDay(dateInGMTDay: date).year < year ? 1 : 0
    }
    
    var scope: PeriodScope {
        didSet {
            reloadAllComponents()
            updatePickerComponents()
        }
    }
    var value: Date {
        didSet {
            reloadAllComponents()
            updatePickerComponents()
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
            selectRow(centerZeroMonth + dateComponents.month! - 1, inComponent: 0, animated: false)
            selectRow(centerZeroDay + dateComponents.day! - 1, inComponent: 1, animated: false)
            selectRow(dateComponents.year! - startYear, inComponent: 2, animated: false)
        case .Week:
            let componentSet: Set<Calendar.Component> = [.weekOfYear, .yearForWeekOfYear]
            let dateComponents = gmtCal.dateComponents(componentSet, from: self.value)
            let year = dateComponents.yearForWeekOfYear!
            let weekOffset = weekOffsetForYear(year)
            if dateComponents.weekOfYear == 1 && weekOffset == 1 {
                // If there's a week offset, the first week of a year what we
                // consider the last week of the previous year.
                selectRow(numWeeks - 1, inComponent: 0, animated: false)
                selectRow(year - 1 - startYear, inComponent: 1, animated: false)
            } else {
                selectRow(dateComponents.weekOfYear! - weekOffset - 1, inComponent: 0, animated: false)
                selectRow(year - startYear, inComponent: 1, animated: false)
            }
            
        case .Month:
            let componentSet: Set<Calendar.Component> = [.month, .year]
            let dateComponents = gmtCal.dateComponents(componentSet, from: self.value)
            selectRow(centerZeroMonth + dateComponents.month! - 1, inComponent: 0, animated: false)
            selectRow(dateComponents.year! - startYear, inComponent: 1, animated: false)
        case .None: break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func weekNameForNumber(_ weekNumber: Int, in year: Int) -> String {
        let components = DateComponents(weekday: 1, weekOfYear: weekNumber, yearForWeekOfYear: year)
        let date = gmtCal.date(from: components)!
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate
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
                return numMonthRows
            case 1:
                return numDayRows
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
                return numMonthRows
            case 1:
                return numYears
            default:
                return 0
            }
        case .None:
            return 0
        }
    }
    
    func titleForRow(_ row: Int, component: Int) -> String? {
        switch scope {
        case .Day:
            switch component {
            case 0:
                let month = row % numMonths
                return Calendar.current.monthSymbols[month]
            case 1:
                let day = (row % numDays) + 1
                return "\(day)"
            case 2:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .Week:
            switch component {
            case 0:
                let year = day.year
                return "Week of \(weekNameForNumber(row + weekOffsetForYear(year) + 1, in: year))"
            case 1:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .Month:
            switch component {
            case 0:
                let month = row % numMonths
                return Calendar.current.monthSymbols[month]
            case 1:
                return "\(startYear + row)"
            default:
                return ""
            }
        case .None:
            return ""
        }

    }
    
    func isActiveRow(_ row: Int, component: Int) -> Bool {
        return scope != .Day || component != 1 || (row % numDays) + 1 <= month.daysInMonth
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.font = font
        label.textAlignment = scope != .Week && component == 0 ? .natural : .center
        label.text = titleForRow(row, component: component)
        label.textColor = isActiveRow(row, component: component) ? .black : .lightGray
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch scope {
        case .Day:
            let month = selectedRow(inComponent: 0) % numMonths + 1
            var day = selectedRow(inComponent: 1) % numDays + 1
            let year = selectedRow(inComponent: 2) + startYear
            
            // Check to make sure the day is in this month.
            let monthComponents = DateComponents(year: year, month: month)
            let monthDate = gmtCal.date(from: monthComponents)!
            let daysInMonth = gmtCal.range(of: .day, in: .month, for: monthDate)!.count
            day = day > daysInMonth ? daysInMonth : day
            
            // Re-center values
            selectRow(centerZeroDay + day - 1, inComponent: 1, animated: false)
            selectRow(centerZeroMonth + month - 1, inComponent: 1, animated: false)
            
            let dayComponents = DateComponents(year: year, month: month, day: day)
            self.value = gmtCal.date(from: dayComponents)!
        case .Week:
            let year = selectedRow(inComponent: 1) + startYear
            let weekNum = selectedRow(inComponent: 0) + 1 + weekOffsetForYear(year)
            let components = DateComponents(weekday: 1, weekOfYear: weekNum, yearForWeekOfYear: year)
            let date = gmtCal.date(from: components)!
            self.value = date
            if component == 1 {
                reloadComponent(0)
            }
        case .Month:
            let monthNum = selectedRow(inComponent: 0) % numMonths + 1
            let year = selectedRow(inComponent: 1) + startYear
            let components = DateComponents(year: year, month: monthNum)

            selectRow(centerZeroMonth + monthNum - 1, inComponent: 1, animated: false)

            self.value = gmtCal.date(from: components)!
        case .None: break
        }
        calendarPickerDelegate?.changedToDate(date: self.value, scope: self.scope)
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let margin: CGFloat = 25
        switch scope {
        case .Day:
            switch component {
            case 0:
                let longestMonth = Calendar.current.monthSymbols.max { $0.count < $1.count }
                return longestMonth!.calculatedSize(font: font).width + margin
            case 1:
                return "00".calculatedSize(font: font).width + margin
            case 2:
                return "00000".calculatedSize(font: font).width
            default:
                return 0
            }
        case .Week:
            switch component {
            case 0:
                return "Week of 00/00".calculatedSize(font: font).width + margin
            case 1:
                return "00000".calculatedSize(font: font).width
            default:
                return 0
            }
        case .Month:
            switch component {
            case 0:
                let longestMonth = Calendar.current.monthSymbols.max { $0.count < $1.count }
                return longestMonth!.calculatedSize(font: font).width + margin
            case 1:
                return "00000".calculatedSize(font: font).width
            default:
                return 0
            }
        case .None:
            return 0
        }
    }
}
