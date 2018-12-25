//
//  ExpenseSuggestionDataProvider.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/24/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class ExpenseSuggestionDataProvider {
    private let defaultsKey = "quickSuggestStrings"

    func quickSuggestStrings() -> [String] {
//        let values = ["Restaurant", "Groceries", "Gas", "Snack", "Potato 1", "Potato 2"]
//        return values
        return UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
    }

    func setQuickSuggestStrings(strings: [String]) {
        UserDefaults.standard.set(strings, forKey: defaultsKey)
    }
}
