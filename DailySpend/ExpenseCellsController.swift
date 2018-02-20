//
//  ExpenseCellsController.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/25/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class ExpenseCellsController {
    private var day: CalendarDay
    private var delegate: ExpenseCellsControllerDelegate
    
    init(delegate: ExpenseCellsControllerDelegate, day: CalendarDay) {
        self.delegate = delegate
        self.day = day
        
    }
    
    public func numberOfCells() -> Int {
        return 0
    }
    
    public func configureCellForIndex(_ index: Int, cell: ExpenseTableViewCell) -> ExpenseTableViewCell {
        return cell
    }
}

struct CellState {
    var dataSource: ExpenseProvider
    var clean: Bool
    var new: Bool
}

protocol ExpenseCellsControllerDelegate {
    func reloadCell(index: Int)
}
