//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell, UITextFieldDelegate, CalculatorTextFieldDelegate {
    let margin: CGFloat = 8
    let inset: CGFloat = 15
    
    var textField: UITextField!
    
    var hasTitle = false
    var useCalcInputView = false
    
    private var shouldChangeCallback: ((UITextField, NSRange, String) -> Bool)?
    private var changedCallback: ((UITextField) -> ())?
    private var beginEditingCallback: ((UITextField) -> ())?
    private var endEditingCallback: ((UITextField) -> ())?
    private var changedEvaluatedValueCallback: ((UITextField, Decimal?) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if textField != nil {
            var frame = bounds.insetBy(dx: margin, dy: margin)
            if hasTitle {
                let textWidth = textLabel?.intrinsicContentSize.width ?? (bounds.size.width / 2)
                frame.origin.x = textWidth + inset + margin
                frame.size.width = bounds.size.width - textWidth - (inset * 2) - margin
            } else {
                frame.origin.x += (inset - margin)
            }
            textField.frame = frame

        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textField = makeTextField(calculator: false)
        self.addSubview(textField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func makeTextField(calculator: Bool) -> UITextField {
        let field = calculator ? CalculatorTextField() : UITextField()
        field.borderStyle = .none
        field.delegate = self
        field.addTarget(self, action: #selector(textFieldChanged(field:)), for: .editingChanged)
        if calculator {
            let calcField = field as! CalculatorTextField
            calcField.calcDelegate = self
        }
        return field
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        beginEditingCallback?(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        endEditingCallback?(textField)
    }
    
    @objc func textFieldChanged(field: UITextField!) {
        changedCallback?(field)
    }
    
    func textFieldChangedEvaluatedValue(_ textField: CalculatorTextField, to newValue: Decimal?) {
        changedEvaluatedValueCallback?(textField, newValue)
    }
    
    func setBeginEditingCallback(_ cb: ((UITextField) -> ())?) {
        beginEditingCallback = cb
    }
    
    func setEndEditingCallback(_ cb: ((UITextField) -> ())?) {
        endEditingCallback = cb
    }
    
    func setChangedCallback(_ cb: ((UITextField) -> ())?) {
        changedCallback = cb
    }
    
    func setShouldChangeCallback(_ cb: ((UITextField, NSRange, String) -> Bool)?) {
        shouldChangeCallback = cb
    }
    
    func setChangedEvaluatedValueCallback(_ cb: ((UITextField, Decimal?) -> ())?) {
        changedEvaluatedValueCallback = cb
    }
    
    func setHasTitle(_ newValue: Bool) {
        if newValue != hasTitle {
            hasTitle = newValue
            textField.textAlignment = hasTitle ? .right : .left
            self.setNeedsLayout()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let cb = shouldChangeCallback {
            return cb(textField, range, string)
        }
        return true
    }
    
    func setCalculatorTextField(_ newValue: Bool) {
        if newValue == true && useCalcInputView == false {
            let oldFrame = textField.frame
            textField.removeFromSuperview()
            textField = makeTextField(calculator: true)
            textField.frame = oldFrame
            self.addSubview(textField)
            useCalcInputView = true
        } else if newValue == false && useCalcInputView == true {
            let oldFrame = textField.frame
            textField.removeFromSuperview()
            textField = makeTextField(calculator: false)
            textField.frame = oldFrame
            self.addSubview(textField)
            useCalcInputView = false
        }
    }
}
