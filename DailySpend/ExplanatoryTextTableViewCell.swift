//
//  ExplanatoryTextTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/11/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

class ExplanatoryTextTableViewCell: UITableViewCell {
    static let margin: CGFloat = 8
    static let inset: CGFloat = 15
    let margin: CGFloat = ExplanatoryTextTableViewCell.margin
    let inset: CGFloat = ExplanatoryTextTableViewCell.inset
    
    var explanatoryTextLabel: UILabel?
    var controlAreaBounds: CGRect {
        let height = explanatoryTextLabel == nil ? bounds.size.height : 44
        return CGRect(x: 0, y: 0, width: bounds.size.width, height: height)
    }
    
    static let defaultExplanatoryTextFont = UIFont.systemFont(ofSize: 14)
    
    var explanatoryTextFont = ExplanatoryTextTableViewCell.defaultExplanatoryTextFont {
        didSet {
            explanatoryTextLabel?.font = explanatoryTextFont
        }
    }
    
    var explanatoryTextColor = UIColor.lightGray {
        didSet {
            explanatoryTextLabel?.textColor = explanatoryTextColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if explanatoryTextLabel != nil {
            let width = bounds.size.width - (inset * 2)
            let boundingSize = CGSize(width: width, height: .greatestFiniteMagnitude)
            let height = explanatoryTextLabel!.sizeThatFits(boundingSize).height
            
            let labelFrame = CGRect(x: inset,
                                    y: controlAreaBounds.bottomEdge + (margin / 2),
                                    width: width, height: height)
            explanatoryTextLabel!.frame = labelFrame
        }
    }
    
    private func makeTextLabel() -> UILabel {
        let label = UILabel()
        label.font = explanatoryTextFont
        label.textColor = explanatoryTextColor
        label.numberOfLines = 0
        return label
    }
    
    func setExplanatoryText(_ text: String?) {
        if text == nil {
            explanatoryTextLabel?.removeFromSuperview()
            explanatoryTextLabel = nil
        }
        if explanatoryTextLabel == nil {
            explanatoryTextLabel = makeTextLabel()
        }
        explanatoryTextLabel!.text = text
        addSubview(explanatoryTextLabel!)
        self.setNeedsDisplay()
    }
    
    static func desiredHeightForExplanatoryText(_ text: String,
                                                font: UIFont = defaultExplanatoryTextFont,
                                                width: CGFloat = UIScreen.main.bounds.size.width) -> CGFloat {
        let label = UILabel()
        label.text = text
        label.font = font
        let widthWithoutMargins = width - (inset * 2)
        return label.intrinsicHeightForWidth(widthWithoutMargins) + 44 + (margin * 2)
    }
}
