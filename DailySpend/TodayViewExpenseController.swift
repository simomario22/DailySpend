//
//  TodayViewExpenseController.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/5/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

struct ExpenseCellDatum {
    var shortDescription: String
    var amount: String
    var clean: Bool
}

class TodayViewExpensesController : NSObject, UITableViewDataSource, UITableViewDelegate {
    var tableView: UITableView
    var period: CalendarPeriod
    var expenses = [Expense?]()
    var expenseCellData = [ExpenseCellDatum]()
    
    init(tableView: UITableView, period: CalendarPeriod) {
        self.tableView = tableView
        self.period = period
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func loadExpensesForGoal(_ goal: Goal?) {
        if let goal = goal {
            expenses = goal.expensesIn(period: period)
        } else {
            expenses = []
            expenseCellData = []
        }
    }
}
