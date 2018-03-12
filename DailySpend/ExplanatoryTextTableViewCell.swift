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
    
    var explanatoryTextView: UITextView?
    var controlAreaBounds: CGRect {
        let height = explanatoryTextView == nil ? bounds.size.height : 44
        return CGRect(x: 0, y: 0, width: bounds.size.width, height: height)
    }
    
    static let defaultExplanatoryTextFont = UIFont.systemFont(ofSize: 14)
    
    var explanatoryTextFont = ExplanatoryTextTableViewCell.defaultExplanatoryTextFont {
        didSet {
            explanatoryTextView?.font = explanatoryTextFont
        }
    }
    
    var explanatoryTextColor = UIColor.lightGray {
        didSet {
            explanatoryTextView?.textColor = explanatoryTextColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if explanatoryTextView != nil {
            let width = bounds.size.width - (inset * 2)
            let height = explanatoryTextView!.intrinsicHeightForWidth(width)
            
            let labelFrame = CGRect(x: inset,
                                    y: controlAreaBounds.bottomEdge - (margin / 2),
                                    width: width,
                                    height: height)
            explanatoryTextView!.frame = labelFrame
        }
    }
    
    func addExclusionFrame(_ frame: CGRect) {
        let convertedFrame = self.convert(frame, to: explanatoryTextView)
        explanatoryTextView?.textContainer.exclusionPaths.append(UIBezierPath(rect: convertedFrame))
    }
    
    private func makeTextView() -> UITextView {
        let view = UITextViewWithoutMargins()
        view.isScrollEnabled = false
        view.isEditable = false
        view.font = explanatoryTextFont
        view.textColor = explanatoryTextColor
        view.backgroundColor = UIColor.clear
        view.textContainer.exclusionPaths = []
        return view
    }
    
    func setExplanatoryText(_ text: String?) {
        if text == nil {
            explanatoryTextView?.removeFromSuperview()
            explanatoryTextView = nil
            return
        }
        if explanatoryTextView == nil {
            explanatoryTextView = makeTextView()
        }
        explanatoryTextView!.text = text
        addSubview(explanatoryTextView!)
        self.setNeedsDisplay()
    }
    
    static func desiredHeight(_ explanatoryText: String,
                    font: UIFont = defaultExplanatoryTextFont,
                    width: CGFloat = UIScreen.main.bounds.size.width,
                    exclusionFrame: CGRect?) -> CGFloat {
        let textView = UITextViewWithoutMargins()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.text = explanatoryText
        textView.font = font
        
        if let exclusionFrame = exclusionFrame {
            let textViewFrame = CGRect(x: inset,
                                       y: 44 - (margin / 2),
                                       width: width - (inset * 2),
                                       height: exclusionFrame.bottomEdge + CGFloat(100))
            let intersection = textViewFrame.intersection(exclusionFrame)
            let convertedFrame = intersection.offsetBy(dx: -textViewFrame.origin.x,
                                                       dy: -textViewFrame.origin.y)

            textView.textContainer.exclusionPaths = [UIBezierPath(rect: convertedFrame)]
        }
        let widthWithoutMargins = width - (inset * 2)
        return textView.intrinsicHeightForWidth(widthWithoutMargins) + (44 - (margin / 2)) + (margin * 1.5)
    }
}
