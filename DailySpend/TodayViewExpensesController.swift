//
//  TodayViewExpenseController.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/5/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class TodayViewExpensesController : NSObject, UITableViewDataSource, UITableViewDelegate, AddExpenseDelegate {
    private class ExpenseCellDatum {
        var shortDescription: String?
        var amount: Decimal?
        var clean: Bool
        var day: CalendarDay
        var expandedHeight: CGFloat
        var collapsedHeight: CGFloat
        init(_ shortDescription: String?, _ amount: Decimal?, _ day: CalendarDay?, _ clean: Bool) {
            self.shortDescription = shortDescription
            self.amount = amount
            self.day = day ?? CalendarDay()
            self.clean = clean
            self.expandedHeight = 100
            self.collapsedHeight = 160
        }
        
        convenience init() {
            self.init(nil, nil, nil, true)
        }
    }
    
    /**
     * Create a class to wrap the row with so we can update it in for use in
     * the cell for row at index path closures.
     */
    private class UpdatingRow {
        var row: Int
        init(row: Int) {
            self.row = row
        }
    }
    
    private var updatingRows = [UpdatingRow]()
    private func insertNewUpdatingRow() {
        for updatingRow in updatingRows {
            updatingRow.row += 1
        }
        updatingRows.insert(UpdatingRow(row: 0), at: 0)
    }
    private func appendNewUpdatingRow() {
        updatingRows.append(UpdatingRow(row: updatingRows.count))
    }
    private func removeUpdatingRow(at index: Int) {
        updatingRows.remove(at: index)
        for i in index..<updatingRows.count {
            updatingRows[i].row -= 1
        }
    }

    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    var delegate: TodayViewExpensesDelegate?
    
    private var tableView: UITableView
    private var present: (UIViewController, Bool, (() -> Void)?) -> ()
    private var goal: Goal!
    private var currentInterval: CalendarIntervalProvider? = nil
    private var expenses = [Expense]()
    private var expenseCellData = [ExpenseCellDatum]()
    private var cellCreator: TableViewCellHelper
    private var expenseSuggestor: ExpenseSuggestionDataProvider
    private var mostRecentlyEditedCellIndex: IndexPath = IndexPath(row: NSNotFound, section: 0)
    
    init(
        tableView: UITableView,
        present: @escaping (UIViewController, Bool, (() -> Void)?) -> ()
    ) {
        self.tableView = tableView
        self.present = present
        self.cellCreator = TableViewCellHelper(tableView: tableView)
        self.expenseSuggestor = ExpenseSuggestionDataProvider()
        self.tableView.keyboardDismissMode = .interactive
        super.init()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        
        if let size = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
            let bottom = size.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.3
            UIView.animate(withDuration: duration) {
                self.tableView.contentInset = contentInsets
                self.tableView.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.3
        UIView.animate(withDuration: duration) {
            self.tableView.contentInset = UIEdgeInsets.zero
            self.tableView.scrollIndicatorInsets = UIEdgeInsets.zero
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenseCellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isAddCell = indexPath.row == 0
        let expenseData = expenseCellData[indexPath.row]
        let undescribed = !isAddCell && expenseData.shortDescription == nil
        let expense = !isAddCell ? self.expenses[indexPath.row - 1] : nil
        let datum = self.expenseCellData[indexPath.row]
        let updatingRow = self.updatingRows[indexPath.row]
        
        return cellCreator.expenseCell(
            description: expenseData.shortDescription,
            undescribed: undescribed,
            amount: expenseData.amount,
            day: expenseData.day,
            showPlus: isAddCell && expenseData.clean,
            showButtonPicker: isAddCell && expenseData.shortDescription == nil,
            buttonPickerValues: expenseSuggestor.quickSuggestStrings(),
            showDetailDisclosure: !(isAddCell && expenseData.clean),
            tappedSave: { (shortDescription: String?, amount: Decimal?, resignFirstResponder) in
                if !datum.clean {
                    if !self.saveExpense(at: updatingRow.row - 1, with: datum) {
                        return
                    }
                }
                
                self.tableView.performBatchUpdates({
                    resignFirstResponder()
                    datum.clean = true
                    self.tableView.reloadRows(at: [IndexPath(row: updatingRow.row, section: 0)], with: .fade)

                    if isAddCell {
                        // Make a new add cell.
                        self.createNewAddCellDatum()
                        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    }
                }, completion: { _ in
                    if self.currentInterval != nil &&
                       !self.currentInterval!.contains(date: datum.day.start) {
                        self.tableView.performBatchUpdates({
                            let rowIndex = updatingRow.row
                            let index = rowIndex - 1

                            self.expenses.remove(at: index)
                            self.expenseCellData.remove(at: rowIndex)
                            self.removeUpdatingRow(at: rowIndex)
                            tableView.deleteRows(at: [IndexPath(row: rowIndex, section: 0)], with: .left)
                        })
                    }
                })
            }, tappedCancel: { resign, resetCleanAddCell in
                resign()
                if isAddCell {
                    let buttonStrings = self.expenseSuggestor.quickSuggestStrings()
                    resetCleanAddCell(buttonStrings)
                    datum.amount = nil
                    datum.shortDescription = nil
                    datum.clean = true
                } else if !datum.clean {
                    datum.amount = expense!.amount
                    datum.shortDescription = expense!.shortDescription
                    datum.clean = true
                    self.tableView.reloadRows(at: [IndexPath(row: updatingRow.row, section: 0)], with: .automatic)
                }
                UIView.animate(withDuration: 0.2, animations: {
                    self.tableView.performBatchUpdates({})
                })
        }, selectedDetailDisclosure: { (shouldHighlightDate: Bool) in
                let addExpenseVC = AddExpenseViewController()
                addExpenseVC.delegate = self
                let navCtrl = UINavigationController(rootViewController: addExpenseVC)
                if isAddCell {
                    addExpenseVC.setupPartiallyCreatedExpense(
                        goal: self.goal,
                        transactionDay: datum.day,
                        amount: datum.amount,
                        shortDescription: datum.shortDescription
                    )
                } else {
                    addExpenseVC.setupPartiallyEditedExpense(
                        expense: expense!,
                        transactionDay: datum.day,
                        amount: datum.amount,
                        shortDescription: datum.shortDescription
                    )
                }
                self.present(navCtrl, true, nil)
                
            }, didBeginEditing: { (expenseCell: ExpenseTableViewCell) in
                if datum.clean {
                    self.mostRecentlyEditedCellIndex = IndexPath(row: updatingRow.row, section: 0)
                    expenseCell.setPlusButton(show: false, animated: true)
                    expenseCell.setDetailDisclosure(show: true, animated: true)
                    datum.clean = false
                    self.tableView.performBatchUpdates({})
                }
                // Scroll after any potential keyboard height changes fire.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                    self.tableView.scrollToRow(at: IndexPath(row: updatingRow.row, section: 0), at: .middle, animated: true)
                })
            }, changedToDescription: { (newDescription: String?) in
                let desc = newDescription == "" ? nil : newDescription
                datum.shortDescription = desc
            }, changedToAmount: { (newAmount: Decimal?) in
                datum.amount = newAmount
            }, changedToDay: { (newDay: CalendarDay) in
                datum.day = newDay
            }, changedCellHeight: { (newCollapsedHeight: CGFloat, newExpandedHeight: CGFloat) in
                tableView.performBatchUpdates({
                    datum.collapsedHeight = newCollapsedHeight
                    datum.expandedHeight = newExpandedHeight
                })
            }
        )
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        let index = indexPath.row - 1
        let expense = expenses[index]
        
        context.delete(expense)
        appDelegate.saveContext()
        expenses.remove(at: index)
        expenseCellData.remove(at: indexPath.row)
        removeUpdatingRow(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        delegate?.expensesChanged(goal: goal)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let datum = expenseCellData[indexPath.row]
        return datum.clean ? datum.collapsedHeight : datum.expandedHeight
    }
    
    private func createNewAddCellDatum() {
        expenseCellData.insert(ExpenseCellDatum(), at: 0)
        insertNewUpdatingRow()
    }
    
    private func saveExpense(at index: Int, with datum: ExpenseCellDatum) -> Bool {
        var justCreated = false
        var expense: Expense! = index >= 0 ? expenses[index] : nil
        if expense == nil {
            justCreated = true
            expense = Expense(context: context)
            expense.dateCreated = Date()
        }
        
        let validation = expense.propose(
            amount: datum.amount,
            shortDescription: datum.shortDescription,
            transactionDay: datum.day,
            notes: expense!.notes,
            dateCreated: expense!.dateCreated,
            goal: goal
        )
        
        if validation.valid {
            appDelegate.saveContext()
            if justCreated {
                expenses.insert(expense, at: 0)
            } else {
                expenses[index] = expense
            }
            delegate?.expensesChanged(goal: goal)
            return true
        } else {
            if justCreated {
                context.delete(expense)
                appDelegate.saveContext()
            }

            let alert = UIAlertController(title: "Couldn't Save",
                                          message: validation.problem!,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay",
                                          style: .default,
                                          handler: nil))
            present(alert, true, nil)
            return false
        }
    }
    
    func loadExpensesForGoal(_ goal: Goal?) {
        if let goal = goal,
            let currentInterval = goal.incrementalPaymentInterval(for: CalendarDay().start) {
            self.goal = goal
            self.expenses = goal.getExpenses(interval: currentInterval)
            self.currentInterval = currentInterval
            
            expenseCellData = []
            for e in expenses {
                let d = ExpenseCellDatum(e.shortDescription, e.amount, e.transactionDay, true)
                expenseCellData.append(d)
                appendNewUpdatingRow()
            }
            createNewAddCellDatum()
        } else {
            expenses = []
            expenseCellData = []
        }
        tableView.reloadData()
    }

    func createdExpenseFromModal(_ expense: Expense) {
        // Needs to check this condition before caling `expenseChanged` because
        // this class will have a different `self.goal` after that function
        // returns.
        if expense.goal != self.goal && !self.goal.isParentOf(goal: expense.goal!) {
            delegate?.expensesChanged(goal: expense.goal!)
            return
        }
        delegate?.expensesChanged(goal: goal)
        expenses.insert(expense, at: 0)
        let newDatum = ExpenseCellDatum(expense.shortDescription, expense.amount, expense.transactionDay, true)
        expenseCellData[0] = newDatum
        
        tableView.endEditing(false)
        createNewAddCellDatum()
        
        let addCellIndexPath = IndexPath(row: 0, section: 0)
        let newCellIndexPath = IndexPath(row: 1, section: 0)
        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: [addCellIndexPath], with: .fade)
            self.tableView.insertRows(at: [addCellIndexPath], with: .automatic)
            self.tableView.selectRow(at: addCellIndexPath, animated: true, scrollPosition: .none)
        }, completion: { _ in
            self.tableView.deselectRow(at: newCellIndexPath, animated: true)
            if self.currentInterval != nil &&
                !self.currentInterval!.contains(date: expense.transactionDay!.start) {
                self.tableView.performBatchUpdates({
                    let rowIndex = newCellIndexPath.row
                    let index = rowIndex - 1

                    self.expenses.remove(at: index)
                    self.expenseCellData.remove(at: rowIndex)
                    self.removeUpdatingRow(at: rowIndex)
                    self.tableView.deleteRows(at: [IndexPath(row: rowIndex, section: 0)], with: .left)
                })
            }
        })
    }
    
    func editedExpenseFromModal(_ expense: Expense) {
        // Needs to check this condition before caling `expenseChanged` because
        // this class will have a different `self.goal` after that function
        // returns.
        if expense.goal != self.goal && !self.goal.isParentOf(goal: expense.goal!) {
            delegate?.expensesChanged(goal: expense.goal!)
            return
        }
        delegate?.expensesChanged(goal: goal)
        guard let index = expenses.index(of: expense) else {
            Logger.debug("Edited an expense, but could not find it in TodayViewController expenses.")
            return
        }

        let newDatum = ExpenseCellDatum(expense.shortDescription, expense.amount, expense.transactionDay, true)
        expenses[index] = expense
        expenseCellData[index + 1] = newDatum
        let indexPath = IndexPath(row: index + 1, section: 0)
        self.tableView.performBatchUpdates({
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }, completion: { _ in
            self.tableView.deselectRow(at: indexPath, animated: true)
            if self.currentInterval != nil &&
               !self.currentInterval!.contains(date: expense.transactionDay!.start) {
                self.tableView.performBatchUpdates({
                    let rowIndex = indexPath.row
                    let index = rowIndex - 1

                    self.expenses.remove(at: index)
                    self.expenseCellData.remove(at: rowIndex)
                    self.removeUpdatingRow(at: rowIndex)
                    self.tableView.deleteRows(at: [IndexPath(row: rowIndex, section: 0)], with: .left)
                })
            }
        })
    }

    func reloadAddCell() {
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
    }
}

protocol TodayViewExpensesDelegate {
    /**
     * Called when there is a potential change to the set of expenses currently
     * loaded for this goal.
     *
     * - Parameters:
     *    - goal: The goal associated with the expense.
     */
    func expensesChanged(goal: Goal)
}
