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
        init(_ shortDescription: String?, _ amount: Decimal?, _ clean: Bool) {
            self.shortDescription = shortDescription
            self.amount = amount
            self.clean = clean
        }
        
        convenience init() {
            self.init(nil, nil, true)
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
    
    let collapsedCellSize: CGFloat = 44
    let expandedCellSize: CGFloat = 88

    private var tableView: UITableView
    private var present: (UIViewController, Bool, (() -> Void)?) -> ()
    private var goal: Goal!
    private var expenses = [Expense]()
    private var expenseCellData = [ExpenseCellDatum]()
    private var cellCreator: TableViewCellHelper
    private var mostRecentlyEditedCellIndex: IndexPath = IndexPath(row: NSNotFound, section: 0)
    
    init(
        tableView: UITableView,
        present: @escaping (UIViewController, Bool, (() -> Void)?) -> ()
    ) {
        self.tableView = tableView
        self.present = present
        self.cellCreator = TableViewCellHelper(tableView: tableView)
        self.tableView.keyboardDismissMode = .onDrag
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
            var contentInsets: UIEdgeInsets
            if UIApplication.shared.statusBarOrientation.isPortrait {
                contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: size.height, right: 0)
            } else {
                contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: size.width, right: 0)
            }

            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.3
            UIView.animate(withDuration: duration) {
                self.tableView.contentInset = contentInsets
                self.tableView.scrollIndicatorInsets = contentInsets
                self.tableView.scrollToRow(at: self.mostRecentlyEditedCellIndex, at: .middle, animated: true)
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
            showPlus: isAddCell && expenseData.clean,
            showDetailDisclosure: !(isAddCell && expenseData.clean),
            tappedSave: { (shortDescription: String?, amount: Decimal?, resignFirstResponder) in
                if !datum.clean {
                    if !self.saveExpense(at: updatingRow.row - 1, with: datum) {
                        return
                    }
                }
                
                self.tableView.beginUpdates()
                resignFirstResponder()
                datum.clean = true
                self.tableView.reloadRows(at: [IndexPath(row: updatingRow.row, section: 0)], with: .fade)
                
                if isAddCell {
                    // Make a new add cell.
                    self.createNewAddCellDatum()
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                }

                self.tableView.endUpdates()
            }, tappedCancel: { expenseCell, resignFirstResponder in
                resignFirstResponder()
                if isAddCell {
                    expenseCell.setPlusButton(show: true, animated: true)
                    expenseCell.setDetailDisclosure(show: false, animated: true)
                    datum.amount = nil
                    datum.shortDescription = nil
                    datum.clean = true
                    expenseCell.amountField.text = nil
                    expenseCell.descriptionField.text = nil
                } else if !datum.clean {
                    datum.amount = expense!.amount
                    datum.shortDescription = expense!.shortDescription
                    datum.clean = true
                    self.tableView.reloadRows(at: [IndexPath(row: updatingRow.row, section: 0)], with: .automatic)
                }
                UIView.animate(withDuration: 0.2, animations: {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                })
            }, selectedDetailDisclosure: {
                let addExpenseVC = AddExpenseViewController()
                addExpenseVC.delegate = self
                let navCtrl = UINavigationController(rootViewController: addExpenseVC)
                if isAddCell {
                    addExpenseVC.setupPartiallyCreatedExpense(
                        goal: self.goal,
                        transactionDay: CalendarDay(),
                        amount: datum.amount,
                        shortDescription: datum.shortDescription
                    )
                } else {
                    addExpenseVC.setupPartiallyEditedExpense(
                        expense: expense!,
                        amount: datum.amount,
                        shortDescription: datum.shortDescription
                    )
                }
                self.present(navCtrl, true, nil)
                
            }, didBeginEditing: { (expenseCell: ExpenseTableViewCell) in
                self.mostRecentlyEditedCellIndex = IndexPath(row: updatingRow.row, section: 0)
                expenseCell.setPlusButton(show: false, animated: true)
                expenseCell.setDetailDisclosure(show: true, animated: true)
                datum.clean = false
                tableView.beginUpdates()
                tableView.endUpdates()
            }, didEndEditing: { (expenseCell: ExpenseTableViewCell) in
            }, changedToDescription: { (newDescription: String?) in
                let desc = newDescription == "" ? nil : newDescription
                datum.shortDescription = desc
            }, changedToAmount: { (newAmount: Decimal?) in
                datum.amount = newAmount
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
        if expenseCellData[indexPath.row].clean {
            return collapsedCellSize
        } else {
            return expandedCellSize
        }
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
            expense.transactionDay = CalendarDay()
        }
        
        let validation = expense.propose(
            amount: datum.amount,
            shortDescription: datum.shortDescription,
            transactionDay: expense!.transactionDay,
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
            let currentPeriod = goal.incrementalPaymentInterval(for: CalendarDay().start) {
            self.goal = goal
            expenses = goal.getExpenses(period: currentPeriod)
            
            expenseCellData = []
            for e in expenses {
                let d = ExpenseCellDatum(e.shortDescription, e.amount, true)
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
        if expense.goal != self.goal {
            delegate?.expensesChanged(goal: expense.goal!)
            return
        }
        delegate?.expensesChanged(goal: goal)
        expenses.insert(expense, at: 0)
        let newDatum = ExpenseCellDatum(expense.shortDescription, expense.amount, true)
        expenseCellData[0] = newDatum
        
        tableView.endEditing(false)
        createNewAddCellDatum()
        
        let addCellIndexPath = IndexPath(row: 0, section: 0)
        let newCellIndexPath = IndexPath(row: 1, section: 0)
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [addCellIndexPath], with: .fade)
        self.tableView.insertRows(at: [addCellIndexPath], with: .automatic)
        self.tableView.endUpdates()
        self.tableView.selectRow(at: newCellIndexPath, animated: true, scrollPosition: .none)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tableView.deselectRow(at: newCellIndexPath, animated: true)
        }
    }
    
    func editedExpenseFromModal(_ expense: Expense) {
        // Needs to check this condition before caling `expenseChanged` because
        // this class will have a different `self.goal` after that function
        // returns.
        if expense.goal != self.goal {
            delegate?.expensesChanged(goal: expense.goal!)
            return
        }
        delegate?.expensesChanged(goal: goal)
        guard let index = expenses.index(of: expense) else {
            Logger.debug("Edited an expense, but could not find it in TodayViewController expenses.")
            return
        }

        let newDatum = ExpenseCellDatum(expense.shortDescription, expense.amount, true)
        expenses[index] = expense
        expenseCellData[index + 1] = newDatum
        let indexPath = IndexPath(row: index + 1, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .fade)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
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
