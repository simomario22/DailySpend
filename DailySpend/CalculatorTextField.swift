//
// The follwing files are derived from Venmo's VENCalculatorInputView, which is
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
    /**
     * A receiver implementing `CalculatorTextFieldDelegate` to be notified
     * for events pertaining to `CalculatorTextField`.
     */
    var calcDelegate: CalculatorTextFieldDelegate?
    
    /**
     * A mapping of valid operation characters to functions that perform the
     * operation associated with that character.
     */
    private let operationFunctions: [Character: (Decimal, Decimal) -> Decimal] = [
        "+": { $0 + $1 },
        "−": { $0 - $1 },
        "×": { $0 * $1 },
        "÷": { $0 / $1 }
    ]
    
    /**
     * The characters that are associated with mathematical operations.
     */
    private let operationCharacters = CharacterSet(charactersIn: "÷×−+")
    
    /**
     * The characters for which the second operand should be formatted with
     * the `formatOperand` function.
     */
    private let operationCharactersWhereSecondOperandShouldBeFormatted = CharacterSet(charactersIn: "−+")
    
    /**
     * The format
     */
    let validChars: CharacterSet
    
    /**
     * The evaluted value of the text field.
     */
    private var value: Decimal?
    
    /**
     * A value indicating whether setting text should trigger editingChanged.
     */
    private var settingTextTriggersEditingChanged = true
    
    /**
     * The raw value of the text as shown to the user in this text field.
     */
    override var text: String? {
        didSet {
            if settingTextTriggersEditingChanged {
                editingChanged()
                if !isFirstResponder {
                    // Editing the text while not the first responder should be
                    // treated like becoming the first responder, changing
                    // text, then resigning first responder.
                    didEndEditing()
                }
            }
        }
    }
    /**
     * Allow internal bypass of editingChanged call when setting text.
     */
    private var safeText: String? {
        get {
            return text
        }
        set {
            settingTextTriggersEditingChanged = false
            text = newValue
            settingTextTriggersEditingChanged = true
        }
    }
    
    /**
     * The maximum evaluated value that should be allowed in the text field.
     */
    var maxValue: Decimal?
    
    // Set these up for currency by default.
    /**
     * A function to format an operand. Defaults to `{ "$" + $0 }`.
     */
    var formatOperand: ((String) -> String)? = { "$" + $0 }
    
    /**
     * A string that would be considered "empty" after transforming with
     * the `formatOperand` function. Defaults to `$`.
     */
    var emptyTransformation: String? = "$"
    
    /**
     * A function to format a valid evaluated decimal to a display to the user.
     * Defaults to `{ String.formatAsCurrency(amount: $0)! }`.
     */
    var formatFinishedValue: ((Decimal) -> String)? = { String.formatAsCurrency(amount: $0)! }

    override init(frame: CGRect) {
        validChars = CharacterSet(charactersIn: "0123456789.").union(operationCharacters)
        super.init(frame: frame)
        let screenHeight = UIScreen.main.bounds.size.height
        let screenWidth = UIScreen.main.bounds.size.width
        let inputHeight: CGFloat = 216 + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
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
    
    /**
     * Called when this text field resigns as first responder, or text is set
     * while this text field is not the first responder.
     *
     * This function updates the displayed text in the text field to a single
     * formatted value rather than an expression.
     */
    private func didEndEditing() {
        if let evaluated = evaluatedValue() {
            safeText = formatFinishedValue?(evaluated) ?? String(describing: evaluated)
        } else {
            safeText = nil
        }
    }
    
    /**
     * Called when the value of the text field has changed, either by typing on
     * a keyboard, or by changing the value of `text` directly.
     *
     * This function updates the value to the evaluated expression value and
     * formats the expression shown to the user.
     */
    private func editingChanged() {
        if emptyTransformation != nil && safeText == emptyTransformation! {
            if value != nil {
                calcDelegate?.textFieldChangedEvaluatedValue(self, to: nil)
            }
            value = nil
            safeText = nil
        }
        
        guard let text = safeText else {
            if value != nil {
                calcDelegate?.textFieldChangedEvaluatedValue(self, to: nil)
            }
            value = nil
            return
        }
        
        let expressionParts = makeExpressionParts(text)
        safeText = formatText(expressionParts: expressionParts, text: text)
        
        let newValue = evaluateExpression(parts: expressionParts, maxValue: maxValue)
        if newValue != value {
            value = newValue
            calcDelegate?.textFieldChangedEvaluatedValue(self, to: value)
        }
    }
    
    /**
     * - Parameters:
     *    - expressionParts: ExpressionParts created from the passed text.
     *    - text: A raw expression string.
     *
     * - Returns: Formatted text, if it matches its expression parts, otherwise
     *            the text itself.
     */
    private func formatText(expressionParts: ExpressionParts, text: String) -> String {
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
                var transformedAfter = textAfterOperand
                if operationCharactersWhereSecondOperandShouldBeFormatted.contains(operation.unicodeScalars.first!) {
                    transformedAfter = formatOperand(textAfterOperand)
                }
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

    /**
     * Called when a key pressed which produces string to be added to the text
     * field (e.g. not backspace).
     *
     * This functions determines whether or not to add the string,
     * where to add the string, and if it should evaluate the current
     * expression before inserting the string (e.g. if an operand was typed).
     */
    func tappedKey(_ key: String) {
        let location = offset(from: beginningOfDocument, to: selectedTextRange!.start)
        let length = offset(from: selectedTextRange!.start, to: selectedTextRange!.end)
        let objCRange = NSMakeRange(location, length)
        
        var shouldChange = delegate?.textField?(self, shouldChangeCharactersIn: objCRange, replacementString: key) ?? true
        let newString = ((safeText ?? "") as NSString).replacingCharacters(in: objCRange, with: key)
        if maxValue != nil {
            let expressionParts = makeExpressionParts(newString)
            let evaluated = evaluateExpression(parts: expressionParts)
            shouldChange = shouldChange && (evaluated == nil || evaluated! <= maxValue!)
        }
        
        if !shouldChange {
            return
        }
        
        if operationCharacters.contains(key.unicodeScalars.first!) && safeText!.containsAny(in: operationCharacters) {
            if let evaluated = evaluatedValue() {
                safeText = formatFinishedValue?(evaluated) ?? String(describing: evaluated)
            } else {
                return
            }
        }
        
        insertText(key)
    }
    
    /**
     * Called when the backspace key is pressed.
     */
    func tappedBackspace() {
        deleteBackward()
    }
    
    /**
     * - Returns: The evaluated value of the current text in the text field,
     *            including evaluating any operands or nil if the expression is
     *            invalid.
     */
    func evaluatedValue() -> Decimal? {
        let expressionParts = makeExpressionParts(safeText!)
        return safeText != nil ? evaluateExpression(parts: expressionParts, maxValue: maxValue) : nil
    }
    
    /**
     * ExpressionParts stores the type and components of a mathematical
     * expression.
     */
    private enum ExpressionParts {
        case InvalidExpression
        case SingleValue(value: Decimal)
        case MultiValue(firstOperand: Decimal, operation: Character, secondOperand: Decimal)
    }
    
    /**
     * - Parameters:
     *    - parts: The ExpressionParts fo be evaluated.
     *    - maxValue: An optional maximum value to be returned.
     *
     * - Returns: The expression parts evaluated into a decimal, up to an
     *            optional maximum value, or nil if the parts are invalid.
     */
    private func evaluateExpression(parts: ExpressionParts, maxValue: Decimal? = nil) -> Decimal? {
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
    
    /**
     * - Parameters:
     *    - expression: A potential mathematical expression in string form.
     *
     * - Returns: An ExpressionParts type representing the same expression as
     *            the string or ExpressionParts.InvalidExpression if there is
     *            no ExpressionParts representation of the string.
     */
    private func makeExpressionParts(_ expression: String) -> ExpressionParts {
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
        // For some reason CharacterSet isn't a subclass of Set
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
    /**
     * Called when the evaluated value of the text field changes, either due to
     * user input, or by directly setting setting `textField.text`.
     *
     * - Parameters:
     *    - textField: The text field whose evaluated value changed.
     *    - newValue: The updated value of the text field.
     */
    func textFieldChangedEvaluatedValue(_ textField: CalculatorTextField, to newValue: Decimal?)
}
