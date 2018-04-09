//
//  TableViewCellHelpers.swift
//  DailySpend
//
//  Created by Josh Sherick on 10/29/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class TableViewCellHelper {
    
    var tableView: UITableView
    var view: UIView
    var dateFormatter: DateFormatter
    
    init(tableView: UITableView, view: UIView, dateFormatter: DateFormatter? = nil) {
        self.tableView = tableView
        self.view = view
        
        if let dateFormatter = dateFormatter {
            self.dateFormatter = dateFormatter
        } else {
            self.dateFormatter = DateFormatter()
            self.dateFormatter.dateFormat = "E, MMM d, yyyy"
        }
    }
    
    /**
     * Return a cell to format and display a CalendarDay.
     */
    public func dateDisplayCell(label: String,
                         day: CalendarDay?,
                         tintDetailText: Bool = false,
                         strikeText: Bool = false,
                         alternateText: String? = nil) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "dateDisplay")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "dateDisplay")
        }

        let dateText = day?.string(formatter: dateFormatter, friendly: true) ?? alternateText ?? "None"
        
        return valueDisplayCell(labelText: label,
                                valueText: dateText,
                                tintDetailText: tintDetailText,
                                strikeText: strikeText)
    }
    
    /**
     * Cell to display a label and a value, which can be tinted or crossed out.
     */
    public func valueDisplayCell(labelText: String,
                                 valueText: String,
                                 explanatoryText: String? = nil,
                                tintDetailText: Bool = false,
                                strikeText: Bool = false) -> UITableViewCell {
        var cell: ValueTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "valueDisplay") as? ValueTableViewCell
        if cell == nil {
            cell = ValueTableViewCell(style: .value1, reuseIdentifier: "valueDisplay")
        }
        
        cell.textLabel!.text = labelText
        cell.setExplanatoryText(explanatoryText)
        
        let attributedText = NSMutableAttributedString(string: valueText)
        let attr: [NSAttributedStringKey: Any] = [
            .foregroundColor: tintDetailText ? view.tintColor : UIColor.black,
            .strikethroughColor: tintDetailText ? view.tintColor : UIColor.black,
            // NSUnderlineStyle.styleNone and .styleSingle weren't working, so
            // I am using literal number values. Should be changed if there is
            // a better way.
            .strikethroughStyle: strikeText ? NSNumber(integerLiteral: 1) : NSNumber(integerLiteral: 0)
        ]
        attributedText.addAttributes(attr, range: NSMakeRange(0, valueText.count))
        cell.detailTextLabel!.attributedText = attributedText
        
        cell.valueWasSet()
        
        return cell
    }

    
    /**
     * Return a cell with an editable text field.
     */
    public func textFieldDisplayCell(title: String? = nil,
                              placeholder: String,
                              text: String?,
                              explanatoryText: String? = nil,
                              keyboardType: UIKeyboardType = .default,
                              changedToText: @escaping (String, UITextField) -> (),
                              didBeginEditing: ((UITextField) -> ())? = nil,
                              didEndEditing: ((UITextField) -> ())? = nil) -> UITableViewCell {
        var cell: TextFieldTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "textFieldDisplay") as? TextFieldTableViewCell
        if cell == nil {
            cell = TextFieldTableViewCell(style: .default, reuseIdentifier: "textFieldDisplay")
        }
        
        cell.textField.placeholder = placeholder
        cell.textField.text = text == "" ? nil : text
        cell.textField.keyboardType = keyboardType
        cell.textLabel?.text = title
        cell.setHasTitle(title != nil)
        cell.setExplanatoryText(explanatoryText)
        cell.setBeginEditingCallback(didBeginEditing)
        cell.setEndEditingCallback(didEndEditing)
        cell.setChangedCallback { (textField: UITextField) in
            let text = textField.text
            changedToText(text!, textField)
        }
        
        return cell
    }

    /**
     * Return a cell with an editable text field.
     */
    public func currencyDisplayCell(title: String? = nil,
                                     amount: Decimal? = nil,
                                     changedToAmount: @escaping (Decimal?) -> (),
                                     didBeginEditing: ((UITextField) -> ())? = nil,
                                     didEndEditing: ((UITextField) -> ())? = nil) -> UITableViewCell {
        var cell: TextFieldTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "currencyDisplay") as? TextFieldTableViewCell
        if cell == nil {
            cell = TextFieldTableViewCell(style: .default, reuseIdentifier: "currencyDisplay")
        }

        cell.setCalculatorTextField(true)
        cell.textField.placeholder = "$0"
        cell.textField.text = amount != nil ? String.formatAsCurrency(amount: amount!) : nil
        cell.textLabel?.text = title
        cell.setHasTitle(title != nil)
        cell.setExplanatoryText(nil)
        cell.setChangedEvaluatedValueCallback { (_, newValue) in
            changedToAmount(newValue)
        }
        cell.setBeginEditingCallback(didBeginEditing)
        cell.setEndEditingCallback(didEndEditing)
        (cell.textField as! CalculatorTextField).maxValue = 1e7
        return cell
    }
    
    /**
     * Return a cell with a segmented control.
     */
    public func segmentedControlCell(segmentTitles: [String],
                              selectedSegmentIndex: Int,
                              title: String? = nil,
                              explanatoryText: String? = nil,
                              changedToIndex: @escaping (Int) -> ()) -> UITableViewCell {
        var cell: SegmentedControlTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "segmentedControlDisplay") as? SegmentedControlTableViewCell
        if cell == nil {
            cell = SegmentedControlTableViewCell(style: .default, reuseIdentifier: "segmentedControlDisplay")
        }
        
        cell.textLabel?.text = title
        cell.setHasTitle(title != nil)
        cell.setExplanatoryText(explanatoryText)
        cell.setSegmentTitles(segmentTitles)
        cell.segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        cell.setChangedCallback { (control: UISegmentedControl) in
            let index = control.selectedSegmentIndex
            changedToIndex(index)
        }
        
        return cell
    }
    
    /**
     * Return a cell with a segmented control.
     */
    public func switchCell(initialValue: Bool,
                           title: String? = nil,
                           explanatoryText: String? = nil,
                           valueChanged: @escaping (Bool) -> ()) -> UITableViewCell {
        var cell: SwitchTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "switchDisplay") as? SwitchTableViewCell
        if cell == nil {
            cell = SwitchTableViewCell(style: .default, reuseIdentifier: "switchDisplay")
        }
        
        cell.textLabel?.text = title
        cell.setHasTitle(title != nil)
        cell.setExplanatoryText(explanatoryText)
        cell.setSwitchValue(initialValue)
        cell.setChangedCallback { (control: UISwitch) in
            valueChanged(control.isOn)
        }
        
        return cell
    }

    
    /**
     * Return a cell with a date picker.
     */
    public func datePickerCell(day: CalendarDay,
                        changedToDay: @escaping (CalendarDay) -> ()) -> UITableViewCell {
        var cell: DatePickerTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "datePicker") as? DatePickerTableViewCell
        if cell == nil {
            cell = DatePickerTableViewCell(style: .default, reuseIdentifier: "datePicker")
        }
        
        cell.datePicker.datePickerMode = .date
        cell.datePicker.timeZone = CalendarDay.gmtTimeZone
        cell.datePicker.setDate(day.gmtDate, animated: false)
        cell.setCallback { (datePicker: UIDatePicker) in
            let day = CalendarDay(dateInGMTDay: datePicker.date)
            changedToDay(day)
        }
        
        return cell
    }

    /**
     * Return a cell with a date picker.
     */
    public func periodPickerCell(date: Date,
                                 scope: PeriodScope,
                                 changedToDate: @escaping (Date, PeriodScope) -> ()) -> UITableViewCell {
        var cell: CalendarPeriodPickerTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "periodPicker") as? CalendarPeriodPickerTableViewCell
        if cell == nil {
            cell = CalendarPeriodPickerTableViewCell(style: .default, reuseIdentifier: "periodPicker")
        }
        
        cell.periodPicker.value = date
        cell.periodPicker.scope = scope
        cell.setCallback { (date: Date, scope: PeriodScope) in
            changedToDate(date, scope)
        }
        
        return cell
    }

    
    /**
     * Return a cell with a picker.
     */
    public func pickerCell(rows: [[String]],
                           initialSelection: [Int]?,
                           changedValues: @escaping ([String]) -> ()) -> UITableViewCell {
        var cell: PickerTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "picker") as? PickerTableViewCell
        if cell == nil {
            cell = PickerTableViewCell(style: .default, reuseIdentifier: "picker")
        }
        cell.setRows(rows)
        if let selection = initialSelection {
            for (i, row) in selection.enumerated() {
                cell.picker.selectRow(row, inComponent: i, animated: false)
            }
        } else if !rows.isEmpty && !rows[0].isEmpty {
            cell.picker.selectRow(0, inComponent: 0, animated: false)
        }
        
        cell.setCallback { (pickerView) in
            var values = [String]()
            for component in 0..<rows.count {
                let selected = pickerView.selectedRow(inComponent: component)
                values.append(rows[component][selected])
            }
            changedValues(values)
        }
        
        return cell
    }
    
    /**
     * Return a cell with a date picker.
     */
    public func expenseCell(expense: Expense?,
                           day: CalendarDay,
                           addedExpense: @escaping (_ shortDescription: String, _ amount: Decimal) -> (),
                           selectedDetailDisclosure: @escaping () -> (),
                           beganEditing: @escaping (_ newHeight: Int) -> (),
                           endedEditing: @escaping (_ newHeight: Int) -> ()) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "addExpense")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "addExpense")
        }
        
        return cell
    }

}
