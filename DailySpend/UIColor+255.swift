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

    class var underspent: UIColor {
        return UIColor(red255: 167, green: 234, blue: 140)
    }

    class var overspent: UIColor {
        return UIColor(red255: 232, green: 89, blue: 91)
    }

    class var paused: UIColor {
        return UIColor(red255: 100, green: 100, blue: 200)
    }
    
    class var tint: UIColor {
        return UIColor(red255: 0, green: 129, blue: 234)
    }
    
    class var disabled: UIColor {
        return UIColor(white: 0.492583, alpha: 0.35)
    }

    class var navigationBarBackground: UIColor {
        return UIColor(red255: 254, green: 254, blue: 254)
    }
}
