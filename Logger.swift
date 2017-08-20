//
//  Logger.swift
//  DailySpend
//
//  Created by Josh Sherick on 8/19/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

class Logger {
    static func debug(_ message: String) {
        let bundleID = Bundle.main.bundleIdentifier!
        if bundleID.contains("com.joshsherick.DailySpendTesting") {
            print(message)
        }
    }
    
    static func warning(_ message: String) {
        print(message)
    }
}
