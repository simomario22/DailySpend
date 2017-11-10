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

    class var overspent: UIColor {
        return UIColor(red255: 179, green: 0, blue: 0)
    }

    class var underspent: UIColor {
        return UIColor(red255: 0, green: 179, blue: 0)
    }

    class var paused: UIColor {
        return UIColor(red255: 0, green: 0, blue: 179)
    }
}
