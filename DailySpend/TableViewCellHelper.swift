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
    var dateFormatter: DateFormatter
    
    init(tableView: UITableView, dateFormatter: DateFormatter? = nil) {
        self.tableView = tableView
        
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
    func dateDisplayCell(label: String,
                         day: CalendarDay?,
                         tintColor: UIColor? = nil,
                         strikeText: Bool = false,
                         alternateText: String? = nil) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "dateDisplay")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "dateDisplay")
        }

        let dateText = day?.string(formatter: dateFormatter, friendly: true) ?? alternateText ?? "None"
        
        return valueDisplayCell(labelText: label,
                                valueText: dateText,
                                tintColor: tintColor,
                                strikeText: strikeText)
    }
    
    func indentedLabelCell(
        labelText: String,
        indentationLevel: Int,
        indentationWidth: CGFloat = 10,
        selected: Bool = false
    ) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "indentedLabel")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "indentedLabel")
        }
        
        cell.textLabel!.text = labelText
        cell.accessoryType = selected ? .checkmark : .none
        cell.indentationWidth = indentationWidth
        cell.indentationLevel = indentationLevel
        
        return cell
    }
    
    /**
     * Returns a cell with a single centered label.
     */
    func centeredLabelCell(labelText: String, disabled: Bool) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "centeredLabel")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "centeredLabel")
        }
        
        cell.textLabel!.text = labelText
        cell.textLabel!.textAlignment = .center
        
        if disabled {
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.font = UIFont.italicSystemFont(ofSize: 17)
        }
        
        return cell
    }

    
    /**
     * Cell to display a label and a value, which can be tinted or crossed out.
     */
    func valueDisplayCell(
        labelText: String,
        valueText: String,
        explanatoryText: String? = nil,
        tintColor: UIColor? = nil,
        strikeText: Bool = false,
        detailIndicator: Bool = false
    ) -> UITableViewCell {
        var cell: ValueTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "valueDisplay") as? ValueTableViewCell
        if cell == nil {
            cell = ValueTableViewCell(style: .value1, reuseIdentifier: "valueDisplay")
        }
        
        cell.textLabel!.text = labelText
        cell.accessoryType = detailIndicator ? .disclosureIndicator : .none
        cell.setExplanatoryText(explanatoryText)
        
        let attributedText = NSMutableAttributedString(string: valueText)
        let attr: [NSAttributedStringKey: Any] = [
            .foregroundColor: tintColor ?? UIColor.black,
            .strikethroughColor: tintColor ?? UIColor.black,
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
    func textFieldDisplayCell(title: String? = nil,
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
     * Return a cell with an editable currency-formatted text field.
     */
    func currencyDisplayCell(title: String? = nil,
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
     * Return a non editable cell with the option for a detail disclosure
     * indicator and an "undescribed" descriptor style.
     */
    func optionalDescriptorValueCell(
        description: String?,
        undescribed: Bool,
        value: String?,
        detailButton: Bool
    ) -> UITableViewCell {
        var cell: ValueTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "optionalDescriptorValue") as? ValueTableViewCell
        if cell == nil {
            cell = ValueTableViewCell(style: .value1, reuseIdentifier: "optionalDescriptorValue")
        }
        
        cell.textLabel!.text = description
        if !undescribed {
            cell.textLabel!.font = UIFont.systemFont(ofSize: 18)
        } else {
            cell.textLabel!.font = UIFont.italicSystemFont(ofSize: 18)
        }
        cell.detailTextLabel!.text = value
        cell.detailTextLabel?.textColor = .black
        
        cell.accessoryType = detailButton ? .detailButton : .none
        return cell
    }

    
    /**
     * Return a cell with a segmented control.
     */
    func segmentedControlCell(segmentTitles: [String],
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
    func switchCell(initialValue: Bool,
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
    func datePickerCell(
            day: CalendarDay,
            changedToDay: @escaping (CalendarDay) -> ()
        ) -> UITableViewCell {
        var cell: DatePickerTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "datePicker") as? DatePickerTableViewCell
        if cell == nil {
            cell = DatePickerTableViewCell(style: .default, reuseIdentifier: "datePicker")
        }
        
        cell.datePicker.datePickerMode = .date
        cell.datePicker.timeZone = CalendarDay.gmtTimeZone
        cell.datePicker.setDate(day.start.gmtDate, animated: false)
        cell.setCallback { (datePicker: UIDatePicker) in
            let day = CalendarDay(dateInDay: GMTDate(datePicker.date))
            changedToDay(day)
        }
        
        return cell
    }

    /**
     * Return a cell with a date picker.
     */
    func periodPickerCell(
        date: CalendarDateProvider,
        scope: PeriodScope,
        changedToDate: @escaping (CalendarDateProvider, PeriodScope) -> ()
    ) -> UITableViewCell {
        var cell: CalendarPeriodPickerTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "periodPicker") as? CalendarPeriodPickerTableViewCell
        if cell == nil {
            cell = CalendarPeriodPickerTableViewCell(style: .default, reuseIdentifier: "periodPicker")
        }
        
        cell.periodPicker.scope = scope
        cell.periodPicker.value = date
        cell.setCallback { (date: CalendarDateProvider, scope: PeriodScope) in
            changedToDate(date, scope)
        }
        
        return cell
    }

    
    /**
     * Return a cell with a picker.
     */
    func pickerCell(rows: [[String]],
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
     * Return a dynamic expense cell.
     */
    func expenseCell(
        description: String?,
        undescribed: Bool,
        amount: Decimal?,
        day: CalendarDay,
        showPlus: Bool,
        showButtonPicker: Bool,
        buttonPickerValues: [String]?,
        showDetailDisclosure: Bool,
        tappedSave: @escaping (String?, Decimal?, ()->()) -> (),
        tappedCancel: @escaping ( ()->(), ([String]?)->() ) -> (),
        selectedDetailDisclosure: @escaping (Bool) -> (),
        didBeginEditing: @escaping ((ExpenseTableViewCell) -> ()),
        changedToDescription: @escaping (String?) -> (),
        changedToAmount: @escaping (Decimal?) -> (),
        changedToDay: @escaping (CalendarDay) -> (),
        changedCellHeight: @escaping (CGFloat, CGFloat) -> ()
    ) -> UITableViewCell {
        var cell: ExpenseTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "addExpense") as? ExpenseTableViewCell
        if cell == nil {
            cell = ExpenseTableViewCell(style: .default, reuseIdentifier: "addExpense")
            cell.clipsToBounds = true
        } else {
            cell.resetCellHeight()
        }
        
        cell.willReturn = { (newField) in
            newField.becomeFirstResponder()
        }
        
        cell.beganEditing = { (cell: ExpenseTableViewCell) in
            didBeginEditing(cell)
        }
        cell.selectedDetailDisclosure = selectedDetailDisclosure

        cell.changedDescription = changedToDescription
        cell.endedEditing = { (shortDesc: String?, amount: Decimal?) in
            // Send changed events since autocorrect can change the text on
            // when editing ends.
            changedToAmount(amount)
            changedToDescription(shortDesc)
        }
        cell.tappedSave = { (shortDesc: String?, amount: Decimal?, resign: () -> ()) in
            tappedSave(shortDesc, amount, resign)
        }
        cell.tappedCancel = { (resign: () -> (), reset: ([String]?) -> ()) in
            tappedCancel(resign, reset)
        }
        cell.changedEvaluatedAmount = { amount in
            changedToAmount(amount)
        }

        cell.changedDay = changedToDay

        cell.changedCellHeight = changedCellHeight

        cell.amountPlaceholder = "$0.00"

        // Note: Side effect of setting text property is that
        // changedEvaluatedAmount gets called. Ensure that
        // changedEvaluatedAmount is set up before calling this function.
        let amountText = amount != nil ? "\(amount!)" : nil
        cell.amountText = amountText
        cell.amountMaxValue = 1e7

        cell.day = day

        cell.descriptionText = description
        cell.descriptionPlaceholder = undescribed ? "No Description" : "Description"
        cell.descriptionPlaceholderUsesUndescribedStyle = undescribed
        cell.setPlusButton(show: showPlus, animated: false)
        cell.setDetailDisclosure(show: showDetailDisclosure, animated: false)

        cell.setQuickSuggest(show: showButtonPicker, buttonValues: buttonPickerValues)

        cell.notifyHeightReceiver()

        cell.setNeedsLayout()
        return cell
    }
    
    func imageSelectorCell(selector: ImageSelectorView) -> UITableViewCell {
        var cell: ImageSelectorTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "addExpense") as? ImageSelectorTableViewCell
        if cell == nil {
            cell = ImageSelectorTableViewCell(style: .default, reuseIdentifier: "addExpense")
        }
        
        cell.textLabel?.text = "Images"
        cell.setImageSelector(selector)
        return cell
    }

    func longFormTextInputCell(
        text: String?,
        didBeginEditing: @escaping ((ExpenseTableViewCell) -> ()),
        changedToText: @escaping (String?) -> ()
    ) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "longFormText")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "longFormText")
        }
        return cell
    }

}
