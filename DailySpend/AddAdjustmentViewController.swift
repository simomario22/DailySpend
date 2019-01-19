//
//  AddAdjustmentViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class AddAdjustmentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GoalSelectorDelegate {

    private let appDelegate = (UIApplication.shared.delegate as! AppDelegate)

    private var cellCreator: TableViewCellHelper!
    
    var delegate: AddAdjustmentDelegate?
    private var tableView: UITableView!
    
    private var editingAmountField: UITextField? = nil
    private var editingFirstDate = false
    private var editingLastDate = false
    
    var adjustmentId: NSManagedObjectID?

    private var goal: Goal?
    private var goalSetupFinished = false
    
    private var firstDayEffective: CalendarDay!
    private var firstDayEffectiveSetupFinished = false
    
    private var lastDayEffective: CalendarDay!
    private var lastDayEffectiveSetupFinished = false
    
    private var amountPerDay: Decimal = 0
    private var shortDescription: String = ""
    private var deduct = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up table view.
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)

        
        let adjustment = (Adjustment.inContext(adjustmentId) as? Adjustment)
        
        if let adjustment = adjustment {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, save)
            shortDescription = adjustment.shortDescription!
            
            if adjustment.amountPerDay! < 0 {
                deduct = true
            }
            amountPerDay = abs(adjustment.amountPerDay!)
            
            if !goalSetupFinished {
                goal = adjustment.goal
                goalSetupFinished = true
            }
            
            if !firstDayEffectiveSetupFinished {
                firstDayEffective = adjustment.firstDayEffective
                firstDayEffectiveSetupFinished = true
            }
            
            if !lastDayEffectiveSetupFinished {
                lastDayEffective = adjustment.lastDayEffective
                lastDayEffectiveSetupFinished = true
            }

            
            self.navigationItem.title = "Edit Adjustment"
        } else {
            
            amountPerDay = 0
            if !goalSetupFinished {
                goal = nil
                goalSetupFinished = true
            }
            
            if !firstDayEffectiveSetupFinished {
                firstDayEffective = CalendarDay()
                firstDayEffectiveSetupFinished = true
            }
            
            if !lastDayEffectiveSetupFinished {
                lastDayEffective = CalendarDay()
                lastDayEffectiveSetupFinished = true
            }

            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, save)
            self.navigationItem.title = "New Adjustment"
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) {
            self.view.endEditing(false)
            self.dismiss(animated: true, completion: nil)
        }

        
        cellCreator = TableViewCellHelper(tableView: tableView)
    }
    
    /**
     * Setup this view controller to default to a particular goal.
     */
    func setupAdjustment(
        goal: Goal?,
        firstDayEffective: CalendarDay?,
        lastDayEffective: CalendarDay?
    ) {
        if let goal = goal {
            self.goal = goal
            self.goalSetupFinished = true
        }
        
        if let firstDayEffective = firstDayEffective {
            self.firstDayEffective = firstDayEffective
            self.firstDayEffectiveSetupFinished = true
        }


        if let lastDayEffective = lastDayEffective {
            self.lastDayEffective = lastDayEffective
            self.lastDayEffectiveSetupFinished = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
        var validation: (valid: Bool, problem: String?)!
        let isNew = (adjustmentId == nil)
        let context = appDelegate.persistentContainer.newBackgroundContext()
        context.performAndWait {
            var adjustment: Adjustment!
            if isNew {
                adjustment = Adjustment(context: context)
                adjustment.dateCreated = Date()
            } else {
                adjustment = Adjustment.inContext(adjustmentId!, context: context)
            }

            let goal = Goal.inContext(self.goal, context: context)
            let multipliedAmountPerDay = self.amountPerDay * (deduct ? -1 : 1)
            validation = adjustment.propose(
                shortDescription: shortDescription,
                amountPerDay: multipliedAmountPerDay,
                firstDayEffective: firstDayEffective,
                lastDayEffective: lastDayEffective,
                goal: goal
            )

            if !validation.valid && isNew {
                context.rollback()
            } else {
                if context.hasChanges {
                    try! context.save()
                }
                self.view.endEditing(false)
                adjustmentId = adjustment.objectID
            }
        }

        if let adjustmentId = adjustmentId {
            let adjustmentOnViewContext: Adjustment = Adjustment.inContext(adjustmentId)!
            if isNew {
                delegate?.createdAdjustmentFromModal(adjustmentOnViewContext)
            } else {
                delegate?.editedAdjustmentFromModal(adjustmentOnViewContext)
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
    
    
    enum AdjustmentViewCellType {
        case DescriptionCell
        case AmountCell
        case TypeCell
        
        case FirstDayEffectiveDisplayCell
        case FirstDayEffectiveDatePickerCell
        case LastDayEffectiveDisplayCell
        case LastDayEffectiveDatePickerCell
        
        case GoalsCell
    }
    
    func cellTypeForIndexPath(indexPath: IndexPath) -> AdjustmentViewCellType {
        let section = indexPath.section
        let row = indexPath.row

        if section == 1 {
            if row == 0 {
                return .AmountCell
            }
            if row == 1 {
                return .TypeCell
            }
        }
        
        if section == 2 {
            if row == 0 {
                return .FirstDayEffectiveDisplayCell
            }
            
            if !editingFirstDate && !editingLastDate {
                return .LastDayEffectiveDisplayCell
            }
            
            if editingFirstDate {
                if row == 1 {
                    return .FirstDayEffectiveDatePickerCell
                }
                if row == 2 {
                    return .LastDayEffectiveDisplayCell
                }
            }
            
            if editingLastDate {
                if row == 1 {
                    return .LastDayEffectiveDisplayCell
                }
                if row == 2 {
                    return .LastDayEffectiveDatePickerCell
                }
            }
        }
        
        if section == 3 {
            return .GoalsCell
        }
        
        return .DescriptionCell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section != 1 {
            return nil
        }
        
        guard let firstDayEffective = firstDayEffective,
              let lastDayEffective = lastDayEffective else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if firstDayEffective == lastDayEffective {
            let formattedDate = firstDayEffective.string(formatter: dateFormatter)
            var formattedAmount = "the above amount"
            if amountPerDay != 0 {
                formattedAmount = String.formatAsCurrency(amount: amountPerDay)!
            }
            let formattedType = deduct ? "decreased" : "increased"
            return "The balance for \(formattedDate) will be \(formattedType) " +
                    "by \(formattedAmount)."
        } else if firstDayEffective < lastDayEffective {
            let formattedFirstDate = firstDayEffective.string(formatter: dateFormatter)
            let formattedLastDate = lastDayEffective.string(formatter: dateFormatter)
            var formattedAmount = "the above amount"
            if amountPerDay != 0 {
                formattedAmount = String.formatAsCurrency(amount: amountPerDay)!
            }
            let formattedType = deduct ? "decreased" : "increased"
            return "The balances from \(formattedFirstDate) to " +
                    "\(formattedLastDate) will be \(formattedType) by " +
                    "\(formattedAmount) each day."
        } else {
            var formattedAmount = "the above amount"
            if amountPerDay != 0 {
                formattedAmount = String.formatAsCurrency(amount: amountPerDay)!
            }
            let formattedType = deduct ? "decreased" : "increased"
            return "The balance will be \(formattedType) by \(formattedAmount)."
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellCreator == nil {
            return UITableViewCell()
        }
        
        func cancelDateEditing() {
            if self.editingFirstDate {
                self.editingFirstDate = false
                tableView.beginUpdates()
                tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
                tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                tableView.endUpdates()
            } else if self.editingLastDate {
                self.editingLastDate = false
                tableView.beginUpdates()
                tableView.reloadRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                tableView.deleteRows(at: [IndexPath(row: 2, section: 2)], with: .fade)
                tableView.endUpdates()
            }
        }
        
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .DescriptionCell:
            return cellCreator.textFieldDisplayCell(
                placeholder: "Description (e.g. \"Found $20 in sock\")",
                text: shortDescription,
                changedToText: { (text: String, _) in
                    self.shortDescription = text
                },
                didBeginEditing: { (_) in cancelDateEditing() }
            )
        case .AmountCell:
            return cellCreator.currencyDisplayCell(title: "Amount",
                amount: self.amountPerDay > 0 ? self.amountPerDay : nil,
                changedToAmount: { newValue in
                    self.amountPerDay = newValue ?? 0
                },
                didBeginEditing: { _ in
                    cancelDateEditing()
                },
                didEndEditing: { (_) in
                    tableView.reloadSections(IndexSet(integer: 1), with: .fade)
                    tableView.reloadSections(IndexSet(integer: 1), with: .fade)
                    self.editingAmountField = nil
                }
            )
        case .TypeCell:
            return cellCreator.segmentedControlCell(
                segmentTitles: ["Add", "Deduct"],
                selectedSegmentIndex: deduct ? 1 : 0,
                title: "Type",
                changedToIndex: { (index: Int) in
                    self.deduct = (index == 1)
                    if self.editingAmountField != nil {
                        self.editingAmountField!.resignFirstResponder()
                    } else {
                        tableView.reloadSections(IndexSet(integer: 1), with: .fade)
                        tableView.reloadSections(IndexSet(integer: 1), with: .fade)
                    }
                    
            })
        case .FirstDayEffectiveDisplayCell:
            return cellCreator.dateDisplayCell(
                label: "Start",
                day: firstDayEffective,
                tintColor: editingFirstDate ? view.tintColor : nil
            )
            
        case .FirstDayEffectiveDatePickerCell:
            return cellCreator.datePickerCell(day: firstDayEffective) { (day: CalendarDay) in
                self.firstDayEffective = day
                
                if self.firstDayEffective! > self.lastDayEffective! {
                    self.lastDayEffective = self.firstDayEffective
                }
                
                tableView.reloadSections(IndexSet(arrayLiteral: 1, 2), with: .fade)
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
            
        case .LastDayEffectiveDisplayCell:
            return cellCreator.dateDisplayCell(
                label: "End",
                day: lastDayEffective,
                tintColor: editingLastDate ? view.tintColor : nil,
                strikeText: firstDayEffective! > lastDayEffective!
            )
            
        case .LastDayEffectiveDatePickerCell:
            return cellCreator.datePickerCell(day: lastDayEffective) { (day: CalendarDay) in
                self.lastDayEffective = day
                
                tableView.reloadSections(IndexSet(arrayLiteral: 1, 2), with: .fade)
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
            
        case .GoalsCell:
            return cellCreator.valueDisplayCell(
                labelText: "Goals",
                valueText: goal?.shortDescription ?? "None",
                detailIndicator: true
            )
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        case 2:
            return editingFirstDate || editingLastDate ? 3 : 2
        case 3:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .FirstDayEffectiveDisplayCell, .LastDayEffectiveDisplayCell:
            return indexPath
        case .GoalsCell:
            return indexPath
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .FirstDayEffectiveDisplayCell:
            editingAmountField?.resignFirstResponder()
            tableView.beginUpdates()
            tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
            if editingFirstDate {
                editingFirstDate = false
                tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
            } else {
                editingFirstDate = true
                tableView.insertRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                if editingLastDate {
                    editingLastDate = false
                    tableView.deleteRows(at: [IndexPath(row: 2, section: 2)], with: .fade)
                    tableView.reloadRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.endUpdates()
            self.view.endEditing(false)
        case .LastDayEffectiveDisplayCell:
            editingAmountField?.resignFirstResponder()
            tableView.beginUpdates()
            tableView.reloadRows(at: [IndexPath(row: editingFirstDate ? 2 : 1, section: 2)], with: .fade)
            if editingLastDate {
                editingLastDate = false
                tableView.deleteRows(at: [IndexPath(row: 2, section: 2)], with: .fade)
            } else {
                editingLastDate = true
                tableView.insertRows(at: [IndexPath(row: 2, section: 2)], with: .fade)
                if editingFirstDate {
                    editingFirstDate = false
                    tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
                }
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
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .FirstDayEffectiveDatePickerCell:
            return editingFirstDate ? 216 : 0
        case .LastDayEffectiveDatePickerCell:
            return editingLastDate ? 216 : 0
        default:
            return 44
        }
    }
    
    func dismissedGoalSelectorWithSelectedGoal(_ goal: Goal?) {
        self.goal = goal
        tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .fade)
    }
}

protocol AddAdjustmentDelegate {
    func createdAdjustmentFromModal(_ adjustment: Adjustment)
    func editedAdjustmentFromModal(_ adjustment: Adjustment)
}
