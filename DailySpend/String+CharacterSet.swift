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
    
    /**
     * - Returns:
     * The decimal representation of the number created by removing
     * all non numerical characters from the string and dividing the result
     * by 100.
     */
    func parseValidAmount(maxLength: Int?) -> Double {
        var negative = false
        if self.count > 0 &&
            self[startIndex] == "-" &&
            self.components(separatedBy: "-").count == 1 {
            negative = true
        }
        let nonNumbers = CharacterSet(charactersIn: "0123456789").inverted
        var s = self.removeCharactersWhichAreActuallyUnicodeScalarsSoBeCareful(in: nonNumbers)
        
        let length = s.lengthOfBytes(using: .ascii)
        if length == 0 {
            s = "0"
        } else if maxLength != nil && length > maxLength! {
            let endIndex = s.index(s.endIndex, offsetBy: maxLength! - length)
            s = String(s[..<endIndex])
        }
        
        return (Double(s)! / 100) * (negative ? -1 : 1)
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
