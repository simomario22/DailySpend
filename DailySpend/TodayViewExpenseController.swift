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
    var shortDescription: String?
    var amount: Decimal?
    var clean: Bool
    init(_ shortDescription: String?, _ amount: Decimal?, _ clean: Bool) {
        self.shortDescription = shortDescription
        self.amount = amount
        self.clean = clean
    }
    
    init() {
        self.init(nil, nil, true)
    }
}

class TodayViewExpensesController : NSObject, UITableViewDataSource, UITableViewDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
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

        let row = indexPath.row
        
        return cellCreator.expenseCell(
            description: expenseData.shortDescription,
            undescribed: undescribed,
            amount: expenseData.amount,
            showPlus: isAddCell && expenseData.clean,
            showDetailDisclosure: !(isAddCell && expenseData.clean),
            tappedSave: { (shortDescription: String?, amount: Decimal?, resignFirstResponder) in
                if !self.expenseCellData[row].clean {
                    if !self.saveExpense(at: row - 1) {
                        return
                    }
                }
                
                self.tableView.beginUpdates()
                resignFirstResponder()
                self.expenseCellData[row].clean = true
                self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .fade)
                
                if isAddCell {
                    // Make a new add cell.
                    self.expenseCellData.insert(ExpenseCellDatum(), at: 0)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                }

                self.tableView.endUpdates()

            }, tappedCancel: { expenseCell, resignFirstResponder in
                resignFirstResponder()
                if isAddCell {
                    expenseCell.setPlusButton(show: true, animated: true)
                    expenseCell.setDetailDisclosure(show: false, animated: true)
                    self.expenseCellData[row] = ExpenseCellDatum()
                    expenseCell.amountField.text = nil
                    expenseCell.descriptionField.text = nil
                } else if !self.expenseCellData[row].clean {
                    let e = self.expenses[row - 1]
                    self.expenseCellData[row] = ExpenseCellDatum(e.shortDescription, e.amount, true)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                UIView.animate(withDuration: 0.2, animations: {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                })
            }, selectedDetailDisclosure: {
                print("selected detail disclosure")
            }, didBeginEditing: { (expenseCell: ExpenseTableViewCell) in
                self.mostRecentlyEditedCellIndex = indexPath
                expenseCell.setPlusButton(show: false, animated: true)
                expenseCell.setDetailDisclosure(show: true, animated: true)
                self.expenseCellData[row].clean = false
                tableView.beginUpdates()
                tableView.endUpdates()
            }, didEndEditing: { (expenseCell: ExpenseTableViewCell) in
                print("ended editing")
            }, changedToDescription: { (newDescription: String?) in
                let desc = newDescription == "" ? nil : newDescription
                print("changed to description \(String(describing: desc))")
                self.expenseCellData[row].shortDescription = desc
            }, changedToAmount: { (newAmount: Decimal?) in
                print("changed to amount \(String(describing: newAmount))")
                self.expenseCellData[row].amount = newAmount
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
        expenseCellData.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
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
    
    func saveExpense(at index: Int) -> Bool {
        let datum = expenseCellData[index + 1]
        var justCreated = false
        var expense: Expense! = index >= 0 ? expenses[index] : nil
        if expense == nil {
            justCreated = true
            expense = Expense(context: context)
            expense.dateCreated = Date()
            expense.transactionDay = CalendarDay()
            expense.goals?.insert(goal)
        }
        
        let validation = expense.propose(
            amount: datum.amount,
            shortDescription: datum.shortDescription,
            transactionDay: expense!.transactionDay,
            notes: expense!.notes,
            dateCreated: expense!.dateCreated
        )
        
        if validation.valid {
            appDelegate.saveContext()
            if justCreated {
                expenses.insert(expense, at: 0)
            } else {
                expenses[index] = expense
            }
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
        if let goal = goal {
            self.goal = goal
            let todayPeriod = CalendarPeriod(
                dateInGMTPeriod: Date(),
                period: goal.period,
                beginningDateOfPeriod: goal.start!
            )!
            expenses = goal.getExpenses(period: todayPeriod)
            expenseCellData = []
            for e in expenses {
                let d = ExpenseCellDatum(e.shortDescription, e.amount, true)
                expenseCellData.append(d)
            }
            expenseCellData.insert(ExpenseCellDatum(), at: 0) // Add Cell
        } else {
            expenses = []
            expenseCellData = []
        }
        tableView.reloadData()
    }
}

