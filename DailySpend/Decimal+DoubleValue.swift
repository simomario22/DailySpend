//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension Decimal {

    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
    
    var cgFloatValue: CGFloat {
        return CGFloat(NSDecimalNumber(decimal: self).doubleValue)
    }
    
    /**
     * Returns a number rounded to the nearest 1/power-th.
     *
     * - Parameters:
     *    - power: the 1/power to round to. Must be a power of 10.
     */
    func roundToNearest(th power: Double) -> Decimal {
        return Decimal(round(self.doubleValue * power) / power)
    }
}
