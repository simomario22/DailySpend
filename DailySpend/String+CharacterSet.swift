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
}
