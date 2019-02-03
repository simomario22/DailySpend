//
//  PayScheduleTableViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/19/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import Foundation


class PayScheduleTableViewController : NSObject {
    private var amount: Decimal?
    private var adjustMonthAmountAutomatically: Bool!
    private var period: Period
    private var payFrequency: Period
    private var start: CalendarDateProvider!
    private var end: CalendarDateProvider?

    init(
        tableView: UITableView,
        cellCreator: TableViewCellHelper,
        endEditing: @escaping () -> (),
        sectionOffset: Int
    ) {
        self.tableView = tableView
        self.cellCreator = cellCreator
        self.endEditing = endEditing
        self.sectionOffset = sectionOffset

        adjustMonthAmountAutomatically = true
        period = Period(scope: .Month, multiplier: 1)
        adjustMonthAmountAutomatically = true
        payFrequency = Period(scope: .Day, multiplier: 1)
        start = CalendarDay().start
    }

    func setupPaySchedule(schedule: StagedPaySchedule) {
        self.amount = schedule.amount
        self.adjustMonthAmountAutomatically = schedule.adjustMonthAmountAutomatically
        self.period = schedule.period
        self.payFrequency = schedule.payFrequency
        self.start = schedule.start!
        self.end = schedule.end

        isRecurring = schedule.period.scope != .None
        hasIncrementalPayment = schedule.payFrequency.scope != .None
        neverEnd = schedule.end == nil
    }

    func currentValues() -> StagedPaySchedule {
        return StagedPaySchedule(
            amount: amount,
            start: start,
            end: neverEnd ? nil : end,
            period: isRecurring ? period : Period.none,
            payFrequency: isRecurring && hasIncrementalPayment ? payFrequency : Period.none,
            adjustMonthAmountAutomatically: isRecurring && period.scope == .Month ? adjustMonthAmountAutomatically : false
        )
    }


    /**
     * Sets all sections to unexpanded.
     */
    func unexpandAllSections() {
        // Public interface for setExpandedSection(.None)
        setExpandedSection(.None)
    }

    private let tableView: UITableView!
    private let cellCreator: TableViewCellHelper!
    private let endEditing: () -> ()
    private let sectionOffset: Int
    private func offset(_ section: Int) -> Int {
        return section + sectionOffset
    }

    private var isRecurring = true
    private var hasIncrementalPayment = false
    private var neverEnd = true

    private var expandedSection: PayScheduleExpandableSectionType = .None
    private var cellSizeCache = [PayScheduleViewCellType: CGFloat]()

    let periodLengthExplanatoryText = "The length of the period you have to " +
        "spend the above amount."

    let autoAdjustExplanatoryText = "Adjust the amount per month based on the " +
        "number of days in a month (the amount above will be used for a 30 " +
        "day month)."

    let incrementalPaymentExplanatoryText = "Pay equally portioned amounts at " +
        "intervals throughout the goal period to help you stay on track " +
        "rather than paying the full amount at the beginning of the period."

    let periodPickerRows = [(1...100).map({"\($0)"}), ["Day", "Week", "Month"]]

    private enum PayScheduleViewCellType {
        case AmountPerPeriodCell
        case RecurringCell
        case PeriodLengthCell
        case PeriodLengthPickerCell
        case AutoAdjustMonthAmountCell
        case IncrementalPaymentCell
        case PayIntervalCell
        case PayIntervalPickerCell
        case StartCell
        case StartPickerCell
        case EndCell
        case EndNeverPickerCell
        case EndPickerCell
    }

    private enum PayScheduleExpandableSectionType {
        case None
        case PeriodLengthPicker
        case PayIntervalPicker
        case StartDayPicker
        case EndNeverAndDayPicker
    }

    private func reloadExpandedSectionLabel(_ section: PayScheduleExpandableSectionType, scroll: Bool = false) {
        let startEndSection = offset(isRecurring ? 2 : 1)
        var path = IndexPath()
        switch section {
        case .PeriodLengthPicker:
            let section = offset(0)
            path = IndexPath(row: 2, section: section)
        case .PayIntervalPicker:
            let section = offset(1)
            path = IndexPath(row: 1, section: section)
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
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }

    private func toggleExpandedSection(_ section: PayScheduleExpandableSectionType) {
        setExpandedSection(section != expandedSection ? section : .None)
    }

    private func setExpandedSection(_ newSection: PayScheduleExpandableSectionType) {
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

        func reloadSection(_ section: PayScheduleExpandableSectionType,
                           delete: Bool,
                           adjacentRows: Bool) -> IndexPath? {
            let startEndSection = offset(isRecurring ? 2 : 1)

            switch section {
            case .PeriodLengthPicker:
                let section = offset(0)
                reload(row: 2, section: section, delete: delete)
                return IndexPath(row: 3, section: section)
            case .PayIntervalPicker:
                let section = offset(1)
                reload(row: 1, section: section, delete: delete)
                return IndexPath(row: 2, section: section)
            case .StartDayPicker:
                reload(row: 0, section: startEndSection, delete: delete, next: adjacentRows ? 0 : 1)
                return IndexPath(row: 1, section: startEndSection)
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
            tableView.scrollToRow(at: path!, at: .middle, animated: true)
        }
    }

    private func insertRecurringSectionsAndCells(delete: Bool = false) {
        let sections = IndexSet([offset(1)])
        let sectionsAction = (delete ? self.tableView.deleteSections : self.tableView.insertSections)
        sectionsAction(sections, .fade)

        let section0 = offset(0)
        var paths = [IndexPath(row: 2, section: section0)]
        if period.scope == .Month {
            paths.append(IndexPath(row: 3, section: section0))
        }
        let rowsAction = (delete ? self.tableView.deleteRows : self.tableView.insertRows)
        rowsAction(paths, .fade)
    }

    private func removeRecurringSectionsAndCells() {
        self.insertRecurringSectionsAndCells(delete: true)
    }

    private func insertEndDayPickerCell() {
        let section = offset(isRecurring ? 2 : 1)
        let path = IndexPath(row: 3, section: section)
        tableView.insertRows(at: [path], with: .fade)
        tableView.scrollToRow(at: path, at: .middle, animated: true)
    }

    private func removeEndDayPickerCell() {
        let section = offset(isRecurring ? 2 : 1)
        tableView.deleteRows(at: [IndexPath(row: 3, section: section)], with: .fade)
    }

    private func insertPayIntervalCell() {
        guard isRecurring else {
            return
        }
        let section = offset(1)
        let path = IndexPath(row: 1, section: section)
        tableView.insertRows(at: [path], with: .fade)
        tableView.scrollToRow(at: path, at: .middle, animated: true)
    }

    private func removePayIntervalCell() {
        guard isRecurring else {
            return
        }
        let section = offset(1)
        tableView.deleteRows(at: [IndexPath(row: 1, section: section)], with: .fade)
    }

    private func insertAdjustMonthAmountAutomaticallyCell() {
        guard isRecurring else {
            return
        }
        let row = expandedSection == .PeriodLengthPicker ? 4 : 3
        let section = offset(0)
        let path = IndexPath(row: row, section: section)
        tableView.insertRows(at: [path], with: .fade)
    }

    private func removeAdjustMonthAmountAutomaticallyCell() {
        guard isRecurring else {
            return
        }
        let row = expandedSection == .PeriodLengthPicker ? 4 : 3
        let section = offset(0)
        tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: .fade)
    }

    private func cellTypeForIndexPath(indexPath: IndexPath) -> PayScheduleViewCellType {
        let section = indexPath.section
        let row = indexPath.row

        let defaultCellType: PayScheduleViewCellType = .AmountPerPeriodCell

        func cellTypeForAmountSection(row: Int) -> PayScheduleViewCellType? {
            switch row {
            case 0:
                return .AmountPerPeriodCell
            case 1:
                return .RecurringCell
            case 2:
                return .PeriodLengthCell
            case 3:
                if expandedSection == .PeriodLengthPicker {
                    return .PeriodLengthPickerCell
                } else {
                    return .AutoAdjustMonthAmountCell
                }
            case 4:
                return .AutoAdjustMonthAmountCell

            default:
                return nil
            }
        }

        func cellTypeForPayIncrementalPaymentSection(row: Int) -> PayScheduleViewCellType? {
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

        func cellTypeForStartEndSection(row: Int) -> PayScheduleViewCellType? {
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

        if isRecurring {
            switch section {
            case 0:
                return cellTypeForAmountSection(row: row) ?? defaultCellType
            case 1:
                return cellTypeForPayIncrementalPaymentSection(row: row) ?? defaultCellType
            case 2:
                return cellTypeForStartEndSection(row: row) ?? defaultCellType
            default: break
            }
        } else {
            switch section {
            case 0:
                return cellTypeForAmountSection(row: row) ?? defaultCellType
            case 1:
                return cellTypeForStartEndSection(row: row) ?? defaultCellType
            default: break
            }
        }
        return defaultCellType
    }
}

extension PayScheduleTableViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .AmountPerPeriodCell:
            return cellCreator.currencyDisplayCell(
                title: "Amount",
                amount: amount,
                changedToAmount: { (newAmount) in
                    self.amount = newAmount
            })
        case .RecurringCell:
            return cellCreator.switchCell(
                initialValue: isRecurring,
                title: "Recurring",
                valueChanged: { (newValue) in
                    if newValue != self.isRecurring {
                        if self.expandedSection == .PeriodLengthPicker ||
                            self.expandedSection == .PayIntervalPicker {
                            self.setExpandedSection(.None)
                        }

                        self.tableView.beginUpdates()
                        self.isRecurring = newValue

                        if self.isRecurring {
                            self.insertRecurringSectionsAndCells()
                        } else {
                            self.removeRecurringSectionsAndCells()
                        }
                        self.tableView.endUpdates()
                    }
            })
        case .PeriodLengthCell:
            return cellCreator.valueDisplayCell(
                labelText: "Period Length",
                valueText: period.string(),
                explanatoryText: periodLengthExplanatoryText,
                tintColor: expandedSection == .PeriodLengthPicker ? .tint : nil
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

                    let newPeriod = PeriodScope(values[1])

                    self.tableView.beginUpdates()
                    if newPeriod == .Month && self.period.scope != newPeriod {
                        self.insertAdjustMonthAmountAutomaticallyCell()
                    } else if self.period.scope == .Month && self.period.scope != newPeriod {
                        self.removeAdjustMonthAmountAutomaticallyCell()
                    }

                    self.period.scope = newPeriod

                    self.reloadExpandedSectionLabel(.PeriodLengthPicker)
                    if self.hasIncrementalPayment {
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
        case .IncrementalPaymentCell:
            return cellCreator.switchCell(
                initialValue: hasIncrementalPayment,
                title: "Incremental Payment",
                explanatoryText: incrementalPaymentExplanatoryText,
                valueChanged: { (newValue) in
                    if self.expandedSection == .PayIntervalPicker {
                        self.setExpandedSection(.None)
                    }

                    self.hasIncrementalPayment = newValue

                    if self.hasIncrementalPayment {
                        self.insertPayIntervalCell()
                    } else {
                        self.removePayIntervalCell()
                    }
            })
        case .PayIntervalCell:
            return cellCreator.valueDisplayCell(
                labelText: "Pay Interval",
                valueText: "Every " + payFrequency.string(),
                tintColor: expandedSection == .PayIntervalPicker ? .tint : nil,
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
                tintColor: expandedSection == .StartDayPicker ? .tint : nil
            )
        case .StartPickerCell:
            return cellCreator.periodPickerCell(
                date: start,
                scope: .Day,
                changedToDate: { (date: CalendarDateProvider, scope: PeriodScope) in
                    self.start = date

                    if self.end != nil && self.start!.gmtDate > self.end!.gmtDate {
                        // End day earlier than start day - set it to start.
                        self.end = self.start
                        self.reloadExpandedSectionLabel(.EndNeverAndDayPicker)
                    }

                    self.reloadExpandedSectionLabel(.StartDayPicker)
            })
        case .EndCell:
            return cellCreator.dateDisplayCell(
                label: "End",
                day: self.neverEnd ? nil : CalendarDay(dateInDay: end!),
                tintColor: expandedSection == .EndNeverAndDayPicker ? .tint : nil,
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
                    self.reloadExpandedSectionLabel(.EndNeverAndDayPicker)
            })
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .PeriodLengthCell:
            endEditing()
            toggleExpandedSection(.PeriodLengthPicker)
        case .PayIntervalCell:
            endEditing()
            toggleExpandedSection(.PayIntervalPicker)
        case .StartCell:
            endEditing()
            toggleExpandedSection(.StartDayPicker)
        case .EndCell:
            endEditing()
            toggleExpandedSection(.EndNeverAndDayPicker)
        default: break
        }

        let adjustedIndexPath = IndexPath(row: indexPath.row, section: offset(indexPath.section))
        tableView.deselectRow(at: adjustedIndexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        func height(_ cellType: PayScheduleViewCellType,
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
        return isRecurring ? 3 : 2
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        func rowsInAmountSection() -> Int {
            var rows = 2
            rows += isRecurring ? 1 : 0
            rows += isRecurring && expandedSection == .PeriodLengthPicker ? 1 : 0
            rows += isRecurring && period.scope == .Month ? 1 : 0
            return rows
        }

        func rowsInPayIncrementalPaymentSection() -> Int {
            var sections = 1
            sections += hasIncrementalPayment ? 1 : 0
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

        if isRecurring {
            switch section {
            case 0:
                return rowsInAmountSection()
            case 1:
                return rowsInPayIncrementalPaymentSection()
            case 2:
                return rowsInStartEndSection()
            default:
                return 0
            }
        } else {
            switch section {
            case 0:
                return rowsInAmountSection()
            case 1:
                return rowsInStartEndSection()
            default:
                return 0
            }
        }
    }
}

struct StagedPaySchedule : Equatable {
    var amount: Decimal?
    var start: CalendarDateProvider?
    var end: CalendarDateProvider?
    var period: Period
    var payFrequency: Period
    var adjustMonthAmountAutomatically: Bool

    var exclusiveEnd: CalendarDateProvider? {
        return CalendarDay(dateInDay: end)?.end
    }

    static func from(_ schedule: PaySchedule) -> StagedPaySchedule {
        return StagedPaySchedule(
            amount: schedule.amount,
            start: schedule.start,
            end: schedule.end,
            period: schedule.period,
            payFrequency: schedule.payFrequency,
            adjustMonthAmountAutomatically: schedule.adjustMonthAmountAutomatically
        )
    }

    static func defaultValues(
        start: CalendarDateProvider? = nil,
        end: CalendarDateProvider? = nil
    ) -> StagedPaySchedule {
        return StagedPaySchedule(
            amount: nil,
            start: start,
            end: end,
            period: Period(scope: .Month, multiplier: 1),
            payFrequency: Period(scope: .Day, multiplier: 1),
            adjustMonthAmountAutomatically: true
        )
    }

    static func == (lhs: StagedPaySchedule, rhs: StagedPaySchedule) -> Bool {
        return lhs.amount == rhs.amount &&
                lhs.start?.gmtDate == rhs.start?.gmtDate &&
                lhs.end?.gmtDate == rhs.end?.gmtDate &&
                lhs.period == rhs.period &&
                lhs.payFrequency == rhs.payFrequency &&
                lhs.adjustMonthAmountAutomatically == rhs.adjustMonthAmountAutomatically
    }
}
