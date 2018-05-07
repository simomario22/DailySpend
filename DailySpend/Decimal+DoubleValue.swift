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
}
