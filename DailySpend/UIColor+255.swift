//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension UIColor {
    convenience init(red255: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red255 / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1)
    }
    
    convenience init(red255: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.init(red: red255 / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
}
