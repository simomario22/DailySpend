//
//  ExpenseCellDescriptionTextView.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/23/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class ExpenseCellDescriptionTextView: UITextView {

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

    enum DescriptionViewTextStyle {
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
            self.textColor = .black
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

    var textViewDelegate: ExpenseCellDescriptionTextViewDelegate?

    init(delegate: ExpenseCellDescriptionTextViewDelegate) {
        super.init(frame: CGRect.zero, textContainer: nil)
        textViewDelegate = delegate
        self.delegate = self
        self.isScrollEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ExpenseCellDescriptionTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        textViewDelegate?.textViewDidBeginEditing?(textView)
    }

    func textViewDidChange(_ textView: UITextView) {
        #warning("make sure this does not get called when we change the text to placeholder text")
        textViewDelegate?.textViewDidChange?(textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textViewDelegate?.textViewDidEndEditing?(textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Hack-ily determine if the user pressed the return key, since there
        // isn't a better way to do this that I could find.
        if text == "\n" {
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

        return false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        let beginningRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        if style == .placeholder && textView.selectedTextRange != beginningRange {
            textView.selectedTextRange = beginningRange
        }
    }

}


protocol ExpenseCellDescriptionTextViewDelegate: UITextViewDelegate {
    func textViewDidReturn(_ textView: UITextView)
}
