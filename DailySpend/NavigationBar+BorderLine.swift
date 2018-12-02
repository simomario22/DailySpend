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
