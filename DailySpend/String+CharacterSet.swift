//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension String {

    func removeCharactersWhichAreActuallyUnicodeScalarsSoBeCareful(in charSet: CharacterSet) -> String {
        var withoutChars = ""
        for scalar in self.unicodeScalars {
            if !charSet.contains(scalar) {
                withoutChars.append(String(scalar))
            }
        }
        return withoutChars
    }
    
    func countOccurrences(ofString needle: String) -> Int? {
        if needle.isEmpty {
            return nil
        }
        var searchRange: Range<String.Index>?
        var count = 0
        while let foundRange = range(of: needle, options: [], range: searchRange) {
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
            count += 1
        }
        return count
    }
    
    func countOccurrences(ofCharacters set: CharacterSet) -> Int? {
        if set.isEmpty {
            return nil
        }
        var searchRange: Range<String.Index>?
        var count = 0
        while let foundRange = rangeOfCharacter(from: set, options: [], range: searchRange) {
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
            count += 1
        }
        return count
    }

    func containsAny(in set: CharacterSet) -> Bool {
        return set.isEmpty || rangeOfCharacter(from: set) != nil
    }
    
    /**
     * Determines the maximum font size this string can be, rendered with a
     * particular font `font` inside a contrained space of `size`, and returns
     * `font` in that size.
     *
     * - Parameters:
     *   - font: The font, set to the initial, desired font size.
     *   - maxSize: The size constraining the string.
     *   - minFontSize: Optional minimum font size to return.
     *
     * - Returns:
     * The font of maximum size that can render this string in constrained
     * space `maxSize`. Will be less than or equal to the size of the passed
     * in font, and greater than `minFontSize`, if specified.
     */
    func maximumFontSize(_ font: UIFont,
                     maxWidth: CGFloat?,
                     maxHeight: CGFloat?) -> CGFloat {
        var fontSize: CGFloat = font.pointSize
        
        var attr = [NSAttributedStringKey.font: font]
        var size = self.size(withAttributes: attr)
        
        // Continue to decrease size while one of the next two conditions is true:
        //   maxWidth is not equal to nil and the rendered size's width is greater than maxWidth
        //   maxHeight is not equal to nil and the rendered size's height is greater than maxHeight
        // AND the following is true:
        //   fontSize > minFontSize
        while ((maxWidth != nil && size.width > maxWidth!) ||
                (maxHeight != nil && size.height > maxHeight!)) &&
                fontSize > 1 {
            fontSize -= 1
            attr = [.font: font.withSize(fontSize)]
            size = self.size(withAttributes: attr)
        }
        return fontSize
    }
    
    func calculatedHeightForWidth(_ width: CGFloat, font: UIFont?, exclusionPaths: [UIBezierPath]) -> CGFloat {
        let textStorage = NSTextStorage(string: self)
        let textContainer = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        if let font = font {
            textStorage.addAttribute(.font, value: font, range: NSMakeRange(0, count))
        }
        textContainer.exclusionPaths = exclusionPaths
        textContainer.lineFragmentPadding = 0
        
        layoutManager.glyphRange(for: textContainer)
        return layoutManager.usedRect(for: textContainer).size.height
    }
    
    static func formatAsCurrency(amount: Decimal) -> String? {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        return currencyFormatter.string(from: amount.doubleValue as NSNumber)
    }
    
    static func formatAsCurrency(amount: Double) -> String? {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        return currencyFormatter.string(from: amount as NSNumber)
    }
}
