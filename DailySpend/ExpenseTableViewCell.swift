//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {
    // Constants
    private let margin: CGFloat = 8
    private let inset: CGFloat = 15
    
    private let amountPointSize: CGFloat = 28
    private let descriptionPointSize: CGFloat = 20
    private let amountHeight: CGFloat = 42
    private let buttonHeight: CGFloat = 60

    private var descriptionView: ExpenseCellDescriptionTextView!
    private var amountField: CalculatorTextField!
    private var quickSuggestView: ButtonPickerView!
    private var relativeDatePickerView: RelativeDatePicker!
    private var detailDisclosureButton: UIButton!
    private var plusButton: UIButton!
    private var saveButton: DSButton!
    private var cancelButton: DSButton!

    private var collapsedHeight: CGFloat = -1
    private var expandedHeight: CGFloat = -1
    private var detailDisclosureButtonOnscreen: Bool = false
    private var plusButtonOnscreen: Bool = false
    private var relativeDatePickerOnscreen: Bool = true

    var beganEditing: ((ExpenseTableViewCell) -> ())?
    var endedEditing: ((String?, Decimal?) -> ())?
    var willReturn: ((UIResponder) -> ())?
    var changedDescription: ((String?) -> ())?
    var changedEvaluatedAmount: ((Decimal?) -> ())?
    var changedDay: ((CalendarDay) -> ())?
    var tappedSave: ((String?, Decimal?, () -> ()) -> ())?
    var tappedCancel: ((() -> (), ([String]?) -> ()) -> ())?
    var selectedDetailDisclosure: ((Bool) -> ())?
    var changedCellHeight: ((CGFloat, CGFloat) -> ())?

    var descriptionPlaceholder: String? {
        get {
            return descriptionView.placeholder
        }

        set {
            descriptionView.placeholder = newValue
        }
    }

    var descriptionPlaceholderUsesUndescribedStyle: Bool = false {
        didSet {
            descriptionView.isPlaceholderItalic = descriptionPlaceholderUsesUndescribedStyle
        }
    }
    var descriptionText: String? {
        get {
            return descriptionView.userText
        }

        set {
            descriptionView.userText = newValue
        }
    }

    var amountText: String? {
        get {
            return amountField.text
        }
        set {
            amountField.text = newValue
        }
    }

    var amountMaxValue: Decimal? {
        get {
            return amountField.maxValue
        }
        set {
            amountField.maxValue = newValue
        }
    }

    var amountPlaceholder: String? {
        didSet {
            amountField.placeholder = amountPlaceholder
        }
    }

    var day: CalendarDay? {
        get {
            return relativeDatePickerView.selectedDay
        }
        set {
            relativeDatePickerView.selectedDay = newValue
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutOwnSubviews(animated: false)
    }
    
    private func setDetailDisclosureButtonFrame(onscreen: Bool) {
        let ics = detailDisclosureButton.intrinsicContentSize
        let x = bounds.size.width - ics.width - inset
        let y = (amountHeight / 2) - (ics.height / 2)
        var frame = CGRect(x: x, y: y, width: ics.width, height: ics.height)
        if !onscreen {
            frame.origin.x = bounds.size.width + ics.width + inset
        }
        
        detailDisclosureButton.frame = frame
    }

    private func setPlusButtonFrame(onscreen: Bool) {
        let width: CGFloat = 25
        let height: CGFloat = 38
        let y = amountHeight - (height / 2)
        var frame = CGRect(x: margin, y: y, width: width, height: height)
        if !onscreen {
            frame.origin.x = -width - margin
        }
        
        plusButton.frame = frame
    }

    private func layoutOwnSubviews(animated: Bool) {
        if animated {
            UIView.beginAnimations("ExpenseTableViewCell.layoutOwnSubviews", context: nil)
        }

        if detailDisclosureButton != nil {
            setDetailDisclosureButtonFrame(onscreen: detailDisclosureButtonOnscreen)
        }
        
        if plusButton != nil {
            setPlusButtonFrame(onscreen: plusButtonOnscreen)
        }
        
        if amountField != nil {
            let leftSide = plusButtonOnscreen ? plusButton.frame.rightEdge + margin : inset
            let rightSide = detailDisclosureButtonOnscreen ?
                (bounds.size.width - detailDisclosureButton.frame.leftEdge) + margin : inset

            amountField.frame = CGRect(
                x: leftSide,
                y: margin,
                width: bounds.size.width - leftSide - rightSide,
                height: amountHeight
            )
        }

        if descriptionView != nil {
            let leftSide = plusButtonOnscreen ? plusButton.frame.rightEdge + margin : inset
            let rightSide = inset
            let width = bounds.size.width - rightSide - leftSide
            let height = (descriptionView.userText ?? descriptionView.placeholder)?.calculatedHeightForWidth(width, font: descriptionView.font)

            descriptionView.frame = CGRect(
                x: leftSide,
                y: amountField.frame.bottomEdge,
                width: width,
                height: height ?? amountHeight
            )
        }

        if quickSuggestView != nil {
            let leftSide = plusButtonOnscreen ? plusButton.frame.rightEdge + margin : 0

            quickSuggestView.frame = CGRect(
                x: leftSide,
                y: amountField.frame.bottomEdge,
                width: bounds.size.width - leftSide,
                height: amountHeight
            )

            let insets = plusButtonOnscreen ? UIEdgeInsets.zero : UIEdgeInsets(top: 0, left: inset, bottom: 0, right: 0)
            quickSuggestView.contentInset = insets
            quickSuggestView.scrollIndicatorInsets = insets
            if (quickSuggestView.contentOffset.x == 0) {
                quickSuggestView.contentOffset = CGPoint(x: plusButtonOnscreen ? 0 : -inset, y: 0)
            }
        }

        let collapsedBottomEdge = (descriptionView.isHidden ? quickSuggestView : descriptionView).frame.bottomEdge

        if relativeDatePickerView != nil {
            let width = bounds.size.width - inset
            let leftSide = relativeDatePickerOnscreen ? inset : -width - inset
            let y = collapsedBottomEdge + margin + 1

            relativeDatePickerView.frame = CGRect(
                x: leftSide,
                y: y,
                width: width,
                height: amountHeight
            )
        }

        let buttonTop = relativeDatePickerOnscreen ? relativeDatePickerView.frame.bottomEdge : collapsedBottomEdge

        // Bottom buttons
        let halfWidth = bounds.size.width / 2
        let cancelFrame = CGRect(
            x: 0,
            y: buttonTop,
            width: halfWidth,
            height: buttonHeight
        ).insetBy(dx: margin, dy: margin)

        if cancelButton != nil {
            cancelButton.frame = cancelFrame.shiftedLeftEdge(by: margin)
        }
        
        if saveButton != nil {
            saveButton.frame = cancelFrame.offsetBy(dx: halfWidth, dy: 0).shiftedRightEdge(by: -margin)
        }

        let newCollapsedHeight = collapsedBottomEdge + margin
        let newExpandedHeight = saveButton.frame.bottomEdge + margin
        if newCollapsedHeight != collapsedHeight || newExpandedHeight != expandedHeight {
            collapsedHeight = newCollapsedHeight
            expandedHeight = newExpandedHeight
            changedCellHeight?(collapsedHeight, expandedHeight)
        }
        
        if animated {
            UIView.commitAnimations()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        descriptionView = ExpenseCellDescriptionTextView(delegate: self)
        amountField = CalculatorTextField()
        quickSuggestView = ButtonPickerView()
        relativeDatePickerView = RelativeDatePicker()

        descriptionView.textViewDelegate = self
        descriptionView.returnKeyType = .done
        descriptionView.smartInsertDeleteType = .no
        descriptionView.textContainerInset = .zero
        descriptionView.textContainer.lineFragmentPadding = 0
        descriptionView.font = UIFont.systemFont(ofSize: descriptionPointSize)

        amountField.borderStyle = .none
        amountField.smartInsertDeleteType = .no
        amountField.font = UIFont.systemFont(ofSize: amountPointSize, weight: .bold)
        amountField.delegate = self
        amountField.calcDelegate = self

        quickSuggestView.pickerDelegate = self

        relativeDatePickerView.delegate = self

        amountField.add(for: .editingChanged) {
            self.setNeedsLayout()
        }

        detailDisclosureButton = UIButton(type: .detailDisclosure)
        detailDisclosureButton.add(for: .touchUpInside) {
            self.selectedDetailDisclosure?(false)
        }
        
        plusButton = UIButton(type: .custom)
        plusButton.setTitle("+", for: .normal)
        plusButton.setTitleColor(self.tintColor, for: .normal)
        plusButton.titleLabel?.font = UIFont.systemFont(ofSize: 41.0, weight: .light)
        plusButton.add(for: .touchUpInside) {
            self.amountField.becomeFirstResponder()
        }
        
        saveButton = DSButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.add(for: .touchUpInside) {
            self.tappedSave?(
                self.descriptionText,
                self.amountField.evaluatedValue(),
                {
                    self.descriptionView.resignFirstResponder()
                    self.amountField.resignFirstResponder()
                })
        }
        
        cancelButton = DSButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.add(for: .touchUpInside) {
            self.tappedCancel?({
                self.descriptionView.resignFirstResponder()
                self.amountField.resignFirstResponder()
            }, { (buttonValues: [String]?) in
                self.descriptionView.userText = nil
                self.amountField.text = nil
                self.setPlusButton(show: true, animated: true)
                self.setDetailDisclosure(show: false, animated: true)
                self.setQuickSuggest(show: true, buttonValues: buttonValues)
                self.setNeedsLayout()
            })
        }
        
        self.addSubviews([
            amountField,
            descriptionView,
            quickSuggestView,
            relativeDatePickerView,
            detailDisclosureButton,
            plusButton,
            saveButton,
            cancelButton
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setDetailDisclosure(show: Bool, animated: Bool) {
        if show != detailDisclosureButtonOnscreen {
            detailDisclosureButtonOnscreen = show
            self.layoutOwnSubviews(animated: animated)
        }
    }

    func setPlusButton(show: Bool, animated: Bool) {
        if show != plusButtonOnscreen {
            plusButtonOnscreen = show
            self.layoutOwnSubviews(animated: animated)
        }
    }

    func setQuickSuggest(show: Bool, buttonValues: [String]?) {
        if show && buttonValues != nil && !buttonValues!.isEmpty {
            quickSuggestView.isHidden = false
            descriptionView.isHidden = true
            quickSuggestView.buttonTitles = buttonValues!
        } else {
            quickSuggestView.isHidden = true
            descriptionView.isHidden = false
        }
    }

    func setRelativeDatePickerView(show: Bool) {
        if relativeDatePickerOnscreen != show {
            relativeDatePickerOnscreen = show
            self.setNeedsLayout()
        }
    }

    /**
     * Recalculates the cell height on next layout and fires a notification with
     * the new height.
     */
    func resetCellHeight() {
        expandedHeight = -1
        collapsedHeight = -1
    }

    /**
     * Will synchronously notify receiver via `changedCellHeight` of height
     * updates.
     */
    func notifyHeightReceiver() {
        layoutOwnSubviews(animated: false)
    }
}

extension ExpenseTableViewCell: ExpenseCellDescriptionTextViewDelegate, CalculatorTextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        beganEditing?(self)
    }

    func textFieldChangedEvaluatedValue(_ textField: CalculatorTextField, to newValue: Decimal?) {
        changedEvaluatedAmount?(newValue)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        endedEditing?(self.descriptionText, self.amountField.evaluatedValue())
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        willReturn?(descriptionView)
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        beganEditing?(self)
    }

    func textViewDidChange(_ textView: UITextView) {
        changedDescription?(self.descriptionText)
        setNeedsLayout()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        endedEditing?(self.descriptionText, self.amountField.evaluatedValue())
    }

    func textViewDidReturn(_ textView: UITextView) {
        textView.resignFirstResponder()
    }
}

extension ExpenseTableViewCell: ButtonPickerViewDelegate {
    func tappedButton(in picker: ButtonPickerView, at index: Int, with label: String) {
        if picker == self.quickSuggestView {
            self.setQuickSuggest(show: false, buttonValues: nil)
            self.descriptionText = label
            self.textViewDidChange(descriptionView)
            if (self.amountField.evaluatedValue() ?? 0) != 0 {
                self.descriptionView.becomeFirstResponder()
            } else {
                self.amountField.becomeFirstResponder()
            }
            self.setNeedsLayout()
        }
    }

    func tappedCustomButton(in picker: ButtonPickerView) {
        if picker == self.quickSuggestView {
            self.setQuickSuggest(show: false, buttonValues: nil)
            self.descriptionView.becomeFirstResponder()
            self.setNeedsLayout()
        }
    }
}

extension ExpenseTableViewCell: RelativeDatePickerDelegate {
    func selectedDay(_ day: CalendarDay) {
        changedDay?(day)
    }

    func selectedExpandedDateSelection() {
        selectedDetailDisclosure?(true)
    }
}
