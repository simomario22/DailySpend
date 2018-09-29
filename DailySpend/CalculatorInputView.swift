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
//  CalculatorInputView.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/4/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//

import UIKit

class CalculatorButton: UIButton {
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
}

class CalculatorInputView: UIView, UIInputViewAudioFeedback {
    let colFourProportion: Double = 1 / 6
    let margin: CGFloat = 2.5
    
    var delegate: CalculatorInputViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red:0.82, green:0.83, blue:0.86, alpha:1.00)
        addAllButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    private struct ButtonDefinition {
        var title: String
        var row: Int
        var col: Int
        var dark: Bool
        init(_ title: String, _ row: Int, _ col: Int, _ dark: Bool) {
            self.title = title
            self.row = row
            self.col = col
            self.dark = dark
        }
    }
    
    private func makeButton(_ definition: ButtonDefinition) -> UIButton {
        let buttonFrame = frameForButton(row: definition.row, col: definition.col)
        let button = CalculatorButton(frame: buttonFrame)
        button.setTitle(definition.title, for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 24.0)
        button.layer.cornerRadius = margin * 2
        
        let lightColor = UIColor(red:0.99, green:0.98, blue:0.99, alpha:1.00)
        let darkColor = UIColor(red:0.66, green:0.70, blue:0.75, alpha:1.00)
        button.nonHighlightedBackgroundColor = definition.dark ? darkColor : lightColor
        
        return button
    }
    
    private func addAllButtons() {
        let buttonDefs: [ButtonDefinition] = [
            ButtonDefinition("1", 0, 0, false),
            ButtonDefinition("2", 0, 1, false),
            ButtonDefinition("3", 0, 2, false),
            ButtonDefinition("4", 1, 0, false),
            ButtonDefinition("5", 1, 1, false),
            ButtonDefinition("6", 1, 2, false),
            ButtonDefinition("7", 2, 0, false),
            ButtonDefinition("8", 2, 1, false),
            ButtonDefinition("9", 2, 2, false),
            ButtonDefinition("0", 3, 1, false),
            ButtonDefinition(".", 3, 0, true),
            ButtonDefinition("÷", 0, 3, true),
            ButtonDefinition("×", 1, 3, true),
            ButtonDefinition("−", 2, 3, true),
            ButtonDefinition("+", 3, 3, true),
        ]
        
        for buttonDef in buttonDefs {
            let button = makeButton(buttonDef)
            button.add(for: .touchDown, {
                UIDevice.current.playInputClick()
            })
            button.add(for: .touchUpInside, {
                self.delegate?.tappedKey(buttonDef.title)
            })

            addSubview(button)
        }
        
        let backspaceButtonDef = ButtonDefinition("", 3, 2, true)
        let backspaceButton = makeButton(backspaceButtonDef)
        let backspaceImage = UIImage(named: "VENCalculatorIconBackspace")
        backspaceButton.setImage(backspaceImage, for: .normal)
        func tap() {
            UIDevice.current.playInputClick()
            self.delegate?.tappedBackspace()
        }
        
        var holdDelayTimer: Timer?
        var repeatPressTimer: Timer?
        
        backspaceButton.add(for: .touchDown, {
            tap()
            holdDelayTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (_) in
                tap()
                repeatPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in tap() })
            })
        })
        
        backspaceButton.add(for: [.touchUpInside, .touchUpOutside], {
            holdDelayTimer?.invalidate()
            repeatPressTimer?.invalidate()
            holdDelayTimer = nil
            repeatPressTimer = nil
        })

        addSubview(backspaceButton)
    }
    
    private func frameForButton(row: Int, col: Int) -> CGRect {
        let sideMargin = margin * 2
        let insetFrame = frame.insetBy(dx: sideMargin, dy: sideMargin)
        let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        let height = (insetFrame.size.height - bottomInset) / 4
        let colFourWidth = insetFrame.size.width * CGFloat(colFourProportion)
        let firstThreeColsWidth = (insetFrame.size.width - colFourWidth) / 3
        let width = col < 3 ? firstThreeColsWidth : colFourWidth
        
        let x = sideMargin + (CGFloat(col) * firstThreeColsWidth)
        let y = sideMargin + (CGFloat(row) * height)
        let fullFrame = CGRect(x: x, y: y, width: width, height: height)
        return fullFrame.insetBy(dx: margin, dy: margin)
    }
    
    var enableInputClicksWhenVisible: Bool = true

}

protocol CalculatorInputViewDelegate {
    func tappedKey(_ key: String)
    func tappedBackspace()
}
