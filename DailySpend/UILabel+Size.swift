//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension UILabel {
    func intrinsicHeightForWidth(_ width: CGFloat) -> CGFloat {
        // Set number of lines for this calculation to work properly.
        let oldLines = numberOfLines
        numberOfLines = 0
        let height = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        numberOfLines = oldLines
        return height
    }
    
    func intrinsicWidthForHeight(_ height: CGFloat) -> CGFloat {
        return sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: height)).width
    }
    
    func resizeFontToFit(desiredFontSize: CGFloat? = nil, minFontSize: CGFloat? = nil) {
        guard let text = self.text,
              let font = self.font else {
                return
        }
        let sizedFont = desiredFontSize == nil ? font : font.withSize(desiredFontSize!)
        let newFontSize = text.maximumFontSize(sizedFont, maxWidth: bounds.size.width, maxHeight: bounds.size.height)
        self.font = font.withSize(max(newFontSize, minFontSize ?? 1))
    }
}
