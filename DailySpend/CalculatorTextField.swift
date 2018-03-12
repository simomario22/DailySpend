//
// The follwing files are derived Venmo's VENCalculatorInputView, which is
// licensed under the MIT License and Copyright (c) 2014 Ayaka Nonaka:
// CalculatorInputView.swift
// CalculatorTextField.swift
// VENCalculatorIconBackspace.png
// VENCalculatorIconBackspace@2x.png
// VENCalculatorIconBackspace@3x.png
//
// A copy of VENCalculatorInputView's source can be found at
// https://github.com/venmo/VENCalculatorInputView
// A copy of the license for that project is included in DailySpend's source
// files as VENMO_LICENSE.txt
//
//  CalculatorTextField.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/4/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

class CalculatorTextField: UITextField, CalculatorInputViewDelegate {
    var calcDelegate: CalculatorTextFieldDelegate?
    let operationFunctions: [Character: (Decimal, Decimal) -> Decimal] = [
        "+": { $0 + $1 },
        "−": { $0 - $1 },
        "×": { $0 * $1 },
        "÷": { $0 / $1 }
    ]
    let operationCharacters = CharacterSet(charactersIn: "÷×−+")
    let validChars: CharacterSet
    private var value: Decimal?
    
    public var maxValue: Decimal?
    // Set these up for currency by default.
    public var formatOperand: ((String) -> String)? = { "$" + $0 }
    public var emptyTransformation: String? = "$"
    public var formatFinishedValue: ((Decimal) -> String)? = { String.formatAsCurrency(amount: $0)! }

    override init(frame: CGRect) {
        validChars = CharacterSet(charactersIn: "0123456789.").union(operationCharacters)
        super.init(frame: frame)
        let screenHeight = UIScreen.main.bounds.size.height
        let screenWidth = UIScreen.main.bounds.size.width
        let inputHeight: CGFloat = 216
        let inputFrame = CGRect(x: 0, y: screenHeight - inputHeight, width: screenWidth, height: inputHeight)
        add(for: .editingDidEnd, didEndEditing)
        add(for: .editingChanged, editingChanged)
        
        let calcInputView = CalculatorInputView(frame: inputFrame)
        calcInputView.delegate = self
        inputView = calcInputView
    }
    
    required init?(coder aDecoder: NSCoder) {
        validChars = CharacterSet(charactersIn: "0123456789.").union(operationCharacters)
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    func didEndEditing() {
        if let evaluated = evaluatedValue() {
            text = formatFinishedValue?(evaluated) ?? String(describing: evaluated)
        } else {
            text = nil
        }
    }
    
    func editingChanged() {
        if emptyTransformation != nil && text == emptyTransformation! {
            text = nil
        }
        
        guard let text = text else {
            return
        }
        
        let expressionParts = makeExpressionParts(text)
        self.text = formatText(expressionParts: expressionParts, text: text)
        
        let newValue = evaluateExpression(parts: expressionParts, maxValue: maxValue)
        if newValue != value {
            value = newValue
            calcDelegate?.textFieldChangedEvaluatedValue(self, to: value)
        }
    }
    
    func formatText(expressionParts: ExpressionParts, text: String) -> String {
        guard let formatOperand = formatOperand else {
            return text
        }
        
        switch expressionParts {
        case .MultiValue(let firstOperand, let operation, let secondOperand):
            guard let operationIndex = text.index(of: operation) else {
                break
            }
            let textBeforeOperand = String(describing: text[text.startIndex..<operationIndex])
                                    .removeCharactersWhichAreActuallyUnicodeScalarsSoBeCareful(in: validChars.inverted)
            let textAfterOperand = String(describing: text[text.index(after: operationIndex)..<text.endIndex])
                                    .removeCharactersWhichAreActuallyUnicodeScalarsSoBeCareful(in: validChars.inverted)
            if Decimal(string: textBeforeOperand) == firstOperand &&
                Decimal(string: textAfterOperand) == secondOperand {
                let transformedBefore = formatOperand(textBeforeOperand)
                let transformedAfter = formatOperand(textAfterOperand)
                return transformedBefore + String(operation) + transformedAfter
            }
        case .SingleValue(let value):
            // Only transform if there's nothing weird in text.
            if Decimal(string: text) == value {
                return formatOperand(text)
            }
        case .InvalidExpression: break
        }
        return text
    }

    func tappedKey(_ key: String) {
        let location = offset(from: beginningOfDocument, to: selectedTextRange!.start)
        let length = offset(from: selectedTextRange!.start, to: selectedTextRange!.end)
        let objCRange = NSMakeRange(location, length)
        
        var shouldChange = delegate?.textField?(self, shouldChangeCharactersIn: objCRange, replacementString: key) ?? true
        let newString = ((text ?? "") as NSString).replacingCharacters(in: objCRange, with: key)
        if maxValue != nil {
            let expressionParts = makeExpressionParts(newString)
            let evaluated = evaluateExpression(parts: expressionParts)
            shouldChange = shouldChange && (evaluated == nil || evaluated! <= maxValue!)
        }
        
        if !shouldChange {
            return
        }
        
        if operationCharacters.contains(key.unicodeScalars.first!) && text!.containsAny(in: operationCharacters) {
            if let evaluated = evaluatedValue() {
                text = formatFinishedValue?(evaluated) ?? String(describing: evaluated)
            } else {
                return
            }
        }
        
        insertText(key)
    }
    
    func tappedBackspace() {
        deleteBackward()
    }
    
    func evaluatedValue() -> Decimal? {
        let expressionParts = makeExpressionParts(text!)
        return text != nil ? evaluateExpression(parts: expressionParts, maxValue: maxValue) : nil
    }
    
    enum ExpressionParts {
        case InvalidExpression
        case SingleValue(value: Decimal)
        case MultiValue(firstOperand: Decimal, operation: Character, secondOperand: Decimal)
    }
    
    func evaluateExpression(parts: ExpressionParts, maxValue: Decimal? = nil) -> Decimal? {
        switch parts {
        case .MultiValue(let firstOperand, let operation, let secondOperand):
            let op = operationFunctions[operation]!
            let value = op(firstOperand, secondOperand)
            return maxValue == nil ? value : min(value, maxValue!)
        case .SingleValue(let value):
            return maxValue == nil ? value : min(value, maxValue!)
        case .InvalidExpression:
            return nil
        }
    }
    
    func makeExpressionParts(_ expression: String) -> ExpressionParts {
        func validNumber(candidate: String) -> Decimal? {
            if candidate.isEmpty || candidate.countOccurrences(ofString: ".")! > 1 {
                return nil
            }
            return Decimal(string: candidate)
        }
        
        let stripped = expression.removeCharactersWhichAreActuallyUnicodeScalarsSoBeCareful(in: validChars.inverted)
        
        var operand: Character? = nil
        var firstOperand = ""
        var secondOperand = ""
        for (opChar, _) in operationFunctions {
            if let index = stripped.index(of: opChar) {
                secondOperand = String(describing: stripped[stripped.index(after: index)...])
                if operand != nil || secondOperand.contains(opChar) {
                    // Empty first or second operand, other operand already
                    // specified, or string contains multiple of this operand.
                    return .InvalidExpression
                }
                operand = opChar
                firstOperand = String(describing: stripped[..<index])
            }
        }
        
        
        
        if let op = operand,
            let first = validNumber(candidate: firstOperand),
            let second = validNumber(candidate: secondOperand) {
            return .MultiValue(firstOperand: first, operation: op, secondOperand: second)
        } else if let value = validNumber(candidate: stripped) {
            return .SingleValue(value: value)
        } else {
            return .InvalidExpression
        }
    }
}

protocol CalculatorTextFieldDelegate: UITextFieldDelegate {
    func textFieldChangedEvaluatedValue(_ textField: CalculatorTextField, to newValue: Decimal?)
}
