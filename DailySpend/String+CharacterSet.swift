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
    
    func parseValidAmount(maxLength: Int?) -> Double {
        var negative = false
        if self.characters.count > 0 &&
            self.characters[self.startIndex] == "-" &&
            self.components(separatedBy: "-").count == 1 {
            negative = true
        }
        let nonNumbers = CharacterSet(charactersIn: "0123456789").inverted
        var s = self.removeCharactersWhichAreActuallyUnicodeScalarsSoBeCareful(in: nonNumbers)
        
        let length = s.lengthOfBytes(using: .ascii)
        if length == 0 {
            s = "0"
        } else if maxLength != nil && length > maxLength! {
            s = s.substring(to: s.index(s.endIndex, offsetBy: maxLength! - length))
        }
        
        return (Double(s)! / 100) * (negative ? -1 : 1)
    }
    
    static func formatAsCurrency(amount: Double) -> String? {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        return currencyFormatter.string(from: amount as NSNumber)
    }
}
