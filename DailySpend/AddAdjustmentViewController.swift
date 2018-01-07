//
//  AddAdjustmentViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class AddAdjustmentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    var cellCreator: TableViewCellHelper!
    
    var delegate: AddAdjustmentDelegate?
    var tableView: UITableView!
    
    var editingAmountField: UITextField? = nil
    var editingFirstDate = false
    var editingLastDate = false
    
    var adjustment: Adjustment?

    /*
     * This is the total amount the user entered,
     * not divided by the number of days.
     */
    var rawAmount: Decimal! = 0
    var shortDescription: String! = ""
    var firstDayEffective: CalendarDay!
    var lastDayEffective: CalendarDay!
    var daysInRange: Decimal! = 1
    var deduct = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up table view.
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        if let adjustment = self.adjustment {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, save)
            
            shortDescription = adjustment.shortDescription
            firstDayEffective = adjustment.firstDayEffective
            lastDayEffective = adjustment.lastDayEffective
            
            let first = self.firstDayEffective!
            let last = self.lastDayEffective!.add(days: 1)
            self.daysInRange = Decimal(CalendarDay.daysInRange(start: first, end: last))
            if adjustment.amountPerDay! < 0 {
                deduct = true
            }
            rawAmount = abs(adjustment.amountPerDay! * daysInRange)
            
            self.navigationItem.title = "Edit"
        } else {
            firstDayEffective = CalendarDay()
            lastDayEffective = CalendarDay()
            rawAmount = 0
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, save)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) {
                self.view.endEditing(false)
                self.dismiss(animated: true, completion: nil)
            }
            self.navigationItem.title = "New Adjustment"
        }
        
        cellCreator = TableViewCellHelper(tableView: tableView, view: view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
        let amountPerDay = (rawAmount * (deduct ? -1 : 1)) / daysInRange
        
        var justCreated = false
        if adjustment == nil {
            justCreated = true
            adjustment = Adjustment(context: context)
            adjustment!.dateCreated = Date()
        }
        
        let validation = adjustment!.propose(shortDescription: shortDescription,
                                             amountPerDay: amountPerDay,
                                             firstDayEffective: firstDayEffective,
                                             lastDayEffective: lastDayEffective)
        if validation.valid {
            appDelegate.saveContext()
            self.view.endEditing(false)
            delegate?.addedOrChangedAdjustment(adjustment!)
            if self.navigationController!.viewControllers[0] == self {
                self.navigationController!.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController!.popViewController(animated: true)
            }
        } else {
            if justCreated {
                context.delete(adjustment!)
                adjustment = nil
                appDelegate.saveContext()
            }
            let alert = UIAlertController(title: "Couldn't Save",
                                          message: validation.problem!,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay",
                                          style: .default,
                                          handler: nil))
            self.present(alert, animated: true, completion: nil)
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
        
        let amountPerDay = rawAmount / daysInRange
        
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
            return "The balances for \(formattedFirstDate) to " +
                    "\(formattedLastDate) will be \(formattedType) by " +
                    "\(formattedAmount) each day."
        } else {
            var formattedAmount = "the above amount"
            if rawAmount != 0 {
                formattedAmount = String.formatAsCurrency(amount: rawAmount)!
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
            var formattedAmount: String? = nil
            if self.rawAmount > 0 {
                formattedAmount = String.formatAsCurrency(amount: self.rawAmount)
            }
            return cellCreator.textFieldDisplayCell(
                title: "Amount",
                placeholder: "$0.00",
                text: formattedAmount,
                keyboardType: .numberPad,
                changedToText: { (text: String, field: UITextField) in
                    self.rawAmount = Decimal(text.parseValidAmount(maxLength: 8))
                    field.text = String.formatAsCurrency(amount: self.rawAmount)
                },
                didBeginEditing: { (field: UITextField) in
                    self.editingAmountField = field
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
            return cellCreator.dateDisplayCell(label: "Start",
                                   day: firstDayEffective,
                                   tintDetailText: editingFirstDate)
            
        case .FirstDayEffectiveDatePickerCell:
            return cellCreator.datePickerCell(day: firstDayEffective) { (day: CalendarDay) in
                self.firstDayEffective = day
                
                if self.firstDayEffective! > self.lastDayEffective! {
                    self.lastDayEffective = self.firstDayEffective
                }
                
                let first = self.firstDayEffective!
                let last = self.lastDayEffective!.add(days: 1)
                self.daysInRange = Decimal(CalendarDay.daysInRange(start: first, end: last))

                tableView.reloadSections(IndexSet(arrayLiteral: 1, 2), with: .fade)
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
            
        case .LastDayEffectiveDisplayCell:
            return cellCreator.dateDisplayCell(label: "End",
                       day: lastDayEffective,
                       tintDetailText: editingLastDate,
                       strikeText: firstDayEffective! > lastDayEffective!)
            
        case .LastDayEffectiveDatePickerCell:
            return cellCreator.datePickerCell(day: lastDayEffective) { (day: CalendarDay) in
                self.lastDayEffective = day

                if self.firstDayEffective! <= day {
                    let first = self.firstDayEffective!
                    let last = self.lastDayEffective!.add(days: 1)
                    self.daysInRange = Decimal(CalendarDay.daysInRange(start: first, end: last))
                }

                tableView.reloadSections(IndexSet(arrayLiteral: 1, 2), with: .fade)
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        case 2:
            return editingFirstDate || editingLastDate ? 3 : 2
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .FirstDayEffectiveDisplayCell, .LastDayEffectiveDisplayCell:
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
}

protocol AddAdjustmentDelegate {
    func addedOrChangedAdjustment(_ adjustment: Adjustment)
}
