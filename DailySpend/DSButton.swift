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
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.pressedColor = self.tintColor

        self.layer.cornerRadius = 8
        self.layer.borderColor = self.tintColor.cgColor
        self.layer.borderWidth = 1

        self.backgroundColor = .clear

        self.setTitleColor(self.tintColor, for: .normal)
        self.setTitleColor(.white, for: .highlighted)
        self.setTitleColor(.white, for: .selected)

        let pressedColorImage = UIImage.withColor(pressedColor)
        self.setBackgroundImage(pressedColorImage, for: .highlighted)
        self.setBackgroundImage(pressedColorImage, for: .selected)

        self.clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
