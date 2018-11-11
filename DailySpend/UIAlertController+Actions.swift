//
//  UIAlertController+Actions.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/9/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

extension UIAlertController {
    func addActions(_ actions: [UIAlertAction]) {
        for action in actions {
            self.addAction(action)
        }
    }
}
