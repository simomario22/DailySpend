//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class DatePickerTableViewCell: UITableViewCell {
    var datePicker: UIDatePicker!
    
    private var changedCallback: ((UIDatePicker) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if datePicker != nil {
            datePicker.frame = bounds
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        datePicker = UIDatePicker()

        self.addSubview(datePicker)
        datePicker.addTarget(self, action: #selector(datePickerChanged(picker:)),
                             for: .valueChanged)
        
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func datePickerChanged(picker: UIDatePicker!) {
        changedCallback?(picker)
    }
    
    func setCallback(_ cb: @escaping ((UIDatePicker) -> ())) {
        changedCallback = cb
    }
}
