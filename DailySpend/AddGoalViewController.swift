//
//  PauseViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class AddGoalViewController: UIViewController, GoalSelectorDelegate, UITableViewDelegate, UITableViewDataSource {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)

    let periodLengthExplanatoryText = "The length of the period you have to " +
            "spend the above amount."
    
    let autoAdjustExplanatoryText = "Adjust the amount per month based on the " +
            "number of days in a month (the amount above will be used for a 30 " +
            "day month)."
    
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
    var toolbar: BorderedToolbar!
    
    var goalId: NSManagedObjectID?
    
    // Cell State
    var recurring = true
    var expandedSection: GoalViewExpandableSectionType = .None
    var incrementalPayment = false
    var neverEnd = true
    var cellSizeCache = [AddGoalViewCellType: CGFloat]()
    
    /*
     * The start day, only updated when the start field is explicitly set, but
     * not on changes to the period scope that affect the start day.
     */
    var unmodifiedStartDay: CalendarDateProvider!
    /*
     * The end day, only updated when the end field is explicitly set, but
     * not on changes to the period scope that affect the end day.
     */
    var unmodifiedEndDay: CalendarDateProvider?
    
    // Goal Data
    var amount: Decimal?
    var shortDescription: String?
    var alwaysCarryOver: Bool!
    var adjustMonthAmountAutomatically: Bool!
    var period: Period!
    var payFrequency: Period!
    var start: CalendarDateProvider!
    var end: CalendarDateProvider?
    var parentGoal: Goal?

    override func viewDidLoad() {
        self.view.tintColor = .tint
        super.viewDidLoad()
        
        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        let toolbarFrame = CGRect(x: 0, y: navHeight + statusBarHeight, width: view.frame.size.width, height: 44)
        
        segmentedControl = UISegmentedControl(items: ["Recurring", "One Time"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.add(for: .valueChanged) {
            self.recurring = self.segmentedControl.selectedSegmentIndex == 0
            
            if self.expandedSection == .PeriodLengthPicker ||
                self.expandedSection == .PayIntervalPicker {
                // Disable section on switch if not in recurring and
                // non-recurring views.
                self.expandedSection = .None
            }
            if self.recurring {
                // We are effectively switching from a .Day period, although
                // not set explicitly.
                self.updateStartAndEndToPeriod(from: .Day, reload: false)
            }
            self.tableView.reloadData()
        }
        
        toolbar = BorderedToolbar(frame: toolbarFrame)
        toolbar.addOutsideBottomBorder(color: UIColor.black.withAlphaComponent(0.3), width: 0.5)

        let barButtonControl = UIBarButtonItem(customView: segmentedControl)
        toolbar.setItems([barButtonControl], animated: false)
        view.addSubview(toolbar)

        let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        // Set up table view.
        let tableViewFrame = CGRect(
            x: 0,
            y: toolbarFrame.bottomEdge,
            width: view.frame.size.width,
            height: view.frame.size.height - toolbarFrame.bottomEdge
        )
        
        tableView = UITableView(frame: tableViewFrame, style: .grouped)
        tableView.scrollIndicatorInsets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: bottomInset,
            right: 0
        )
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        view.backgroundColor = tableView.backgroundColor
        
        cellCreator = TableViewCellHelper(tableView: tableView)

        let goal = (Goal.inContext(goalId) as? Goal)
        if let goal = goal {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, save)
            self.navigationItem.title = "Edit Goal"

            amount = goal.amount
            shortDescription = goal.shortDescription
            alwaysCarryOver = goal.alwaysCarryOver
            adjustMonthAmountAutomatically = goal.adjustMonthAmountAutomatically
            period = goal.period
            payFrequency = goal.payFrequency
            start = goal.start
            end = goal.end
            unmodifiedStartDay = start
            unmodifiedEndDay = end
            parentGoal = goal.parentGoal
            
            // Set up cell state
            recurring = goal.isRecurring
            if !recurring {
                period = Period(scope: .Day, multiplier: 1)
                payFrequency = Period(scope: .Day, multiplier: 1)
                alwaysCarryOver = false
                adjustMonthAmountAutomatically = true
                segmentedControl.selectedSegmentIndex = 1
            }
            
            incrementalPayment = goal.hasIncrementalPayment
            if !incrementalPayment {
                payFrequency = Period(scope: .Day, multiplier: 1)
            }
            
            neverEnd = end == nil
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, save)
            self.navigationItem.title = "New Goal"
            
            alwaysCarryOver = false
            adjustMonthAmountAutomatically = true
            period = Period(scope: .Day, multiplier: 1)
            payFrequency = Period(scope: .Day, multiplier: 1)
            start = CalendarDay().start
            unmodifiedStartDay = start
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) {
            self.view.endEditing(false)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
        let context = appDelegate.persistentContainer.newBackgroundContext()
        var goal: Goal
        var justCreated = false
        if goalId == nil {
            justCreated = true
            goal = Goal(context: context)
            goal.dateCreated = Date()
        } else {
            goal = (context.object(with: goalId!) as! Goal)
        }
        
        let validation = goal.propose(
            shortDescription: shortDescription,
            amount: amount,
            start: start,
            end: neverEnd ? nil : end,
            period: recurring ? period : Period.none,
            payFrequency: recurring && incrementalPayment ? payFrequency : Period.none,
            parentGoal: Goal.inContext(parentGoal, context: context),
            alwaysCarryOver: recurring ? alwaysCarryOver : nil,
            adjustMonthAmountAutomatically: recurring && period.scope == .Month ? adjustMonthAmountAutomatically : nil
        )

        if validation.valid {
            if context.hasChanges {
                try! context.save()
            }
            self.view.endEditing(false)
            let goalOnViewContext = Goal.inContext(goal)!
            delegate?.addedOrChangedGoal(goalOnViewContext)
            if self.navigationController!.viewControllers[0] == self {
                self.navigationController!.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController!.popViewController(animated: true)
            }
        } else {
            if justCreated {
                context.rollback()
                try! context.save()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.hideBorderLine()
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.showBorderLine()
        super.viewWillDisappear(animated)
    }
    
    enum AddGoalViewCellType {
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
        case ParentGoalCell
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
                valueText: period.string(),
                explanatoryText: periodLengthExplanatoryText,
                tintColor: expandedSection == .PeriodLengthPicker ? view.tintColor : nil
            )
        case .PeriodLengthPickerCell:
            let multiplierIndex = period.multiplier - 1
            let periodIndex = periodPickerRows[1].index(of: period.scope.string()) ?? 0
            return cellCreator.pickerCell(
                rows: periodPickerRows,
                initialSelection: [multiplierIndex, periodIndex],
                changedValues: { (values) in
                    if let multiplier = Int(values[0]) {
                        self.period.multiplier = multiplier
                    } else {
                        self.period.multiplier = 1
                    }
                    
                    let oldPeriod = self.period.scope
                    let newPeriod = PeriodScope(values[1])
                    
                    self.tableView.beginUpdates()
                    if newPeriod == .Month && self.period.scope != newPeriod {
                        self.insertAdjustMonthAmountAutomaticallyCell()
                    } else if self.period.scope == .Month && self.period.scope != newPeriod {
                        self.removeAdjustMonthAmountAutomaticallyCell()
                    }
                    
                    self.period.scope = newPeriod
                    
                    self.updateStartAndEndToPeriod(from: oldPeriod, reload: true)
                    self.reloadExpandedSectionLabel(.PeriodLengthPicker)
                    if self.incrementalPayment {
                        self.reloadExpandedSectionLabel(.PayIntervalPicker)
                    }
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
                valueText: "Every " + payFrequency.string(),
                tintColor: expandedSection == .PayIntervalPicker ? view.tintColor : nil,
                strikeText: self.payFrequency > self.period
            )
        case .PayIntervalPickerCell:
            let multiplierIndex = payFrequency.multiplier - 1
            let periodIndex = periodPickerRows[1].index(of: payFrequency.scope.string()) ?? 0
            return cellCreator.pickerCell(
                rows: periodPickerRows,
                initialSelection: [multiplierIndex, periodIndex],
                changedValues: { (values) in
                    if let multiplier = Int(values[0]) {
                        self.payFrequency.multiplier = multiplier
                    } else {
                        self.payFrequency.multiplier = 1
                    }
                    
                    let newPeriod = PeriodScope(values[1])
                    
                    self.tableView.beginUpdates()
                    self.payFrequency.scope = newPeriod
                    self.reloadExpandedSectionLabel(.PayIntervalPicker)
                    self.tableView.endUpdates()
            })
        case .StartCell:
            return cellCreator.dateDisplayCell(
                label: "Start",
                day: CalendarDay(dateInDay: start),
                tintColor: expandedSection == .StartDayPicker ? view.tintColor : nil
            )
        case .StartPickerCell:
            return cellCreator.periodPickerCell(
                date: start,
                scope: recurring ? period.scope : .Day,
                changedToDate: { (date: CalendarDateProvider, scope: PeriodScope) in
                    self.start = date

                    if self.end != nil && self.start!.gmtDate > self.end!.gmtDate {
                        // End day earlier than start day - set it to start.
                        self.end = self.start
                        self.reloadExpandedSectionLabel(.EndNeverAndDayPicker)
                    }
                    
                    // Update the unmodified days since we are making a direct
                    // change.
                    self.unmodifiedStartDay = self.start
                    self.unmodifiedEndDay = self.end

                    self.reloadExpandedSectionLabel(.StartDayPicker)
            })
        case .EndCell:
            return cellCreator.dateDisplayCell(
                label: "End",
                day: self.neverEnd ? nil : CalendarDay(dateInDay: end!),
                tintColor: expandedSection == .EndNeverAndDayPicker ? view.tintColor : nil,
                strikeText: !self.neverEnd && self.end != nil && self.start!.gmtDate > self.end!.gmtDate,
                alternateText: "Never"
            )
        case .EndNeverPickerCell:
            return cellCreator.switchCell(
                initialValue: neverEnd,
                title: "Never",
                valueChanged: { (newValue) in
                    if !newValue && self.end == nil {
                        self.end = self.start
                        self.unmodifiedEndDay = self.unmodifiedStartDay
                    }
                    self.neverEnd = newValue
                    newValue ? self.removeEndDayPickerCell() : self.insertEndDayPickerCell()
                    self.reloadExpandedSectionLabel(.EndNeverAndDayPicker, scroll: true)
            })
        case .EndPickerCell:
            return cellCreator.periodPickerCell(
                date: end!,
                scope: .Day,
                changedToDate: { (date: CalendarDateProvider, scope: PeriodScope) in
                    self.end = date
                    
                    // Update the unmodified days since we are making a direct
                    // change.
                    self.unmodifiedStartDay = self.start
                    self.unmodifiedEndDay = self.end
                    
                    self.reloadExpandedSectionLabel(.EndNeverAndDayPicker)
            })
        case .ParentGoalCell:
            return cellCreator.valueDisplayCell(
                labelText: "Parent Goal",
                valueText: parentGoal?.shortDescription ?? "None",
                detailIndicator: true
            )
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .PeriodLengthCell:
            self.view.endEditing(false)
            toggleExpandedSection(.PeriodLengthPicker)
        case .PayIntervalCell:
            self.view.endEditing(false)
            toggleExpandedSection(.PayIntervalPicker)
        case .StartCell:
            self.view.endEditing(false)
            toggleExpandedSection(.StartDayPicker)
        case .EndCell:
            self.view.endEditing(false)
            toggleExpandedSection(.EndNeverAndDayPicker)
        case .ParentGoalCell:
            setExpandedSection(.None)
            let goalSelectorVC = GoalSelectorViewController()
            if let parentGoal = parentGoal {
                goalSelectorVC.setSelectedGoal(goal: parentGoal)
            }
            if let goalId = goalId {
                let goal = (Goal.inContext(goalId) as! Goal)
                goalSelectorVC.excludedGoals = Set<Goal>([goal])
            }
            goalSelectorVC.showParentSelection = false
            goalSelectorVC.delegate = self
            navigationController?.pushViewController(goalSelectorVC, animated: true)
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        func height(_ cellType: AddGoalViewCellType,
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
        return recurring ? 5 : 3
    }
    
    func reloadExpandedSectionLabel(_ section: GoalViewExpandableSectionType, scroll: Bool = false) {
        let startEndSection = recurring ? 3 : 1
        
        var path = IndexPath()
        switch section {
        case .PeriodLengthPicker:
            path = IndexPath(row: 0, section: 1)
        case .PayIntervalPicker:
            path = IndexPath(row: 1, section: 2)
        case .StartDayPicker:
            path = IndexPath(row: 0, section: startEndSection)
        case .EndNeverAndDayPicker:
            let endRow = expandedSection == .StartDayPicker ? 2 : 1
            path = IndexPath(row: endRow, section: startEndSection)
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
    
    /**
     * Update start and end to be valid for the current period.
     *
     * - Parameters:
     *     - oldPeriod: The previous period scope that was used for date
     *                  selection.
     *     - reload: `true` if this function should reload the appropriate rows
     *               in the table view.
     */
    func updateStartAndEndToPeriod(from oldPeriod: PeriodScope, reload: Bool) {
        let start: CalendarDateProvider! = period.scope < oldPeriod ? unmodifiedStartDay : self.start
        let end: CalendarDateProvider? = period.scope < oldPeriod ? unmodifiedEndDay : self.end
        switch period.scope {
        case .Day:
            self.start = CalendarDay(dateInDay: start).start
            self.end = end == nil ? nil : CalendarDay(dateInDay: end!).start
        case .Week:
            self.start = CalendarWeek(dateInWeek: start).start
            self.end = end == nil ? nil : CalendarWeek(dateInWeek: end!).start
        case .Month:
            self.start = CalendarMonth(dateInMonth: start).start
            self.end = end == nil ? nil : CalendarMonth(dateInMonth: end!).start
        case .None: break
        }
        if !reload {
            return
        }
        let section = recurring ? 3 : 1
        let startRow = 0
        let endRow = expandedSection == .StartDayPicker ? 2 : 1
        let paths = [
            IndexPath(row: startRow, section: section),
            IndexPath(row: endRow, section: section),
        ]
        tableView.reloadRows(at: paths, with: .fade)
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
    
    func reloadParentGoalCell() {
        let section = recurring ? 4 : 2
        tableView.reloadRows(at: [IndexPath(row: 0, section: section)], with: .fade)
    }
    
    func dismissedGoalSelectorWithSelectedGoal(_ goal: Goal?) {
        parentGoal = goal
        reloadParentGoalCell()
    }
    
    func cellTypeForIndexPath(indexPath: IndexPath) -> AddGoalViewCellType {
        let section = indexPath.section
        let row = indexPath.row
        
        let defaultCellType: AddGoalViewCellType = .DescriptionCell
        
        func cellTypeForDescriptionAmountSection(row: Int) -> AddGoalViewCellType? {
            switch row {
            case 0:
                return .DescriptionCell
            case 1:
                return .AmountPerPeriodCell
            default:
                return nil
            }
        }
        
        func cellTypeForPeriodSection(row: Int) -> AddGoalViewCellType? {
            switch row {
            case 0:
                return .PeriodLengthCell
            case 1:
                if expandedSection == .PeriodLengthPicker {
                    return .PeriodLengthPickerCell
                } else if period.scope == .Month {
                    return .AutoAdjustMonthAmountCell
                } else {
                    return .AlwaysCarryOverCell
                }
            case 2:
                if expandedSection == .PeriodLengthPicker && period.scope == .Month {
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
        
        func cellTypeForPayIncrementalPaymentSection(row: Int) -> AddGoalViewCellType? {
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
        
        func cellTypeForStartEndSection(row: Int) -> AddGoalViewCellType? {
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
            case 4:
                return .ParentGoalCell
            default: break
            }
        } else {
            switch section {
            case 0:
                return cellTypeForDescriptionAmountSection(row: row) ?? defaultCellType
            case 1:
                return cellTypeForStartEndSection(row: row) ?? defaultCellType
            case 2:
                return .ParentGoalCell
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
            sections += period.scope == .Month ? 1 : 0
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
        
        func rowsInParentGoalSection() -> Int {
            return 1
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
            case 4:
                return rowsInParentGoalSection()
            default:
                return 0
            }
        } else {
            switch section {
            case 0:
                return rowsInDescriptionAmountSection()
            case 1:
                return rowsInStartEndSection()
            case 2:
                return rowsInParentGoalSection()
            default:
                return 0
            }
        }
    }
}

protocol AddGoalDelegate {
    func addedOrChangedGoal(_ goal: Goal)
}
