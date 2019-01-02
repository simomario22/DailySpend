//
//  ReviewViewExpenseController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/2/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class ReviewViewExpensesController: NSObject, AddExpenseDelegate, ReviewEntityDataProvider {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    
    var delegate: ReviewEntityControllerDelegate
    
    struct ExpenseCellDatum {
        var shortDescription: String?
        var amountDescription: String
        init(_ shortDescription: String?, _ amountDescription: String) {
            self.shortDescription = shortDescription
            self.amountDescription = amountDescription
        }
    }
    private var goal: Goal?
    private var interval: CalendarIntervalProvider?
    private var expenses: [Expense]
    private var expenseCellData: [ExpenseCellDatum]
    private var section: Int
    private var cellCreator: TableViewCellHelper
    private var present: (UIViewController, Bool, (() -> Void)?) -> ()
    
    init(
        section: Int,
        cellCreator: TableViewCellHelper,
        delegate: ReviewEntityControllerDelegate,
        present: @escaping (UIViewController, Bool, (() -> Void)?) -> ()
    ) {
        self.goal = nil
        self.expenses = []
        self.expenseCellData = []
        self.section = section
        self.cellCreator = cellCreator
        self.delegate = delegate
        self.present = present
    }
    
    private func makeExpenseCellDatum(_ expense: Expense) -> ExpenseCellDatum {
        return ExpenseCellDatum(
            expense.shortDescription,
            String.formatAsCurrency(amount: expense.amount ?? 0) ?? ""
        )
    }
    
    func presentCreateModal() {
        guard let goal = goal else {
            return
        }
        let addExpenseVC = AddExpenseViewController()
        // Start by assuming today.
        var defaultTransactionDay = CalendarDay()
        if interval != nil && !interval!.contains(interval: defaultTransactionDay) {
            defaultTransactionDay = CalendarDay(dateInDay: interval!.start)
        }
        addExpenseVC.setupExpense(goal: goal, transactionDay: defaultTransactionDay)
        addExpenseVC.delegate = self
        let navCtrl = UINavigationController(rootViewController: addExpenseVC)
        self.present(navCtrl, true, nil)
    }
    
    private func remakeExpenses() {
        expenseCellData = []
        expenses = []
        guard let goal = self.goal,
              let interval = self.interval else {
            return
        }
        
        expenses = goal.getExpenses(context: appDelegate.persistentContainer.viewContext, interval: interval)
        for expense in expenses {
            expenseCellData.append(makeExpenseCellDatum(expense))
        }
    }
    
    func setGoal(_ newGoal: Goal?, interval: CalendarIntervalProvider) {
        self.goal = newGoal
        self.interval = interval
        remakeExpenses()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(expenseCellData.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if expenseCellData.isEmpty {
            return cellCreator.centeredLabelCell(labelText: "No Expenses", disabled: true)
        }
        
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
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        self.tableView(tableView, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if expenseCellData.count == 0 {
            return
        }
        
        let addExpenseVC = AddExpenseViewController()
        addExpenseVC.delegate = self
        addExpenseVC.expenseId = expenses[indexPath.row].objectID
        let navCtrl = UINavigationController(rootViewController: addExpenseVC)
        self.present(navCtrl, true, nil)

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return expenseCellData.count > 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        let context = appDelegate.persistentContainer.newBackgroundContext()
        let row = indexPath.row
        let expense = context.object(with: expenses[row].objectID)
        context.delete(expense)
        if context.hasChanges {
            try! context.save()
        }
        expenses.remove(at: row)
        expenseCellData.remove(at: row)
        delegate.deletedEntity(at: indexPath, use: .automatic, isOnlyEntity: expenses.count == 0)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func createdExpenseFromModal(_ expense: Expense) {
        remakeExpenses()
        let row = expenses.firstIndex(of: expense)
        let path = IndexPath(row: row ?? 0, section: section)
        delegate.addedEntity(
            with: expense.transactionDay!,
            within: expense.goal!,
            at: path,
            use: .automatic,
            isOnlyEntity: expenseCellData.count == 1
        )
    }
    
    func editedExpenseFromModal(_ expense: Expense) {
        guard let origRow = expenses.firstIndex(of: expense) else {
            return
        }
        
        remakeExpenses()
        if let newRow = expenses.firstIndex(of: expense) {
            // This expense is still in this view, but did not necesarily
            // switch rows.
            expenseCellData[newRow] = makeExpenseCellDatum(expense)
            delegate.editedEntity(
                with: expense.transactionDay!,
                within: expense.goal!,
                at: IndexPath(row: origRow, section: section),
                movedTo: origRow != newRow ? IndexPath(row: newRow, section: section) : nil,
                use: .automatic
            )
        } else {
            // This expense switched goals or intervals and is no longer in
            // this view.
            delegate.editedEntity(
                with: expense.transactionDay!,
                within: expense.goal!,
                at: IndexPath(row: origRow, section: section),
                movedTo: nil,
                use: .automatic
            )
        }
    }
}
