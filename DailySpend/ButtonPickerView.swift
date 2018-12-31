//
//  ButtonPickerView.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/9/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class ButtonPickerView: UIScrollView {
    var pickerDelegate: ButtonPickerViewDelegate?

    private var oldButtonTitles = [String]()
    var buttonTitles = [String]() {
        didSet {
            remakeViewIfNecessary()
        }
    }

    var rows: Int = 1 {
        didSet {
            self.setNeedsLayout()
        }
    }

    private var oldSelectedButtonIndex: Int = -1
    var selectedButtonIndex: Int = -1 {
        didSet {
            if selectedButtonIndex != oldSelectedButtonIndex {
                if let button = buttons[safe: oldSelectedButtonIndex] {
                    button.isSelected = false
                }

                if let button = buttons[safe: selectedButtonIndex] {
                    button.isSelected = true
                }
                oldSelectedButtonIndex = selectedButtonIndex
            }
        }
    }

    private var oldCustomButtonTitle: String? = nil
    var customButtonTitle: String? = "Custom" {
        didSet {
            remakeViewIfNecessary()
        }
    }

    private var buttons = [UIButton]()
    private var hasCustomTitle: Bool {
        return customButtonTitle != nil
    }

    private func remakeViewIfNecessary() {
        if buttonTitles == oldButtonTitles &&
            customButtonTitle == oldCustomButtonTitle {
            return
        }
        oldButtonTitles = buttonTitles
        oldCustomButtonTitle = customButtonTitle
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons = createButtons(from: buttonTitles)
        for (i, button) in buttons.enumerated() {
            button.add(for: .touchUpInside) {
                if i == 0 && self.hasCustomTitle {
                    self.pickerDelegate?.tappedCustomButton(in: self)
                } else {
                    let index = self.hasCustomTitle ? i - 1 : i
                    self.pickerDelegate?.tappedButton(in: self, at: index, with: self.buttonTitles[index])
                }
            }
            if i == selectedButtonIndex {
                button.isSelected = true
            }
            self.addSubview(button)
        }
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let layoutEngine = ButtonPickerLayoutEngine(
            componentHeight: bounds.size.height,
            rows: rows
        )

        let (size, frames) = layoutEngine.makeButtonsFramesForCorrespondingStrings(
            strings: (hasCustomTitle ? [customButtonTitle!] : []) + buttonTitles,
            font: UIFont.systemFont(ofSize: UIFont.systemFontSize)
        )

        for (i, button) in buttons.enumerated() {
            if i == 0 && hasCustomTitle {
                button.titleLabel!.font = UIFont.italicSystemFont(ofSize: size)
            } else {
                button.titleLabel!.font = button.titleLabel!.font.withSize(size)
            }
            button.frame = frames[i]
        }

        if let lastButtonEdge = buttons.last?.frame.rightEdge {
            self.contentSize = CGSize(width: lastButtonEdge + layoutEngine.xMargin, height: bounds.size.height)
        }
    }

    private func createButtons(from buttonTitles: [String]) -> [UIButton] {
        var buttons = [UIButton]()
        for title in (hasCustomTitle ? [customButtonTitle!] : []) + buttonTitles {
            let button = DSButton()
            button.setTitle(title, for: .normal)
            buttons.append(button)
        }
        return buttons
    }
}

// TODO: Refactor this into the ButtonPickerView class.
fileprivate class ButtonPickerLayoutEngine {
    /**
     * The right edge of the rightmost button in the row corresponding to
     * the array index.
     */
    private var maxRowX: [CGFloat]

    /**
     * The y value representing the top of a row.
     */
    private var topRowY: [CGFloat]

    /**
     * The height of each row, without margins.
     */
    private let rowHeight: CGFloat

    /**
     * The sizes of the strings that will appear in the buttons.
     */
    private func makeStringSizes(font: UIFont, strings: [String]) -> [CGSize] {
        return strings.map { (string: String) -> CGSize in
            return string.calculatedSize(font: font)
        }
    }

    /**
     * The font size calculated as the maximum that will fit in a button when
     * considering the properties passed to the constructor.
     */
    private func maxFontSize(font: UIFont, strings: [String]) -> CGFloat {
        var fontSize: CGFloat = 30
        for string in strings {
            // Since letters can be different heights, check all of them and get the max.
            let candidate = string.maximumFontSize(font, maxHeight: rowHeight)
            if candidate < fontSize {
                fontSize = candidate
            }
        }
        return fontSize
    }

    var xMargin: CGFloat = 4
    var yMargin: CGFloat = 2
    var padding: CGFloat = 4
    var scrollBarMargin: CGFloat = 6

    init(componentHeight: CGFloat, rows: Int) {
        let componentHeightWithMargin = componentHeight - scrollBarMargin
        self.maxRowX = [CGFloat]()
        for _ in 0..<rows {
            self.maxRowX.append(xMargin)
        }

        self.rowHeight = ((componentHeightWithMargin - yMargin) / CGFloat(rows)) - yMargin

        self.topRowY = [CGFloat]()
        for row in 0..<rows {
            self.topRowY.append(yMargin + ((self.rowHeight + yMargin) * CGFloat(row)))
        }
    }

    /**
     * Returns frames for buttons big enough to contain strings in the same
     * order those strings were passed to the constructor.
     */
    func makeButtonsFramesForCorrespondingStrings(strings: [String], font: UIFont) -> (fontSize: CGFloat, buttonFrames: [CGRect]) {
        let fontSize = maxFontSize(font: font, strings: strings)
        let sizedFont = font.withSize(fontSize)
        let stringSizes = makeStringSizes(font: sizedFont, strings: strings)

        let rows = maxRowX.count
        var frames = [CGRect]()

        var currentRow = 0
        for size in stringSizes {
            let frame = CGRect(
                x: maxRowX[currentRow],
                y: topRowY[currentRow],
                width: max(rowHeight, size.width + (padding * 2)),
                height: rowHeight
            )
            maxRowX[currentRow] += frame.width + xMargin
            frames.append(frame)
            currentRow = (currentRow + 1) % rows
        }
        return (fontSize: fontSize, buttonFrames: frames)
    }
}

protocol ButtonPickerViewDelegate {
    func tappedButton(in picker: ButtonPickerView, at index: Int, with label: String)
    func tappedCustomButton(in picker: ButtonPickerView)
}
