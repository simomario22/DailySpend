//
//  UITextField+Border.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class BorderedTextField: UITextField {
    override func layoutSubviews() {
        super.layoutSubviews()
        if bottomBorder != nil {
            // Update the size of our border.
            let width = bottomBorder!.frame.size.height
            bottomBorder!.frame = CGRect(x: 0,
                                         y: bounds.size.height - width,
                                         width: bounds.size.width,
                                         height: width)
        }
    }
    
    private var bottomBorder: CALayer?
    
    func addBottomBorder(color: UIColor, width: CGFloat) {
        bottomBorder?.removeFromSuperlayer()
        bottomBorder = CALayer()
        bottomBorder!.backgroundColor = color.cgColor
        bottomBorder!.frame = CGRect(x: 0,
                                     y: bounds.size.height - width,
                                     width: bounds.size.width,
                                     height: width)
        self.layer.addSublayer(bottomBorder!)
        self.layer.masksToBounds = true
    }
}
