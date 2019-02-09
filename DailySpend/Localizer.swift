//
//  LocalizedString.swift
//  DailySpend
//
//  Created by Josh Sherick on 2/5/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import Foundation

class Localizer {
    static let shared = Localizer()

    lazy var localizableDictionary: NSDictionary! = {
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "plist") {
            return NSDictionary(contentsOfFile: path)
        }
        return nil
    }()

    func localize(key: String) -> String {
        guard let dict = localizableDictionary else {
            return key
        }

        let components = key.split(separator: ".")
        var subDict = dict
        for component in components {
            let subKey = String(component)
            if let value = subDict.value(forKey: subKey) as? NSDictionary {
                subDict = value
            } else if let value = subDict.value(forKey: "value") as? NSString {
                return value as String
            } else {
                return key
            }
        }

        return key
    }
}

extension String {
    var localized: String {
        return Localizer.shared.localize(key: self)
    }
}
