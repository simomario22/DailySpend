//
//  ExpenseCellDescriptionTextView.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/23/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class PlaceholderTextView: UITextView {

    var placeholder: String? {
        didSet {
            if self.userText?.isEmpty ?? true {
                self.text = placeholder
            }
        }
    }
    var isPlaceholderItalic: Bool = false {
        didSet {
            drawStyle()
        }
    }

    /**
     * The text that is interactable and changeable by the user.
     * I.e. not placeholder text.
     */
    var userText: String? {
        get {
            return style == .normal ? self.text : nil
        }
        set {
            if newValue != nil && !newValue!.isEmpty {
                style = .normal
                self.text = newValue
            } else {
                style = .placeholder
                self.text = placeholder
            }
        }
    }

    var userTextColor: UIColor = .black {
        didSet {
            if userText != nil && !userText!.isEmpty {
                self.textColor = userTextColor
            }
        }
    }

    /**
     * True if user entered newlines should be allowed by pressing the return
     * key in this text view.
     *
     * Has no effect on text that is pasted with newlines.
     */
    var allowsUserEnteredNewlines: Bool = false

    private enum DescriptionViewTextStyle {
        case normal
        case placeholder
    }

    private var _style: DescriptionViewTextStyle = .normal {
        didSet {
            drawStyle()
        }
    }

    private var style: DescriptionViewTextStyle {
        get {
            return _style
        }
        set {
            if newValue != _style {
                _style = newValue
            }
        }
    }

    private func drawStyle() {
        switch style {
        case .normal:
            let pointSize = self.font?.pointSize ?? UIFont.systemFontSize
            self.font = UIFont.systemFont(ofSize: pointSize)
            self.textColor = userTextColor
        case .placeholder:
            let pointSize = self.font?.pointSize ?? UIFont.systemFontSize
            if isPlaceholderItalic {
                self.font = UIFont.italicSystemFont(ofSize: pointSize)
            } else {
                self.font = UIFont.systemFont(ofSize: pointSize)
            }
            self.textColor = .textPlaceholder
        }
    }

    var textViewDelegate: PlaceholderTextViewDelegate?

    init(delegate: PlaceholderTextViewDelegate) {
        super.init(frame: CGRect.zero, textContainer: nil)
        textViewDelegate = delegate
        self.delegate = self
        self.isScrollEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlaceholderTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        let beginningRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        if style == .placeholder && textView.selectedTextRange != beginningRange {
            textView.selectedTextRange = beginningRange
        }
        textViewDelegate?.textViewDidBeginEditing?(textView)
    }

    func textViewDidChange(_ textView: UITextView) {
        textViewDelegate?.textViewDidChange?(textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textViewDelegate?.textViewDidEndEditing?(textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Hack-ily determine if the user pressed the return key, since there
        // isn't a better way to do this that I could find.
        if !allowsUserEnteredNewlines && text == "\n" {
            textViewDelegate?.textViewDidReturn(textView)
            return false
        }

        // Implement "placeholder" behavior.
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)

        if !newText.isEmpty && style == .normal {
            return true
        } else if !newText.isEmpty && style == .placeholder && newText != placeholder {
            style = .normal
            textView.text = text
        } else {
            textView.text = placeholder
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            style = .placeholder
        }
        delegate?.textViewDidChange?(self)
        return false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        let beginningRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        if style == .placeholder && textView.selectedTextRange != beginningRange {
            textView.selectedTextRange = beginningRange
        }
    }

}


protocol PlaceholderTextViewDelegate: UITextViewDelegate {
    /**
     * Called when the user presses return in a text field.
     *
     * If `allowNewlines` is `true`, this function will never be called.
     */
    func textViewDidReturn(_ textView: UITextView)
}
