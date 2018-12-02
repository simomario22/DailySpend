//
//  BorderedViews.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/1/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class BorderedView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if bottomBorder != nil {
            // Update the size of our border.
            let width = bottomBorder!.frame.size.height
            bottomBorder!.frame = CGRect(
                x: 0,
                y: bounds.size.height,
                width: bounds.size.width,
                height: width
            )
        }
    }
    
    private var bottomBorder: CALayer?
    
    func addOutsideBottomBorder(color: UIColor, width: CGFloat) {
        bottomBorder?.removeFromSuperlayer()
        bottomBorder = CALayer()
        bottomBorder!.backgroundColor = color.cgColor
        bottomBorder!.frame = CGRect(
            x: 0,
            y: bounds.size.height,
            width: bounds.size.width,
            height: width
        )
        self.layer.addSublayer(bottomBorder!)
    }
}
