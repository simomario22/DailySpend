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
                         day: CalendarDay,
                         tintDetailText: Bool = false,
                         strikeText: Bool = false) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "dateDisplay")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "dateDisplay")
        }
        
        cell.textLabel!.text = label
        
        let formattedDate = day.string(formatter: dateFormatter)
        
        let attributedText = NSMutableAttributedString(string: formattedDate)
        let attr: [NSAttributedStringKey: Any] = [
            .foregroundColor: tintDetailText ? view.tintColor : UIColor.black,
            .strikethroughColor: tintDetailText ? view.tintColor : UIColor.black,
            // NSUnderlineStyle.styleNone and .styleSingle weren't working, so
            // I am using literal number values. Should be changed if there is
            // a better way.
            .strikethroughStyle: strikeText ? NSNumber(integerLiteral: 1) : NSNumber(integerLiteral: 0)
        ]
        attributedText.addAttributes(attr, range: NSMakeRange(0, formattedDate.count))
        cell.detailTextLabel!.attributedText = attributedText
        
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
        var cell: TextFieldTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "textFieldDisplay") as? TextFieldTableViewCell
        if cell == nil {
            cell = TextFieldTableViewCell(style: .default, reuseIdentifier: "textFieldDisplay")
        }

        cell.setCalculatorTextField(true)
        cell.textField.placeholder = "$0"
        cell.textField.text = amount != nil ? String.formatAsCurrency(amount: amount!) : nil
        cell.textLabel?.text = title
        cell.setHasTitle(title != nil)
        cell.setChangedEvaluatedValueCallback { (_, newValue) in
            changedToAmount(newValue)
        }
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
