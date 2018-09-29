//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension UINavigationBar {
    func showBorderLine() {
        findBorderImage()?.isHidden = false
    }
    
    func hideBorderLine() {
        findBorderImage()?.isHidden = true
    }
    
    private func findBorderImage() -> UIImageView? {
        return self.subviews
            .flatMap { $0.subviews }
            .compactMap { $0 as? UIImageView }
            .filter {
                $0.bounds.size.width == self.bounds.size.width &&
                $0.bounds.size.height <= 2
            }
            .first
    }
}

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

class BorderedToolbar: UIToolbar {
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
