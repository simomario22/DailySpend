//
//  ExpenseViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class AddExpenseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ImageSelectorController, GoalSelectorDelegate {
    private let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    
    private var cellCreator: TableViewCellHelper!
    
    private var imageSelector: ImageSelectorView!
    private var tableView: UITableView!
    
    private var editingDate = false
    
    var delegate: AddExpenseDelegate?
    
    private var amount: Decimal?
    private var amountSetupFinished = false
    private var shortDescription: String?
    private var shortDescriptionSetupFinished = false
    private var transactionDay: CalendarDay!
    private var transactionDaySetupFinished = false
    private var notes: String!
    private var goal: Goal?
    private var goalSetupFinished = false
    var expenseId: NSManagedObjectID?

    var imageSelectorDataSource: ImageSelectorDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up table view.
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        cellCreator = TableViewCellHelper(tableView: tableView)

        let expense = (Expense.inContext(expenseId) as? Expense)
        
        // Set up singleton image selector to be re-used.
        imageSelector = ImageSelectorView()
        imageSelectorDataSource = ImageSelectorDataSource(expense: expense)
        imageSelector.selectorDelegate = imageSelectorDataSource
        imageSelector.selectorController = self
        imageSelector.removeAllImages()
        imageSelectorDataSource.provide(to: imageSelector.addImage)
        imageSelector.scrollToRightEdge()
        
        if let expense = expense {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, save)
            self.navigationItem.title = "Edit Expense"
            
            if !amountSetupFinished {
                amount = expense.amount
                amountSetupFinished = true
            }
            if !shortDescriptionSetupFinished {
                shortDescription = expense.shortDescription
                shortDescriptionSetupFinished = true
            }
            if !transactionDaySetupFinished {
                transactionDay = expense.transactionDay
                transactionDaySetupFinished = true
            }
            if !goalSetupFinished {
                goal = expense.goal
                goalSetupFinished = true
            }
            
            notes = expense.notes

        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, save)
            self.navigationItem.title = "New Expense"
            
            if !amountSetupFinished {
                amount = nil
                amountSetupFinished = true
            }
            if !shortDescriptionSetupFinished {
                shortDescription = nil
                shortDescriptionSetupFinished = true
            }
            if !transactionDaySetupFinished {
                transactionDay = CalendarDay()
                transactionDaySetupFinished = true
            }
            if !goalSetupFinished {
                goal = nil
                goalSetupFinished = true
            }
            
            notes = ""

        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) {
            self.view.endEditing(false)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func setupExpense(
        expenseId: NSManagedObjectID? = nil,
        goal: Goal? = nil,
        transactionDay: CalendarDay? = nil,
        amount: Decimal?? = nil,
        shortDescription: String?? = nil
    ) {
        if let expenseId = expenseId {
            self.expenseId = expenseId
        }

        if let goal = goal {
            self.goal = goal
            self.goalSetupFinished = true
        }
        
        if let transactionDay = transactionDay {
            self.transactionDay = transactionDay
            self.transactionDaySetupFinished = true
        }
        
        if let amount = amount {
            self.amount = amount
            self.amountSetupFinished = true
        }
        
        if let shortDescription = shortDescription {
            self.shortDescription = shortDescription
            self.shortDescriptionSetupFinished = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
        var validation: (valid: Bool, problem: String?)!
        let isNew = (expenseId == nil)
        let context = appDelegate.persistentContainer.newBackgroundContext()
        context.performAndWait {
            var expense: Expense!
            if isNew {
                expense = Expense(context: context)
                expense.dateCreated = Date()
            } else {
                expense = Expense.inContext(expenseId!, context: context)
            }

            let goal = Goal.inContext(self.goal, context: context)
            validation = expense.propose(
                amount: amount,
                shortDescription: shortDescription,
                transactionDay: transactionDay,
                notes: notes,
                goal: goal
            )

            if validation.valid && !imageSelectorDataSource.saveImages(expense: expense, context: context) {
                validation.valid = false
                validation.problem = "Could not save images associated with the expense."
            }

            if !validation.valid && isNew {
                context.rollback()
            } else {
                if context.hasChanges {
                    try! context.save()
                }
                self.view.endEditing(false)
                expenseId = expense.objectID
            }
        }

        if let expenseId = expenseId {
            let expenseOnViewContext: Expense = Expense.inContext(expenseId)!
            if isNew {
                delegate?.createdExpenseFromModal(expenseOnViewContext)
            } else {
                delegate?.editedExpenseFromModal(expenseOnViewContext)
            }
            if self.navigationController!.viewControllers[0] == self {
                self.navigationController!.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController!.popViewController(animated: true)
            }
        } else {
            let alert = UIAlertController(
                title: "Couldn't Save",
                message: validation.problem!,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: "Okay",
                style: .default,
                handler: nil
            ))
            present(alert, animated: true, completion: nil)
        }
    }

    enum ExpenseViewCellType {
        case DescriptionCell
        case AmountCell
        case TransactionDayDisplayCell
        case TransactionDayDatePickerCell
        case ImageSelectorCell
        case NotesCell
        case GoalsCell
    }
    
    func cellTypeForIndexPath(indexPath: IndexPath) -> ExpenseViewCellType {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                return .DescriptionCell
            } else {
                return .AmountCell
            }
        } else if section == 1 {
            if row == 0 {
                return .TransactionDayDisplayCell
            } else {
                return .TransactionDayDatePickerCell
            }
        } else if section == 2 {
            if row == 0 {
                return .ImageSelectorCell
            } else {
                return .NotesCell
            }
        } else if section == 3 {
            return .GoalsCell
        }
        
        return .DescriptionCell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellCreator == nil {
            return UITableViewCell()
        }
        
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .DescriptionCell:
            return cellCreator.textFieldDisplayCell(
                title: "Description",
                placeholder: "e.g. \"Groceries\"",
                text: shortDescription,
                changedToText: { (text: String, _) in
                    self.shortDescription = text == "" ? nil : text
                },
                didBeginEditing: { _ in
                    self.datePickerCellResignFirstResponder()
            })
        case .AmountCell:
            return cellCreator.currencyDisplayCell(
                title: "Amount",
                amount: amount,
                changedToAmount: { amount in
                    self.amount = amount
                },
                didBeginEditing: { _ in
                    self.datePickerCellResignFirstResponder()
                }
            )
        case .TransactionDayDisplayCell:
            return cellCreator.dateDisplayCell(
                label: "Transaction Date",
                day: transactionDay,
                tintColor: editingDate ? view.tintColor : nil
            )
        case .TransactionDayDatePickerCell:
            return cellCreator.datePickerCell(
                day: transactionDay,
                changedToDay: { day in
                    self.transactionDay = day
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
                }
            )
        case .ImageSelectorCell:
            return cellCreator.imageSelectorCell(selector: imageSelector)
        case .NotesCell:
            return cellCreator.longFormTextInputCell(
                text: self.notes,
                didBeginEditing: { _ in
                    self.datePickerCellResignFirstResponder()
                },
                changedToText: { (text) in
                    self.notes = text
                }
            )
        case .GoalsCell:
            return cellCreator.valueDisplayCell(
                labelText: "Goals",
                valueText: goal?.shortDescription ?? "None",
                detailIndicator: true
            )
        }
    }
    
    private func datePickerCellResignFirstResponder() {
        if self.editingDate {
            self.editingDate = false
            tableView.beginUpdates()
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
            tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
            tableView.endUpdates()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return editingDate ? 2 : 1
        case 2:
            return 2
        case 3:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .TransactionDayDisplayCell:
            return indexPath
        case .GoalsCell:
            return indexPath
        default:
            return nil
        }
    }

    func openDateForEditing() {
        editingDate = true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .TransactionDayDisplayCell:
            tableView.beginUpdates()
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
            if editingDate {
                editingDate = false
                tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
            } else {
                editingDate = true
                tableView.insertRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.endUpdates()
            self.view.endEditing(false)
        case .GoalsCell:
            let goalSelectorVC = GoalSelectorViewController()
            goalSelectorVC.setSelectedGoal(goal: goal)
            let text = "Expenses attached to a child goal are also part of " +
                       "its parents' expenses."
            goalSelectorVC.parentSelectionHelperText = text
            goalSelectorVC.showParentSelection = true
            goalSelectorVC.delegate = self
            navigationController?.pushViewController(goalSelectorVC, animated: true)
            
        default: return // No feasable case
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .ImageSelectorCell:
            return 104
        case .TransactionDayDatePickerCell:
            return 216
        default:
            return 44
        }
    }
    
    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?, sender: Any?) {
        self.present(vc, animated: animated, completion: completion)
    }
    
    func dismissedGoalSelectorWithSelectedGoal(_ goal: Goal?) {
        self.goal = goal
        tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .fade)
    }
    
    func interactedWithImageSelectorViewByTapping() {
        tableView.endEditing(false)
    }
}

protocol AddExpenseDelegate {
    func createdExpenseFromModal(_ expense: Expense)
    func editedExpenseFromModal(_ expense: Expense)
}
