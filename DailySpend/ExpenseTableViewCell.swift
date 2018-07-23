//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ExpenseCellButton : UIButton {
    let pressedColor = UIColor(red:0.50, green:0.50, blue:0.51, alpha:1.00)
    
    var nonHighlightedBackgroundColor: UIColor? {
        didSet {
            backgroundColor = nonHighlightedBackgroundColor
        }
    }
    
    override open var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = pressedColor
            } else {
                backgroundColor = nonHighlightedBackgroundColor
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 5
//        let lightColor = UIColor(red:0.99, green:0.98, blue:0.99, alpha:1.00)
        let darkColor = UIColor(red:0.66, green:0.70, blue:0.75, alpha:1.00)
        self.nonHighlightedBackgroundColor = darkColor
        self.backgroundColor = darkColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ExpenseTableViewCell: UITableViewCell, UITextFieldDelegate, CalculatorTextFieldDelegate {
    let margin: CGFloat = 8
    let inset: CGFloat = 15
    
    let collapsedHeight: CGFloat = 44
    let expandedHeight: CGFloat = 88
    let amountFieldMaxWidth: CGFloat = 120
    
    var descriptionField: UITextField!
    var amountField: CalculatorTextField!
    var detailDisclosureButton: UIButton!
    var plusButton: UIButton!
    var saveButton: ExpenseCellButton!
    var cancelButton: ExpenseCellButton!
    
    var detailDisclosureButtonOnscreen: Bool = false
    var plusButtonOnscreen: Bool = false

    var beganEditing: ((ExpenseTableViewCell, UITextField) -> ())?
    var shouldBegin: ((ExpenseTableViewCell, UITextField) -> ())?
    var willReturn: ((ExpenseTableViewCell, UITextField, UITextField) -> ())?
    var endedEditing: ((ExpenseTableViewCell, UITextField) -> ())?
    var changedDescription: ((UITextField) -> ())?
    var changedEvaluatedAmount: ((UITextField, Decimal?) -> ())?
    var tappedSave: ((UITextField, CalculatorTextField) -> ())?
    var tappedCancel: ((UITextField, CalculatorTextField) -> ())?
    var selectedDetailDisclosure: (() -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutOwnSubviews(animated: false)
    }
    
    private func setDetailDisclosureButtonFrame(onscreen: Bool) {
        let ics = detailDisclosureButton.intrinsicContentSize
        let x = bounds.size.width - ics.width - inset
        let y = (collapsedHeight / 2) - (ics.height / 2)
        var frame = CGRect(x: x, y: y, width: ics.width, height: ics.height)
        if !onscreen {
            frame.origin.x = bounds.size.width + ics.width + inset
        }
        
        detailDisclosureButton.frame = frame
    }

    private func setPlusButtonFrame(onscreen: Bool) {
        var frame = CGRect(x: margin, y: 0, width: 25, height: 38)
        if !onscreen {
            frame.origin.x = -25 - margin
        }
        
        plusButton.frame = frame
    }
    
    private func layoutOwnSubviews(animated: Bool) {
        if animated {
            UIView.beginAnimations("ExpenseTableViewCell.layoutOwnSubviews", context: nil)
        }
        var adjustedDetailDisclosureWidth: CGFloat = 0
        var adjustedPlusWidth: CGFloat = 0

        if detailDisclosureButton != nil {
            setDetailDisclosureButtonFrame(onscreen: detailDisclosureButtonOnscreen)
            let width = detailDisclosureButton.frame.size.width + margin / 2
            adjustedDetailDisclosureWidth = detailDisclosureButtonOnscreen ? width : 0
        }
        
        if plusButton != nil {
            setPlusButtonFrame(onscreen: plusButtonOnscreen)
            let width = plusButton.frame.size.width + margin * 1.5 - inset
            adjustedPlusWidth = plusButtonOnscreen ? width : 0
        }
        
        if amountField != nil {
            let height = collapsedHeight - (margin * 2)
            let minWidth = amountField.placeholder?.calculatedWidthForHeight(height, font: amountField.font) ?? 80
            let calcWidth = amountField.text?.calculatedWidthForHeight(height, font: amountField.font) ?? minWidth
            let width = min(max(calcWidth, minWidth), amountFieldMaxWidth)
            let rightSide = inset + margin / 2 + adjustedDetailDisclosureWidth
            
            amountField.frame = CGRect(
                x: bounds.size.width - rightSide - width,
                y: margin,
                width: width,
                height: height
            )
        }
        
        if descriptionField != nil {
            let rightSide = bounds.size.width -
                (
                    amountField?.frame.leftEdge ??
                    inset + margin / 2 + adjustedDetailDisclosureWidth
            )
            let leftSide = inset + adjustedPlusWidth
            descriptionField.frame = CGRect(
                x: leftSide,
                y: margin,
                width: bounds.size.width - leftSide - rightSide,
                height: collapsedHeight - (margin * 2)
            )
        }

        // Bottom buttons
        let halfWidth = bounds.size.width / 2
        let cancelFrame = CGRect(
            x: 0,
            y: collapsedHeight,
            width: halfWidth,
            height: expandedHeight - collapsedHeight
        ).insetBy(dx: margin, dy: margin)

        if cancelButton != nil {
            cancelButton.frame = cancelFrame.shiftedLeftEdge(by: margin)
        }
        
        if saveButton != nil {
            saveButton.frame = cancelFrame.offsetBy(dx: halfWidth, dy: 0).shiftedRightEdge(by: -margin)
        }
        
        if animated {
            UIView.commitAnimations()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        descriptionField = UITextField()
        amountField = CalculatorTextField()
        
        descriptionField.borderStyle = .none
        descriptionField.delegate = self
        descriptionField.returnKeyType = .next
        
        amountField.borderStyle = .none
        amountField.delegate = self
        amountField.textAlignment = .right
        amountField.calcDelegate = self
        
        descriptionField.addTarget(self, action: #selector(textFieldChanged(field:)), for: .editingChanged)
        amountField.addTarget(self, action: #selector(textFieldChanged(field:)), for: .editingChanged)
        
        detailDisclosureButton = UIButton(type: .detailDisclosure)
        
        plusButton = UIButton(type: .custom)
        plusButton.setTitle("+", for: .normal)
        plusButton.setTitleColor(UIColor(red255: 198, green: 198, blue: 198), for: .normal)
        plusButton.titleLabel?.font = UIFont.systemFont(ofSize: 41.0, weight: .thin)
        plusButton.add(for: .touchUpInside) {
            self.descriptionField.becomeFirstResponder()
        }
        
        saveButton = ExpenseCellButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.add(for: .touchUpInside) {
            self.tappedSave?(self.descriptionField, self.amountField)
        }
        
        cancelButton = ExpenseCellButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.add(for: .touchUpInside) {
            self.tappedCancel?(self.descriptionField, self.amountField)
        }
        
        self.addSubviews([descriptionField, amountField, detailDisclosureButton, plusButton, saveButton, cancelButton])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        beganEditing?(self, textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        endedEditing?(self, textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == descriptionField {
            willReturn?(self, descriptionField, amountField)
        } else {
            willReturn?(self, amountField, descriptionField)
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        shouldBegin?(self, textField)
        return true
    }
    
    @objc func textFieldChanged(field: UITextField!) {
        if field == descriptionField {
            changedDescription?(field)
        } else {
            // Size of amount field may have changed.
            self.setNeedsLayout()
        }
    }
    
    func textFieldChangedEvaluatedValue(_ textField: CalculatorTextField, to newValue: Decimal?) {
        changedEvaluatedAmount?(textField, newValue)
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
}

