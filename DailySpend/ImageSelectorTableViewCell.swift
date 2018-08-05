//
//  ChoiceTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/5/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ImageSelectorTableViewCell : UITableViewCell {
    let standardInset: CGFloat = 15
    let margin: CGFloat = 8

    var imageSelector: ImageSelectorView?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let selector = imageSelector {
            let originalFrame = selector.frame
            var textWidth: CGFloat = 0
            if let text = textLabel?.text {
                textWidth = text.calculatedWidthForHeight(textLabel!.frame.size.height, font: textLabel!.font)
            }
            let x = textWidth + standardInset + margin
            let newFrame = CGRect(
                x: x,
                y: 0,
                width: bounds.size.width - x - standardInset,
                height: bounds.size.height
            ).insetBy(dx: margin, dy: margin)

            if !newFrame.equalTo(originalFrame) {
                selector.frame = newFrame
                selector.recreateButtons()
            }
        }
    }
    
    func setImageSelector(_ selector: ImageSelectorView) {
        if let current = self.imageSelector {
            if current != selector {
                current.removeFromSuperview()
            }
        }
        self.imageSelector = selector
        self.addSubview(selector)
        self.setNeedsLayout()
    }
}
