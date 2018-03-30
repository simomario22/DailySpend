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
    
    let periodLengthExplanatoryText = "The length of the period you have to " +
            "spend the above amount."
    
    let autoAdjustExplanatoryText = "Adjust the amount per month based on the " +
            "number of days in a month (the amount will be for a 30 day month)."
    
    let carryOverExplanatoryText = "Automatically create a carry-over " +
            "adjustment with the balance at the end of each period. If this " +
            "setting is off, you can do this manually in the review section " +
            "for a period."
    
    let incrementalPaymentExplanatoryText = "Pay equally portioned amounts at " +
            "intervals throughout the goal period to help you stay on track " +
            "rather than paying the full amount at the beginning of the period."
    
    let periodPickerRows = [(1...100).map({"\($0)"}), ["Day", "Week", "Month"]]
    
    var cellCreator: TableViewCellHelper!
    
    var delegate: AddGoalDelegate?
    
    var tableView: UITableView!
    var segmentedControl: UISegmentedControl!
    
    var goal: Goal?
    
    // Cell State
    var recurring = true
    var expandedSection: GoalViewExpandableSectionType = .None
    var incrementalPayment = false
    var neverEnd = true
    var cellSizeCache = [GoalViewCellType: CGFloat]()
    
    // Goal Data
    var amount: Decimal?
    var archived: Bool =  false
    var alwaysCarryOver: Bool = false
    var adjustMonthAmountAutomatically: Bool = true
    var period: Period = .Day
    var periodMultiplier: Int = 1
    var payFrequency: Period = .Day
    var payFrequencyMultiplier: Int = 1
    var shortDescription: String?
    var start: CalendarDay? = CalendarDay()
    var end: CalendarDay? = nil
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
        case PeriodLengthPicker
        case PayIntervalPicker
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
                placeholder: "e.g. \"DailySpend\"",
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
        case .PeriodLengthCell:
            return cellCreator.valueDisplayCell(
                labelText: "Period Length",
                valueText: period.string(periodMultiplier),
                explanatoryText: periodLengthExplanatoryText,
                tintDetailText: expandedSection == .PeriodLengthPicker
            )
        case .PeriodLengthPickerCell:
            let multiplierIndex = periodMultiplier - 1
            let periodIndex = periodPickerRows[1].index(of: period.string()) ?? 0
            return cellCreator.pickerCell(
                rows: periodPickerRows,
                initialSelection: [multiplierIndex, periodIndex],
                changedValues: { (values) in
                    if let multiplier = Int(values[0]) {
                        self.periodMultiplier = multiplier
                    } else {
                        self.periodMultiplier = 1
                    }
                    
                    let newPeriod = Period(values[1])
                    
                    self.tableView.beginUpdates()
                    if newPeriod == .Month && self.period != newPeriod {
                        self.insertAdjustMonthAmountAutomaticallyCell()
                    } else if self.period == .Month && self.period != newPeriod {
                        self.removeAdjustMonthAmountAutomaticallyCell()
                    }
                    
                    self.period = newPeriod
                    
                    self.reloadExpandedSectionLabel(.PeriodLengthPicker)
                    self.tableView.endUpdates()
            })
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
        case .IncrementalPaymentCell:
            return cellCreator.switchCell(
                initialValue: incrementalPayment,
                title: "Incremental Payment",
                explanatoryText: incrementalPaymentExplanatoryText,
                valueChanged: { (newValue) in
                    if self.expandedSection == .PayIntervalPicker {
                        self.setExpandedSection(.None)
                    }
                    
                    self.incrementalPayment = newValue

                    if self.incrementalPayment {
                        self.insertPayIntervalCell()
                    } else {
                        self.removePayIntervalCell()
                    }
            })
        case .PayIntervalCell:
            return cellCreator.valueDisplayCell(
                labelText: "Pay Interval",
                valueText: "Every " + payFrequency.string(payFrequencyMultiplier),
                tintDetailText: expandedSection == .PayIntervalPicker,
                strikeText: {
                    if self.payFrequency.rawValue > self.period.rawValue {
                        return true
                    } else if self.payFrequency.rawValue < self.period.rawValue {
                        return false
                    } else {
                        return self.payFrequencyMultiplier > self.periodMultiplier
                    }
                }()
            )
        case .PayIntervalPickerCell:
            let multiplierIndex = payFrequencyMultiplier - 1
            let periodIndex = periodPickerRows[1].index(of: payFrequency.string()) ?? 0
            return cellCreator.pickerCell(
                rows: periodPickerRows,
                initialSelection: [multiplierIndex, periodIndex],
                changedValues: { (values) in
                    if let multiplier = Int(values[0]) {
                        self.payFrequencyMultiplier = multiplier
                    } else {
                        self.payFrequencyMultiplier = 1
                    }
                    
                    let newPeriod = Period(values[1])
                    
                    self.tableView.beginUpdates()
                    self.payFrequency = newPeriod
                    self.reloadExpandedSectionLabel(.PayIntervalPicker)
                    self.tableView.endUpdates()
            })
        case .StartCell:
            return cellCreator.dateDisplayCell(
                label: "Start",
                day: start,
                tintDetailText: expandedSection == .StartDayPicker
            )
        case .StartPickerCell:
            return cellCreator.datePickerCell(
                day: start!,
                changedToDay: { (day) in
                    self.start = day
                    
                    if self.end != nil && self.start! > self.end! {
                        self.end = self.start
                    }
                    self.reloadExpandedSectionLabel(.StartDayPicker)
            })
        case .EndCell:
            return cellCreator.dateDisplayCell(
                label: "End",
                day: self.neverEnd ? nil : end,
                tintDetailText: expandedSection == .EndNeverAndDayPicker,
                strikeText: !self.neverEnd && self.end != nil && self.start! > self.end!,
                alternateText: "Never"
            )
        case .EndNeverPickerCell:
            return cellCreator.switchCell(
                initialValue: neverEnd,
                title: "Never",
                valueChanged: { (newValue) in
                    if self.end == nil {
                        self.end = self.start
                    }
                    self.neverEnd = newValue
                    newValue ? self.removeEndDayPickerCell() : self.insertEndDayPickerCell()
                    self.reloadExpandedSectionLabel(.EndNeverAndDayPicker, scroll: true)
            })
        case .EndPickerCell:
            return cellCreator.datePickerCell(
                day: end!,
                changedToDay: { (day) in
                    self.end = day
                    self.reloadExpandedSectionLabel(.EndNeverAndDayPicker)
            })
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .PeriodLengthCell:
            toggleExpandedSection(.PeriodLengthPicker)
        case .PayIntervalCell:
            toggleExpandedSection(.PayIntervalPicker)
        case .StartCell:
            toggleExpandedSection(.StartDayPicker)
        case .EndCell:
            toggleExpandedSection(.EndNeverAndDayPicker)
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        func height(_ cellType: GoalViewCellType,
                    _ tableViewCellType: ExplanatoryTextTableViewCell.Type,
                    _ text: String) -> CGFloat {
            var height = cellSizeCache[cellType]
            if height == nil {
                height = tableViewCellType.desiredHeight(text)
                cellSizeCache[cellType] = height
            }
            return height!

        }
        
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .PeriodLengthCell:
            return height(.PeriodLengthCell, ValueTableViewCell.self, periodLengthExplanatoryText)
        case .AutoAdjustMonthAmountCell:
            return height(.AutoAdjustMonthAmountCell, SwitchTableViewCell.self, autoAdjustExplanatoryText)
        case .AlwaysCarryOverCell:
            return height(.AlwaysCarryOverCell, SwitchTableViewCell.self, carryOverExplanatoryText)
        case .IncrementalPaymentCell:
            return height(.IncrementalPaymentCell, SwitchTableViewCell.self, incrementalPaymentExplanatoryText)
        case .PeriodLengthPickerCell,
             .PayIntervalPickerCell:
            return 175
        case .StartPickerCell,
             .EndPickerCell:
            return 216
        default:
            return 44
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return recurring ? 4 : 2
    }
    
    func reloadExpandedSectionLabel(_ section: GoalViewExpandableSectionType, scroll: Bool = false) {
        let startEndSection = recurring ? 3 : 1
        
        var path = IndexPath()
        switch expandedSection {
        case .PeriodLengthPicker:
            path = IndexPath(row: 0, section: 1)
        case .PayIntervalPicker:
            path = IndexPath(row: 1, section: 2)
        case .StartDayPicker:
            path = IndexPath(row: 0, section: startEndSection)
        case .EndNeverAndDayPicker:
            path = IndexPath(row: 1, section: startEndSection)
        case .None: return
        }
        tableView.reloadRows(at: [path], with: .fade)
        if scroll {
            if section == .EndNeverAndDayPicker {
                // Scroll low cell to top for end date picker.
                path = IndexPath(row: neverEnd ? 2 : 3, section: startEndSection)
            }
            tableView.scrollToRow(at: path, at: .top, animated: true)
        }
    }
    
    func toggleExpandedSection(_ section: GoalViewExpandableSectionType) {
        setExpandedSection(section != expandedSection ? section : .None)
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
        
        func reloadSection(_ section: GoalViewExpandableSectionType,
                             delete: Bool,
                             adjacentRows: Bool) -> IndexPath? {
            let startEndSection = recurring ? 3 : 1

            switch section {
            case .PeriodLengthPicker:
                reload(row: 0, section: 1, delete: delete)
                return IndexPath(row: 0, section: 1)
            case .PayIntervalPicker:
                reload(row: 1, section: 2, delete: delete)
                return IndexPath(row: 1, section: 2)
            case .StartDayPicker:
                reload(row: 0, section: startEndSection, delete: delete, next: adjacentRows ? 0 : 1)
                return IndexPath(row: 0, section: startEndSection)
            case .EndNeverAndDayPicker:
                if adjacentRows {
                    // Since the rows to be reloaded are adjacent and we are
                    // grouping transactions, we need to do some custom work
                    // here to ensure we reload and insert the correct rows.
                    let rows = [
                        IndexPath(row: 1, section: startEndSection),
                        IndexPath(row: 2, section: startEndSection)
                    ]
                    
                    tableView.reloadRows(at: rows, with: .fade)
                    
                    if !neverEnd {
                        tableView.insertRows(at: [IndexPath(row: 3, section: startEndSection)], with: .fade)
                    }
                } else {
                    reload(row: 1, section: startEndSection, delete: delete, next: neverEnd ? 1 : 2)
                }
                // Return bottom row for row to scroll to here, since this is
                // the bottom section.
                return IndexPath(row: neverEnd ? 2 : 3, section: startEndSection)
            case .None:
                return nil
            }
        }
        
        tableView.beginUpdates()
        // Close existing section.
        let adjacentRows = expandedSection == .StartDayPicker && newSection == .EndNeverAndDayPicker
        _ = reloadSection(expandedSection, delete: true, adjacentRows: adjacentRows)
        
        expandedSection = newSection

        // Open new section.
        let path = reloadSection(expandedSection, delete: false, adjacentRows: adjacentRows)
        tableView.endUpdates()
        
        if path != nil {
            tableView.scrollToRow(at: path!, at: .top, animated: true)
        }
    }
    
    func insertEndDayPickerCell() {
        let section = recurring ? 3 : 1
        let path = IndexPath(row: 3, section: section)
        tableView.insertRows(at: [path], with: .fade)
        tableView.scrollToRow(at: path, at: .top, animated: true)
    }
    
    func removeEndDayPickerCell() {
        let section = recurring ? 3 : 1
        tableView.deleteRows(at: [IndexPath(row: 3, section: section)], with: .fade)
    }
    
    func insertPayIntervalCell() {
        guard recurring else {
            return
        }
        let path = IndexPath(row: 1, section: 2)
        tableView.insertRows(at: [path], with: .fade)
        tableView.scrollToRow(at: path, at: .top, animated: true)
    }
    
    func removePayIntervalCell() {
        guard recurring else {
            return
        }
        tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
    }
    
    func insertAdjustMonthAmountAutomaticallyCell() {
        guard recurring else {
            return
        }
        let row = expandedSection == .PeriodLengthPicker ? 2 : 3
        let path = IndexPath(row: row, section: 1)
        tableView.insertRows(at: [path], with: .fade)
    }
    
    func removeAdjustMonthAmountAutomaticallyCell() {
        guard recurring else {
            return
        }
        let row = expandedSection == .PeriodLengthPicker ? 2 : 3
        tableView.deleteRows(at: [IndexPath(row: row, section: 1)], with: .fade)
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
                if expandedSection == .PeriodLengthPicker {
                    return .PeriodLengthPickerCell
                } else if period == .Month {
                    return .AutoAdjustMonthAmountCell
                } else {
                    return .AlwaysCarryOverCell
                }
            case 2:
                if expandedSection == .PeriodLengthPicker && period == .Month {
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
            sections += expandedSection == .PeriodLengthPicker ? 1 : 0
            return sections
        }
        
        func rowsInPayIncrementalPaymentSection() -> Int {
            var sections = 1
            sections += incrementalPayment ? 1 : 0
            sections += expandedSection == .PayIntervalPicker ? 1 : 0
            return sections
        }
        
        func rowsInStartEndSection() -> Int {
            if expandedSection == .StartDayPicker {
                return 3
            } else if expandedSection == .EndNeverAndDayPicker {
                return neverEnd ? 3 : 4
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
