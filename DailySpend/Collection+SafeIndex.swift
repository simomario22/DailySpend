//
//  Collection+SafeIndex.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/24/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//  From https://stackoverflow.com/a/30593673

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
