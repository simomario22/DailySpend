//
//  PauseViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class AddGoalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    let autoAdjustExplanatoryText = "Adjust the amount per month based on the " +
            "number of days in a month. (The amount will be for a 30 day month"
    
    let carryOverExplanatoryText = "Automatically create a carry-over " +
            "adjustment with the balance at the end of each period. If this " +
            "setting is off, you can do this manually in the review section " +
            "for a period."
    
    var cellCreator: TableViewCellHelper!
    
    var delegate: AddGoalDelegate?
    
    var tableView: UITableView!
    var segmentedControl: UISegmentedControl!
    
    var goal: Goal?
    
    // Cell State
    var recurring = true
    var expandedSection: GoalViewExpandableSectionType = .None
    
    // Goal Data
    var amount: Decimal?
    var archived: Bool =  false
    var alwaysCarryOver: Bool = false
    var adjustMonthAmountAutomatically: Bool = false
    var end: Date?
    var period: Period = .None
    var payFrequency: Period = .None
    var payFrequencyMultiplier: Int = 1
    var shortDescription: String?
    var start: Date?
    var periodMultiplier: Int = 1
    var parentGoal: Goal?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.hideBorderLine()
        
        let toolbarFrame = CGRect(x: 0, y: 64, width: view.frame.size.width, height: 44)
        
        segmentedControl = UISegmentedControl(items: ["Recurring", "One Time"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.add(for: .valueChanged) {
            self.recurring = self.segmentedControl.selectedSegmentIndex == 0
            self.tableView.reloadData()
        }
        
        let toolbar = BorderedToolbar(frame: toolbarFrame)
        toolbar.addBottomBorder(color: UIColor.lightGray, width: 0.5)
        let barButtonControl = UIBarButtonItem(customView: segmentedControl)
        toolbar.setItems([barButtonControl], animated: false)
        view.addSubview(toolbar)

        // Set up table view.
        let tableViewFrame = CGRect(x: 0,
                                    y: toolbarFrame.bottomEdge,
                                    width: view.frame.size.width,
                                    height: view.frame.size.height - toolbarFrame.bottomEdge)
        tableView = UITableView(frame: tableViewFrame, style: .grouped)
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        view.backgroundColor = tableView.backgroundColor
        
        cellCreator = TableViewCellHelper(tableView: tableView, view: view)
        
        if self.goal != nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, save)
            self.navigationItem.title = "Edit Goal"
            
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, save)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) {
                self.view.endEditing(false)
                self.dismiss(animated: true, completion: nil)
            }
            self.navigationItem.title = "New Goal"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
    }
    
    
    enum GoalViewCellType {
        case DescriptionCell
        case AmountPerPeriodCell
        case PeriodLengthCell
        case PeriodLengthPickerCell
        case AutoAdjustMonthAmountCell
        case AlwaysCarryOverCell
        case IncrementalPaymentCell
        case PayIntervalCell
        case PayIntervalPickerCell
        case StartCell
        case StartPickerCell
        case EndCell
        case EndNeverPickerCell
        case EndPickerCell
    }
    
    enum GoalViewExpandableSectionType {
        case None
        case PeriodLengthDatePicker
        case PayIntervalDatePicker
        case StartDayPicker
        case EndNeverAndDayPicker
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section != 1 {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
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
                placeholder: "Description (e.g. \"Travel\")",
                text: shortDescription,
                changedToText: { (text: String, _) in
                    self.shortDescription = text
                },
                didBeginEditing: { _ in
                    self.setExpandedSection(.None)
                }
            )
        case .AmountPerPeriodCell:
            return cellCreator.currencyDisplayCell(
                title: "Amount",
                amount: amount,
                changedToAmount: { (newAmount) in
                    self.amount = newAmount
                }
            )
        case .PeriodLengthCell: break
        case .PeriodLengthPickerCell: break
        case .AutoAdjustMonthAmountCell:
            return cellCreator.switchCell(
                initialValue: self.adjustMonthAmountAutomatically,
                title: "Auto-Adjust Month Amount",
                explanatoryText: autoAdjustExplanatoryText,
                valueChanged: { (newValue) in
                    self.adjustMonthAmountAutomatically = newValue
            })
        case .AlwaysCarryOverCell:
            return cellCreator.switchCell(
                initialValue: self.alwaysCarryOver,
                title: "Always Carry Over",
                explanatoryText: carryOverExplanatoryText,
                valueChanged: { (newValue) in
                    self.alwaysCarryOver = newValue
            })
        case .IncrementalPaymentCell: break
        case .PayIntervalCell: break
        case .PayIntervalPickerCell: break
        case .StartCell: break
        case .StartPickerCell: break
        case .EndCell: break
        case .EndNeverPickerCell: break
        case .EndPickerCell: break
        }
        return UITableViewCell()
            
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .AutoAdjustMonthAmountCell:
            return SwitchTableViewCell.desiredHeight(autoAdjustExplanatoryText)
        case .AlwaysCarryOverCell:
            return SwitchTableViewCell.desiredHeight(carryOverExplanatoryText)
        default:
            return 44
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func setExpandedSection(_ newSection: GoalViewExpandableSectionType) {
        if newSection == expandedSection { return } // No need to change anything.

        func reload(row: Int, section: Int, delete: Bool, next: Int = 1) {
            tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .fade)
            var paths = [IndexPath]()
            for index in 0..<next {
                paths.append(IndexPath(row: row + index + 1, section: section))
            }
            let insertOrDelete = delete ? tableView.deleteRows : tableView.insertRows
            insertOrDelete(paths, .fade)
        }
        
        func reloadSection(_ section: GoalViewExpandableSectionType, delete: Bool) {
            let startEndSection = recurring ? 1 : 3

            switch expandedSection {
            case .PeriodLengthDatePicker:
                reload(row: 0, section: 1, delete: delete)
            case .PayIntervalDatePicker:
                reload(row: 1, section: 2, delete: delete)
            case .StartDayPicker:
                reload(row: 0, section: startEndSection, delete: delete)
            case .EndNeverAndDayPicker:
                reload(row: 0, section: startEndSection, delete: delete, next: 2)
            case .None: break
            }
        }
        
        tableView.beginUpdates()
        // Close existing section.
        reloadSection(expandedSection, delete: true)
        
        expandedSection = newSection
        
        // Open new section.
        reloadSection(expandedSection, delete: false)
        tableView.endUpdates()
    }
    
    func cellTypeForIndexPath(indexPath: IndexPath) -> GoalViewCellType {
        let section = indexPath.section
        let row = indexPath.row
        
        let defaultCellType: GoalViewCellType = .DescriptionCell
        
        func cellTypeForDescriptionAmountSection(row: Int) -> GoalViewCellType? {
            switch row {
            case 0:
                return .DescriptionCell
            case 1:
                return .AmountPerPeriodCell
            default:
                return nil
            }
        }
        
        func cellTypeForPeriodSection(row: Int) -> GoalViewCellType? {
            switch row {
            case 0:
                return .PeriodLengthCell
            case 1:
                if expandedSection == .PeriodLengthDatePicker {
                    return .PeriodLengthPickerCell
                } else if period == .Month {
                    return .AutoAdjustMonthAmountCell
                } else {
                    return .AlwaysCarryOverCell
                }
            case 2:
                if expandedSection == .PeriodLengthDatePicker && period == .Month {
                    return .AutoAdjustMonthAmountCell
                } else {
                    return .AlwaysCarryOverCell
                }
            case 3:
                return .AlwaysCarryOverCell
            default:
                return nil
            }
        }
        
        func cellTypeForPayIncrementalPaymentSection(row: Int) -> GoalViewCellType? {
            switch row {
            case 0:
                return .IncrementalPaymentCell
            case 1:
                return .PayIntervalCell
            case 2:
                return .PayIntervalPickerCell
            default:
                return nil
            }
        }
        
        func cellTypeForStartEndSection(row: Int) -> GoalViewCellType? {
            switch row {
            case 0:
                return .StartCell
            case 1:
                return expandedSection == .StartDayPicker ? .StartPickerCell : .EndCell
            case 2:
                return expandedSection == .StartDayPicker ? .EndCell : .EndNeverPickerCell
            case 3:
                return .EndPickerCell
            default:
                return nil
            }
        }
        
        if recurring {
            switch section {
            case 0:
                return cellTypeForDescriptionAmountSection(row: row) ?? defaultCellType
            case 1:
                return cellTypeForPeriodSection(row: row) ?? defaultCellType
            case 2:
                return cellTypeForPayIncrementalPaymentSection(row: row) ?? defaultCellType
            case 3:
                return cellTypeForStartEndSection(row: row) ?? defaultCellType
            default: break
            }
        } else {
            switch section {
            case 0:
                return cellTypeForDescriptionAmountSection(row: row) ?? defaultCellType
            case 1:
                return cellTypeForStartEndSection(row: row) ?? defaultCellType
            default: break
            }
        }
        return .DescriptionCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        func rowsInDescriptionAmountSection() -> Int {
            return 2
        }
        
        func rowsInPeriodSection() -> Int {
            var sections = 2
            sections += period == .Month ? 1 : 0
            sections += expandedSection == .PeriodLengthDatePicker ? 1 : 0
            return sections
        }
        
        func rowsInPayIncrementalPaymentSection() -> Int {
            var sections = 1
            sections += payFrequency != .None ? 1 : 0
            sections += expandedSection == .PayIntervalDatePicker ? 1 : 0
            return sections
        }
        
        func rowsInStartEndSection() -> Int {
            if expandedSection == .StartDayPicker {
                return 3
            } else if expandedSection == .EndNeverAndDayPicker {
                return 4
            } else {
                return 2
            }
        }
        
        if recurring {
            switch section {
            case 0:
                return rowsInDescriptionAmountSection()
            case 1:
                return rowsInPeriodSection()
            case 2:
                return rowsInPayIncrementalPaymentSection()
            case 3:
                return rowsInStartEndSection()
            default:
                return 0
            }
        } else {
            switch section {
            case 0:
                return rowsInDescriptionAmountSection()
            case 1:
                return rowsInStartEndSection()
            default:
                return 0
            }
        }
    }
}

protocol AddGoalDelegate {
    func addedOrChangedGoal(_ goal: Goal)
}
