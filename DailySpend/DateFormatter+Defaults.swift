//
//  File.swift
//  DailySpend
//
//  Created by Josh Sherick on 2/3/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import Foundation

extension DateFormatter {
    class func shortDate() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short
        return dateFormatter
    }
}
