//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class PickerTableViewCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {

    var picker: UIPickerView!
    
    private var changedCallback: ((UIPickerView) -> ())?
    var rows = [[String]]()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if picker != nil {
            picker.frame = bounds
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        picker = UIPickerView()
        picker.showsSelectionIndicator = true
        picker.dataSource = self
        picker.delegate = self
        self.addSubview(picker)
        
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return rows[component][row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        changedCallback?(pickerView)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return rows.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return rows[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }

    func setCallback(_ cb: @escaping ((UIPickerView) -> ())) {
        changedCallback = cb
    }
    
    func setRows(_ r: [[String]]) {
        rows = r
    }

}
