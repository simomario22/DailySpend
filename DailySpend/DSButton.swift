//
//  DSButton.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/23/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class DSButton : UIButton {
    var pressedColor = UIColor.clear

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

        self.pressedColor = self.tintColor

        self.layer.cornerRadius = 8
        self.layer.borderColor = self.tintColor.cgColor
        self.layer.borderWidth = 1

        self.nonHighlightedBackgroundColor = .clear
        self.backgroundColor = .clear

        self.setTitleColor(self.tintColor, for: .normal)
        self.setTitleColor(.white, for: .highlighted)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
