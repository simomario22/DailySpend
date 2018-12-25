//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class CalendarPeriodPickerTableViewCell: UITableViewCell, CalendarPeriodPickerViewDelegate {
    var periodPicker: CalendarPeriodPickerView!
    
    private var changedCallback: ((CalendarDateProvider, PeriodScope) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if periodPicker != nil {
            periodPicker.frame = bounds
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        periodPicker = CalendarPeriodPickerView()
        self.addSubview(periodPicker)
        periodPicker.calendarPickerDelegate = self
        
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func changedToDate(date: CalendarDateProvider, scope: PeriodScope) {
        changedCallback?(date, scope)
    }
    
    func setCallback(_ cb: @escaping ((CalendarDateProvider, PeriodScope) -> ())) {
        changedCallback = cb
    }
}
