//
//  ChoiceTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/5/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ChoiceTableViewCell : UITableViewCell {
    let standardInset: CGFloat = 15
    let margin: CGFloat = 8
    let checkmarkWidth: CGFloat = 15
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let textLabel = textLabel {
            let accessoryViewWidth = checkmarkWidth + margin
            var leftInset = self.standardInset
            let rightInset = self.standardInset + accessoryViewWidth
            if textLabel.textAlignment == .center {
                leftInset = rightInset
            }
            
            let newFrame = CGRect(x: frame.origin.x + leftInset,
                                  y: 0,
                                  width: frame.size.width - (rightInset + leftInset),
                                  height: frame.size.height)
            textLabel.frame = newFrame
        }
    }
    
}
