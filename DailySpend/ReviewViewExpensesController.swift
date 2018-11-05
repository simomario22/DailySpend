//
//  ReviewViewExpenseController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/2/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class ReviewViewExpensesController {
    struct ExpenseCellDatum {
        var shortDescription: String?
        var amountDescription: String
        init(_ shortDescription: String?, _ amountDescription: String) {
            self.shortDescription = shortDescription
            self.amountDescription = amountDescription
        }
    }
    private var goal: Goal?
    private var expenseCellData: [ExpenseCellDatum]
    private var section: Int
    private var cellCreator: TableViewCellHelper
    
    init(section: Int, cellCreator: TableViewCellHelper) {
        self.goal = nil
        self.expenseCellData = []
        self.section = section
        self.cellCreator = cellCreator
    }
    
    func setGoal(newGoal: Goal?) {
        self.goal = newGoal
        if let goal = self.goal {
            for expense in goal.sortedExpenses ?? [] {
                expenseCellData.append(ExpenseCellDatum(
                    expense.shortDescription,
                    String.formatAsCurrency(amount: expense.amount ?? 0) ?? ""
                ))
            }
        } else {
            expenseCellData = []
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenseCellData.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let description = expenseCellData[row].shortDescription ?? "No Description"
        let value = expenseCellData[row].amountDescription
        return cellCreator.optionalDescriptorValueCell(
            description: description,
            undescribed: expenseCellData[row].shortDescription == nil,
            value: value,
            detailButton: true
        )
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        return
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}