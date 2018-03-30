//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ValueTableViewCell: ExplanatoryTextTableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let textLabel = textLabel {
            let frame = textLabel.frame
            let newFrame = CGRect(x: frame.origin.x,
                                   y: controlAreaBounds.topEdge + margin,
                                   width: frame.size.width,
                                   height: controlAreaBounds.size.height - margin * 2)
            textLabel.frame = newFrame
        }
        
        if let detailTextLabel = detailTextLabel {
            let frame = detailTextLabel.frame
            let newFrame = CGRect(x: frame.origin.x,
                                   y: controlAreaBounds.topEdge + margin,
                                   width: frame.size.width,
                                   height: controlAreaBounds.size.height - margin * 2)
            detailTextLabel.frame = newFrame
        }
        
    }
    
    func valueWasSet() {
        self.setNeedsLayout()
    }

    static func desiredHeight(_ explanatoryText: String,
                                font: UIFont = defaultExplanatoryTextFont,
                                width: CGFloat = UIScreen.main.bounds.size.width) -> CGFloat {
        return super.desiredHeight(explanatoryText, font: font, width: width)
    }
}
