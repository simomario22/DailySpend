//
//  ManagePaySchedulesController.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/27/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import UIKit

class ManagePaySchedulesController: UIViewController {
    var delegate: ManagedPaySchedulesControllerDelegate?
    func setPaySchedules(_ schedules: [StagedPaySchedule]) {
        self.payScheduleCellData = createCellData(from: schedules)
    }

    private var tableView: UITableView!
    private var cellCreator: TableViewCellHelper!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationItem.title = "Pay Schedules"
        self.navigationController?.delegate = self

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, {
            self.editPayIntervalAtIndex(index: nil)
        })

        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        let topInset = navHeight + statusBarHeight
        let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        // Set up table view.
        let tableViewFrame = CGRect(
            x: 0,
            y: topInset,
            width: view.frame.size.width,
            height: view.frame.size.height - topInset
        )

        self.tableView = UITableView(frame: tableViewFrame, style: .grouped)
        self.tableView.estimatedRowHeight = 0
        self.tableView.estimatedSectionHeaderHeight = 0
        self.tableView.estimatedSectionFooterHeight = 0
        self.tableView.scrollIndicatorInsets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: bottomInset,
            right: 0
        )
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.keyboardDismissMode = .interactive
        self.cellCreator = TableViewCellHelper(tableView: self.tableView)
        self.view.addSubview(self.tableView)
        self.setCellHeights()
    }

    private struct PayScheduleDatum {
        var schedule: StagedPaySchedule
        var height: CGFloat
        var passesValidation: Bool
        var reasonForInvalidity: String?
        var overlapsWithPrevious: Bool
        var overlapsWithNext: Bool
    }
    /**
     * Pay schedules with cell data sorted from oldest to most recent, with
     * `nil` elements in any gaps between schedules.
     */
    private var payScheduleCellData: [PayScheduleDatum?]!

    /**
     * Pay schedules sorted from oldest to most recent.
     */
    private var paySchedules: [StagedPaySchedule] {
        return payScheduleCellData.filter({ (datum) -> Bool in
            return datum != nil
        }).map({ (datum) -> StagedPaySchedule in
            return datum!.schedule
        })
    }

    var gapCellHeight: CGFloat? = nil

    func remakeCells() {
        self.setPaySchedules(self.paySchedules)
        self.setCellHeights()
    }

    func setCellHeights() {
        for (i, datum) in self.payScheduleCellData.enumerated() {
            if datum == nil && gapCellHeight != nil {
                continue
            }

            let cell = makePayScheduleCell(datum: datum)
            if let longEntryCell = cell as? LongFormEntryTableViewCell {
                longEntryCell.frame = self.tableView.frame
                let height = longEntryCell.getCellHeight()
                if datum == nil {
                    self.gapCellHeight = height
                } else {
                    self.payScheduleCellData[i]!.height = height
                }
            }
        }
    }

    /**
     * Adds `nil` elements where there should be pay schedules.
     */
    private func createCellData(from schedules: [StagedPaySchedule]) -> [PayScheduleDatum?]! {
        // Sort from earliest start date to latest start date, with nil at
        // beginning.
        let sortedSchedules = schedules.sorted { (left, right) in
            if left.start == nil {
                return true
            } else if right.start == nil {
                return false
            } else {
                return left.start!.gmtDate < right.start!.gmtDate
            }
        }

        var cellData = [PayScheduleDatum?]()
        for (i, schedule) in sortedSchedules.enumerated() {
            let validation = PaySchedule.partialValueValidation(
                amount: schedule.amount,
                start: schedule.start,
                end: schedule.end,
                period: schedule.period,
                payFrequency: schedule.payFrequency
            )
            let previous = sortedSchedules[safe: i - 1]
            let next = sortedSchedules[safe: i + 1]

            // Create datum and calculate true height.
            let datum = PayScheduleDatum(
                schedule: schedule,
                height: 64,
                passesValidation: validation.valid,
                reasonForInvalidity: validation.problem,
                overlapsWithPrevious: areOverlappingSchedules(schedule, previous),
                overlapsWithNext: areOverlappingSchedules(schedule, next)
            )

            cellData.append(datum)

            if next?.start != nil && schedule.end != nil &&
               CalendarDay(dateInDay: schedule.end!).end!.gmtDate < next!.start!.gmtDate {
                // Append a "gap" cell.
                cellData.append(nil)
            }
        }
        return cellData
    }

    /**
     * Given two StagedPaySchedules, returns true if they overlap with each
     * other.
     */
    private func areOverlappingSchedules(_ one: StagedPaySchedule?, _ two: StagedPaySchedule?) -> Bool {
        guard let oneStart = one?.start,
              let twoStart = two?.start,
              let oneInterval = CalendarInterval(start: oneStart, end: one?.end),
              let twoInterval = CalendarInterval(start: twoStart, end: two?.end) else {
            return false
        }

        return oneInterval.overlaps(with: twoInterval)
    }

    func shortHumanScheduleDescription(schedule: StagedPaySchedule) -> String {
        return PaySchedule.string(
            amount: schedule.amount!,
            period: schedule.period,
            payFrequency: schedule.payFrequency
        )
    }
}

extension ManagePaySchedulesController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payScheduleCellData.count
    }

    private func makePayScheduleCell(datum: PayScheduleDatum?) -> UITableViewCell {
        if cellCreator == nil {
            return UITableViewCell()
        }

        var descriptionText = ""
        var valueText = ""
        var isValid: Bool = true
        var isActive: Bool = false

        if let datum = datum {
            let df = DateFormatter()
            df.timeStyle = .none
            df.dateStyle = .short

            if let start = datum.schedule.start,
                let inclusiveInterval = CalendarInterval(start: start, end: datum.schedule.end),
                let exclusiveInterval = CalendarInterval(start: start, end: datum.schedule.exclusiveEnd) {
                descriptionText = inclusiveInterval.string(formatter: df, relative: false)
                if exclusiveInterval.contains(date: CalendarDay().start) {
                    descriptionText = "Current: " + descriptionText
                    isActive = true
                }
            } else {
                descriptionText = "Invalid Schedule"
            }

            if datum.overlapsWithPrevious && datum.overlapsWithNext {
                valueText = "This schedule overlaps with multiple schedules."
                isValid = false
            } else if datum.overlapsWithPrevious {
                valueText = "This schedule overlaps with the previous schedule."
                isValid = false
            } else if datum.overlapsWithNext {
                valueText = "This schedule overlaps with the following schedule."
                isValid = false
            } else if !datum.passesValidation {
                valueText = datum.reasonForInvalidity ?? "Tap to fix."
                isValid = false
            } else {
                valueText = shortHumanScheduleDescription(schedule: datum.schedule)
            }
        } else {
            descriptionText = "Create new schedule..."
            valueText = "Gap between schedules. Tap to add a schedule in the " +
                        "gap, or adjust the start and end dates of other " +
                        "schedules to remove the gap."
            isValid = false
        }

        return cellCreator.longFormTextInputCell(
            descriptionText: descriptionText,
            valueText: valueText,
            isValueEditable: false,
            isDescriptionBold: true,
            descriptionColor: !isValid ? .red : isActive ? .tint : .black,
            valueColor: isValid ? .black : .red,
            detailDisclosure: true,
            expectedCellWidth: self.tableView.frame.size.width
        )
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return makePayScheduleCell(datum: self.payScheduleCellData[indexPath.row])
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return payScheduleCellData[indexPath.row] != nil
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            payScheduleCellData.remove(at: indexPath.row)

            // UITableView can't handle this animation properly, so just do it
            // manually.
            let animationTime = 0.5
            UIView.animate(withDuration: animationTime) {
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + animationTime) {
                // Ensure the number of cells did not change (e.g. by deleting
                // a schedule in between two gaps).
                let numCells = self.payScheduleCellData.count
                self.remakeCells()
                if self.payScheduleCellData.count != numCells {
                    // We aren't sure which were removed, so just reload.
                    self.tableView.reloadData()
                    return
                }
                var rowsToReload = [IndexPath]()
                if indexPath.row < self.payScheduleCellData.count {
                    rowsToReload.append(indexPath)
                }

                if indexPath.row - 1 < self.payScheduleCellData.count {
                    rowsToReload.append(IndexPath(row: indexPath.row - 1, section: indexPath.section))
                }

                self.tableView.reloadRows(at: rowsToReload, with: .fade)

            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.payScheduleCellData[indexPath.row]?.height ?? gapCellHeight ?? 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.editPayIntervalAtIndex(index: indexPath.row)
    }
}

extension ManagePaySchedulesController: UINavigationControllerDelegate {
    /**
     * Returns an initial pay schedule from paySchedules based on when it starts
     * relative to today.
     *
     * If the final schedule ended before today, it will return the final schedule.
     * If the any schedule is active today, it will return the current schedule.
     * If the first schedule begins after today, it will return the first schedule.
     * If this goal has no pay schedules, it will return `nil`.
     */
    private func getInitialPaySchedule() -> StagedPaySchedule? {
        guard let firstSchedule = self.paySchedules.first,
              let lastSchedule = self.paySchedules.last else {
            return nil
        }

        let today = CalendarDay().start
        if lastSchedule.end != nil && lastSchedule.end!.gmtDate < today.gmtDate {
            return lastSchedule
        } else if firstSchedule.start != nil && firstSchedule.start!.gmtDate > today.gmtDate {
            return firstSchedule
        } else {
            return self.paySchedules.first(where: { (schedule) -> Bool in
                if let start = schedule.start {
                    let end = CalendarDay(dateInDay: schedule.end)?.end
                    let interval = CalendarInterval(start: start, end: end)
                    return interval?.contains(date: today) ?? false
                }
                return false
            })
        }
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is ManagedPaySchedulesControllerDelegate {
            // This VC is being dismissed.
            var valid = !paySchedules.isEmpty
            for datum in payScheduleCellData {
                guard let datum = datum,
                    datum.passesValidation,
                    !datum.overlapsWithPrevious,
                    !datum.overlapsWithNext else {
                    valid = false
                    break
                }
            }
            delegate?.updatedPaySchedules(schedules: paySchedules, initial: getInitialPaySchedule(), valid: valid)
        }
    }
}

extension ManagePaySchedulesController {

    func makeEditControllerTableView() -> UITableView {
        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)

        let topInset = navHeight + statusBarHeight
        let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        // Set up table view.
        let tableViewFrame = CGRect(
            x: 0,
            y: topInset,
            width: view.frame.size.width,
            height: view.frame.size.height - topInset
        )

        let tableView = UITableView(frame: tableViewFrame, style: .grouped)
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.scrollIndicatorInsets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: bottomInset,
            right: 0
        )
        tableView.keyboardDismissMode = .onDrag

        return tableView
    }

    func save(schedule: StagedPaySchedule, at index: Int?, vc: UIViewController) {
        if index != nil && self.payScheduleCellData[index!] != nil {
            self.payScheduleCellData[index!]!.schedule = schedule
        } else {
            let datum = PayScheduleDatum(
                schedule: schedule,
                height: -1,
                passesValidation: false,
                reasonForInvalidity: nil,
                overlapsWithPrevious: false,
                overlapsWithNext: false
            )
            self.payScheduleCellData.append(datum)
        }

        self.remakeCells()
        self.tableView.reloadData()
        self.navigationController?.popViewController(animated: true)
    }

    func editPayIntervalAtIndex(index: Int?) {
        let tableView = makeEditControllerTableView()
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        vc.view.addSubview(tableView)

        let payScheduleTableVC = PayScheduleTableViewController(
            tableView: tableView,
            cellCreator: cellCreator,
            endEditing: { vc.view.endEditing(false) },
            sectionOffset: 0
        )

        var schedule: StagedPaySchedule? = nil
        if let index = index,
           let datum = self.payScheduleCellData[safe: index] {
            if datum == nil {
                // This is a gap, get the previous and next, which must exist
                // around a gap.
                let previous = self.payScheduleCellData[index - 1]!.schedule
                let next = self.payScheduleCellData[index + 1]!.schedule
                let previousExclusiveEnd = CalendarDay(dateInDay: previous.end!).end!
                let nextStart = CalendarDay(dateInDay: next.start!).subtract(days: 1).start
                schedule = StagedPaySchedule(
                    amount: nil,
                    start: previousExclusiveEnd,
                    end: nextStart,
                    period: previous.period,
                    payFrequency: previous.payFrequency,
                    adjustMonthAmountAutomatically: previous.adjustMonthAmountAutomatically
                )
            } else {
                schedule = datum!.schedule
            }
        } else if let last = self.paySchedules.last {
            // Set based on most recent values.
            schedule = StagedPaySchedule(
                amount: nil,
                start: CalendarDay(dateInDay: last.end)?.end ?? CalendarDay().start,
                end: nil,
                period: last.period,
                payFrequency: last.payFrequency,
                adjustMonthAmountAutomatically: last.adjustMonthAmountAutomatically
            )
        }

        if let schedule = schedule {
            payScheduleTableVC.setupPaySchedule(schedule: schedule)
        }

        tableView.dataSource = payScheduleTableVC
        tableView.delegate = payScheduleTableVC

        vc.navigationItem.title = index == nil ? "Add Schedule" : "Edit Schedule"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, {
                let schedule = payScheduleTableVC.currentValues()
                self.save(schedule: schedule, at: index, vc: vc)
        })

        self.navigationController?.pushViewController(vc, animated: true)
    }
}

protocol ManagedPaySchedulesControllerDelegate {
    func updatedPaySchedules(schedules: [StagedPaySchedule]!, initial: StagedPaySchedule?, valid: Bool)
}
