//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension UILabel {
    var textIntrinsicSize: CGSize {
        return text == nil ? CGSize() : text!.size(withAttributes: [.font: font])
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
    
    func textFitsInBounds() -> Bool {
        guard let text = self.text,
              let font = self.font else {
                return true
        }
        let minSize = text.size(withAttributes: [.font: font])
        return frame.size.width >= minSize.width && frame.size.height >= minSize.height
    }
}
