//
//  LongFormEntryTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/27/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import UIKit

class LongFormEntryTableViewCell: UITableViewCell {
    // Constants
    private let margin: CGFloat = 8
    private let inset: CGFloat = 15

    private var descriptionLabel: UILabel!
    private var textView: PlaceholderTextView!

    private var calculatedHeight: CGFloat = -1

    var descriptionText: String? {
        get {
            return descriptionLabel.text
        }
        set {
            descriptionLabel.text = newValue
        }
    }

    var isDescriptionHidden: Bool {
        get {
            return descriptionLabel.isHidden
        }
        set {
            descriptionLabel.isHidden = newValue
        }
    }

    func setDescriptionWeight(bold: Bool) {
        let defaultSize = UIFont.labelFontSize
        if bold {
            descriptionLabel.font = UIFont.boldSystemFont(ofSize: defaultSize)
        } else {
            descriptionLabel.font = UIFont.systemFont(ofSize: defaultSize)
        }
    }

    var valueText: String? {
        get {
            return textView.userText
        }

        set {
            textView.userText = newValue
        }
    }

    var valuePlaceholder: String? {
        get {
            return textView.placeholder
        }

        set {
            textView.placeholder = newValue
        }
    }

    var isValueFieldEditable: Bool {
        get {
            return textView.isEditable
        }
        set {
            textView.isEditable = newValue
        }

    }

    var beganEditing: ((LongFormEntryTableViewCell) -> ())?
    var endedEditing: ((String?) -> ())?
    var changedValue: ((String?) -> ())?
    var changedCellHeight: ((CGFloat) -> ())?

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutOwnSubviews()
    }

    func layoutOwnSubviews() {
        let defaultHeight = (44 - (margin * 2))
        if descriptionLabel != nil {
            let leftSide = inset
            let rightSide = margin
            descriptionLabel.frame = CGRect(
                x: leftSide,
                y: margin,
                width: self.bounds.size.width - leftSide - rightSide,
                height: defaultHeight
            )
        }

        if textView != nil {
            let top = descriptionLabel.isHidden ? margin : descriptionLabel.frame.bottomEdge
            let leftSide = inset
            let rightSide = margin
            let width = self.bounds.size.width - leftSide - rightSide
            let height = (textView.userText ?? textView.placeholder)?.calculatedHeightForWidth(width, font: textView.font)
            textView.frame = CGRect(
                x: leftSide,
                y: top,
                width: width,
                height: max(height ?? 0, defaultHeight * 2)
            )

        }

        let newCalculatedHeight = textView.frame.bottomEdge + margin
        if newCalculatedHeight != calculatedHeight {
            calculatedHeight = newCalculatedHeight
            changedCellHeight?(calculatedHeight)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        descriptionLabel = UILabel(frame: CGRect.zero)
        textView = PlaceholderTextView(delegate: self)
        textView.allowsUserEnteredNewlines = true
        textView.smartInsertDeleteType = .no
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.systemFont(ofSize: UIFont.labelFontSize)

        let gr = UITapGestureRecognizer(target: self, action: #selector(textViewFirstResponder))
        self.addGestureRecognizer(gr)

        self.addSubviews([
            descriptionLabel,
            textView,
        ])
    }

    @objc func textViewFirstResponder() {
        self.textView.becomeFirstResponder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    /**
     * Recalculates the cell height on next layout and fires a notification with
     * the new height.
     */
    func resetCellHeight() {
        calculatedHeight = -1
    }

    /**
     * Will synchronously notify receiver via `changedCellHeight` of height
     * updates.
     */
    func notifyHeightReceiver() {
        layoutOwnSubviews()
    }
}

extension LongFormEntryTableViewCell: PlaceholderTextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        beganEditing?(self)
    }

    func textViewDidChange(_ textView: UITextView) {
        changedValue?(self.valueText)
        setNeedsLayout()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        endedEditing?(self.valueText)
    }

    func textViewDidReturn(_ textView: UITextView) {
        textView.resignFirstResponder()
    }
}
