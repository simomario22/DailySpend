//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class IndentedLabelTableViewCell: UITableViewCell {
    private let indentWidth: CGFloat = 20
    
    private let inset: CGFloat = 15
    private let margin: CGFloat = 8
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let textLabel = textLabel {
            let indentationAmount = CGFloat(indentationLevel) * indentationWidth
            let indentedFrame = CGRect(
                x: inset + indentationAmount,
                y: margin,
                width: frame.size.width - inset * 2 - indentationAmount,
                height: frame.size.height - margin * 2
            )
            textLabel.frame = indentedFrame
        }
    }
    
    func setIndentationLevel(level: Int) {
        indentationLevel = level
        self.setNeedsLayout()
    }
}
