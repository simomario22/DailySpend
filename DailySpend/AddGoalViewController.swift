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
    var cellCreator: TableViewCellHelper!
    var scheduleController: PayScheduleTableViewController!
    var scheduleControllerIndex: Int = 0
    var scheduleNumSections = 0
    var initialScheduleHumanName = "Pay Schedule"
    var paySchedulesAreValid = true
    
    var delegate: AddGoalDelegate?
    
    var tableView: UITableView!
    
    var goalId: NSManagedObjectID?
    
    // Cell State
    var cellSizeCache = [AddGoalViewCellType: CGFloat]()

    // Goal Data
    var shortDescription: String?
    var carryOverBalance: Bool!
    var paySchedules: [StagedPaySchedule]!
    var parentGoal: Goal?

    let carryOverExplanatoryText = "For new periods, automatically create a " +
        "carry over adjustment with the balance at the end of the previous " +
        "period. Regardless of this setting, you can always create or " +
        "remove carry over adjustments manually for a particular period."

    override func viewDidLoad() {
        self.view.tintColor = .tint
        super.viewDidLoad()
        
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
        
        tableView = UITableView(frame: tableViewFrame, style: .grouped)
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
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        view.backgroundColor = tableView.backgroundColor
        
        cellCreator = TableViewCellHelper(tableView: tableView)
        scheduleController = PayScheduleTableViewController(
            tableView: tableView,
            cellCreator: cellCreator,
            endEditing: { self.view.endEditing(false) },
            sectionOffset: 1
        )

        let goal = (Goal.inContext(goalId) as? Goal)
        if let goal = goal {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, save)
            self.navigationItem.title = "Edit Goal"

            shortDescription = goal.shortDescription
            carryOverBalance = goal.carryOverBalance
            parentGoal = goal.parentGoal
            paySchedules = goal.sortedPaySchedules!.map(StagedPaySchedule.from)
            setupScheduleController(stagedSchedule: nil)
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, save)
            self.navigationItem.title = "New Goal"
            
            carryOverBalance = false
            paySchedules = [scheduleController.currentValues()]
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) {
            self.view.endEditing(false)
            self.dismiss(animated: true, completion: nil)
        }
    }

    /**
     * Sets up `scheduleController`, `scheduleControllerIndex`, and
     * `initialScheduleHumanName` based on the passed stagedSchedule, or finds
     * an initial staged schedule from `goalId` if the passed `stagedSchedule`
     * is nil.
     */
    private func setupScheduleController(stagedSchedule: StagedPaySchedule?) {
        var initialStagedSchedule: StagedPaySchedule! = stagedSchedule
        if initialStagedSchedule == nil {
            guard let goal = (Goal.inContext(goalId) as? Goal) else {
                Logger.debug("Failed to setupScheduleControllerWithSchedule without stagedSchedule or goalId.")
                return
            }
            // Get the initial schedule
            let initialPeriod = goal.getInitialPeriod(style: .period)!
            let initialSchedule = goal.activePaySchedule(on: initialPeriod.start)!
            initialStagedSchedule = StagedPaySchedule.from(initialSchedule)
        }

        guard let index = paySchedules.firstIndex(where: { $0 == initialStagedSchedule }) else {
            Logger.debug("Could not find schedule controller index.")
            return
        }
        self.scheduleControllerIndex = index

        let today = CalendarDay()
        let initialStagedInterval = CalendarInterval(
            start: initialStagedSchedule.start!,
            end: CalendarDay(dateInDay: initialStagedSchedule.end)?.end
        )!

        if initialStagedInterval.contains(date: today.start) {
            self.initialScheduleHumanName = "Current Pay Schedule"
        } else if today.start.gmtDate < initialStagedInterval.start.gmtDate {
            self.initialScheduleHumanName = "Most Recent Pay Schedule"
        } else {
            self.initialScheduleHumanName = "First Pay Schedule"
        }

        scheduleController.setupPaySchedule(schedule: initialStagedSchedule)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /**
     * This function returns `true` if changes to the initial pay schedule were
     * minor, the initial pay schedule is recurring, today is not in the
     * first period for this pay schedule, but is in the initial period, and
     * there exists another period after the current one.
     *
     * A pay schedule change is minor if the initial pay schedule still has
     * the same period, start, and end.
     */
    func shouldPromptForMinorInitialScheduleUpdateIntent() -> Bool {
        guard let goal = (Goal.inContext(goalId) as? Goal),
              let initialPeriod = goal.getInitialPeriod(style: .period),
              let cleanInitialSchedule = goal.activePaySchedule(on: initialPeriod.start),
              let firstPeriodInSchedule = GoalPeriod(goal: goal, date: cleanInitialSchedule.start!, style: .period)
            else {
            return false
        }

        let today = CalendarDay().start
        let cleanStagedInitialSchedule = StagedPaySchedule.from(cleanInitialSchedule)
        let currentInitialSchedule = scheduleController.currentValues()
        return cleanStagedInitialSchedule.period.scope != .None &&
                initialPeriod.contains(date: today) &&
                !firstPeriodInSchedule.contains(date: today) &&
                (
                    cleanStagedInitialSchedule.exclusiveEnd == nil ||
                    cleanStagedInitialSchedule.exclusiveEnd!.gmtDate > initialPeriod.end!.gmtDate
                ) &&
                currentInitialSchedule.period == cleanStagedInitialSchedule.period &&
                currentInitialSchedule.start?.gmtDate == cleanStagedInitialSchedule.start?.gmtDate &&
                currentInitialSchedule.end?.gmtDate == cleanStagedInitialSchedule.end?.gmtDate &&
                currentInitialSchedule != cleanStagedInitialSchedule

    }

    /**
     * Prompts the user to ensure they want the settings they saved their
     * schedule with, makes any necessary changes, validates those changes,
     * saves, and performs post save actions.
     *
     * Should only be called if shouldPromptForMinorInitialScheduleUpdateIntent
     * evaluates to true.
     */
    func promptForMinorInitialScheduleUpdateIntent(context: NSManagedObjectContext) {
        guard let goal = (Goal.inContext(goalId) as? Goal),
              let initialPeriod = goal.getInitialPeriod(style: .period)
            else {
                Logger.debug("Failed to set up cleanInitialSchedule to check for minor change.")
                return
        }
        let initialSchedule = scheduleController.currentValues()
        let df = DateFormatter()
        df.timeStyle = .none
        df.dateStyle = .short
        let initialStartString = initialSchedule.start!.string(formatter: df)
        let actionSheetMessage = "Making this change will affect all periods " +
            "since the start of this pay schedule, \(initialStartString). " +
            "Are you sure this is when you'd like your changes to take effect?"

        let actionSheet = UIAlertController(
            title: "Effective Date",
            message: actionSheetMessage,
            preferredStyle: .actionSheet
        )

        let scope = initialSchedule.period.scope
        var currentString = "No, take effect "
        var nextString = "No, take effect "
        if initialSchedule.period.multiplier == 1 {
            currentString += scope.currentString().lowercased()
            nextString += scope.nextString().lowercased()
        } else {
            let currentPeriodStartString = initialPeriod.start.string(formatter: df)
            let nextPeriodStartString = initialPeriod.end!.string(formatter: df)
            currentString += "this period (\(currentPeriodStartString))"
            nextString += "this period (\(nextPeriodStartString))"
        }
        let actions = [
            UIAlertAction(
                title: currentString,
                style: .default,
                handler: { _ in
                    createCopiedScheduleWithStart(initialPeriod.start)
                }
            ),
            UIAlertAction(
                title: nextString,
                style: .default,
                handler: { _ in
                    createCopiedScheduleWithStart(initialPeriod.end!)
                }
            ),
            UIAlertAction(
                title: "Yes, take effect \(initialStartString)",
                style: .default,
                handler: { _ in
                    context.performAndWait {
                        if context.hasChanges {
                            try! context.save()
                        }
                        self.goalId = goal.objectID
                        self.performPostSaveActions(validation: (true, nil))
                    }
                }
            ),
            UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: { _ in
                    context.performAndWait {
                        context.rollback()
                    }
                }
            ),
        ]

        actionSheet.addActions(actions)
        self.present(actionSheet, animated: true)

        func createCopiedScheduleWithStart(_ start: CalendarDateProvider) {
            context.performAndWait {
                context.rollback()
            }
            guard let cleanInitialSchedule = goal.activePaySchedule(on: initialPeriod.start) else {
                Logger.debug("Could not get clean initial schedule in promptForMinorInitialScheduleUpdateIntent")
                return
            }

            let newSchedule = StagedPaySchedule(
                amount: initialSchedule.amount,
                start: start,
                end: initialSchedule.end,
                period: initialSchedule.period,
                payFrequency: initialSchedule.payFrequency,
                adjustMonthAmountAutomatically: initialSchedule.adjustMonthAmountAutomatically
            )

            paySchedules[scheduleControllerIndex] = StagedPaySchedule(
                amount: cleanInitialSchedule.amount,
                start: cleanInitialSchedule.start,
                end: CalendarDay(dateInDay: start)?.subtract(days: 1).start,
                period: cleanInitialSchedule.period,
                payFrequency: cleanInitialSchedule.payFrequency,
                adjustMonthAmountAutomatically: cleanInitialSchedule.adjustMonthAmountAutomatically
            )

            paySchedules.insert(newSchedule, at: scheduleControllerIndex + 1)
            self.setupScheduleController(stagedSchedule: newSchedule)
            self.save()
        }
    }

    func save() {
        var validation: (valid: Bool, problem: String?)!
        var shouldPerformPostSaveActions = true
        let isNew = (goalId == nil)
        let context = appDelegate.persistentContainer.newBackgroundContext()
        context.performAndWait {
            var goal: Goal!
            if isNew {
                goal = Goal(context: context)
                goal.dateCreated = Date()
            } else {
                goal = Adjustment.inContext(goalId!, context: context)
            }

            // Delete all old schedules and replace them with new ones.
            let oldSchedules = goal.paySchedules
            for schedule in oldSchedules ?? [] {
                // Need to explicity nullify relationship since delete rules
                // won't be processed until context save.
                schedule.goal = nil
                context.delete(schedule)
            }

            paySchedules[scheduleControllerIndex] = scheduleController.currentValues()

            for stagedSchedule in paySchedules {
                let newSchedule = PaySchedule(context: context)
                validation = newSchedule.propose(
                    amount: stagedSchedule.amount,
                    start: stagedSchedule.start,
                    end: stagedSchedule.end,
                    period: stagedSchedule.period,
                    payFrequency: stagedSchedule.payFrequency,
                    adjustMonthAmountAutomatically: stagedSchedule.adjustMonthAmountAutomatically,
                    goal: goal,
                    dateCreated: Date()
                )
                if !validation.valid {
                    context.rollback()
                    return
                }
            }

            validation = goal.propose(
                shortDescription: shortDescription,
                parentGoal: Goal.inContext(parentGoal, context: context),
                carryOverBalance: carryOverBalance
            )

            if validation.valid && shouldPromptForMinorInitialScheduleUpdateIntent() {
                // The following function is responsible for validating any
                // changes it makes, saving those changes, and performing post
                // save actions.
                DispatchQueue.main.async {
                    self.promptForMinorInitialScheduleUpdateIntent(context: context)
                }
                shouldPerformPostSaveActions = false
                return
            }

            if !validation.valid {
                context.rollback()
            } else {
                if context.hasChanges {
                    try! context.save()
                }
                goalId = goal.objectID
            }
        }
        if shouldPerformPostSaveActions {
            performPostSaveActions(validation: validation)
        }
    }

    func performPostSaveActions(validation: (valid: Bool, problem: String?)) {
        self.view.endEditing(false)

        if validation.valid {
            let goalOnViewContext: Goal = Goal.inContext(goalId)!
            if let parentGoal = goalOnViewContext.parentGoal {
                appDelegate.persistentContainer.viewContext.refresh(parentGoal, mergeChanges: true)
            }
            delegate?.addedOrChangedGoal(goalOnViewContext)
            self.view.endEditing(false)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    enum AddGoalViewCellType {
        case DescriptionCell
        case CarryOverBalanceCell
        case ParentGoalCell
        case ManagePaySchedulesCell
    }

    private func isScheduleCell(path: IndexPath) -> Bool {
        return path.section > 0 && path.section < scheduleNumSections + 1
    }

    private func isScheduleSection(section: Int) -> Bool {
        return section > 0 && section < scheduleNumSections + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellCreator == nil {
            return UITableViewCell()
        }

        if isScheduleCell(path: indexPath) {
            let adjustedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section - 1)
            return scheduleController.tableView(tableView, cellForRowAt: adjustedIndexPath)
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
                    self.scheduleController.unexpandAllSections()
                }
            )
        case .CarryOverBalanceCell:
            return cellCreator.switchCell(
                initialValue: self.carryOverBalance,
                title: "Carry Over Balance",
                explanatoryText: carryOverExplanatoryText,
                valueChanged: { (newValue) in
                    self.carryOverBalance = newValue
                }
            )
        case .ParentGoalCell:
            return cellCreator.valueDisplayCell(
                labelText: "Parent Goal",
                valueText: parentGoal?.shortDescription ?? "None",
                detailIndicator: true
            )
        case .ManagePaySchedulesCell:
            return cellCreator.valueDisplayCell(
                labelText: "All Pay Schedules",
                valueText: paySchedulesAreValid ? "\(self.paySchedules.count)" : "Invalid",
                tintColor: paySchedulesAreValid ? .black : .red,
                detailIndicator: true
            )
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return initialScheduleHumanName
        case scheduleNumSections + 1:
            return "Additional Options"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isScheduleCell(path: indexPath) {
            let adjustedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section - 1)
            return scheduleController.tableView(tableView, didSelectRowAt: adjustedIndexPath)
        }

        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .ParentGoalCell:
            self.scheduleController.unexpandAllSections()
            let goalSelectorVC = GoalSelectorViewController()
            if let parentGoal = parentGoal {
                goalSelectorVC.setSelectedGoal(goal: parentGoal)
            }
            if let goalId = goalId {
                let goal = (Goal.inContext(goalId) as! Goal)
                goalSelectorVC.excludedGoals = Set<Goal>([goal]).union(goal.childGoals ?? Set<Goal>())
            }
            goalSelectorVC.showParentSelection = false
            goalSelectorVC.delegate = self
            navigationController?.pushViewController(goalSelectorVC, animated: true)
        case .ManagePaySchedulesCell:
            self.scheduleController.unexpandAllSections()
            paySchedules[scheduleControllerIndex] = scheduleController.currentValues()
            let managePaySchedulesVC = ManagePaySchedulesController()
            managePaySchedulesVC.setPaySchedules(self.paySchedules)
            managePaySchedulesVC.delegate = self
            navigationController?.pushViewController(managePaySchedulesVC, animated: true)
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isScheduleCell(path: indexPath) {
            let adjustedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section - 1)
            return scheduleController.tableView(tableView, heightForRowAt: adjustedIndexPath)
        }

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
        case .CarryOverBalanceCell:
            return height(.CarryOverBalanceCell, SwitchTableViewCell.self, carryOverExplanatoryText)
        default:
            return 44
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        scheduleNumSections = scheduleController.numberOfSections(in: self.tableView)
        return 2 + scheduleNumSections
    }

    func reloadParentGoalCell() {
        let section = scheduleNumSections + 1
        tableView.reloadRows(at: [IndexPath(row: 0, section: section)], with: .fade)
    }

    func reloadManagePaySchedulesCell() {
        let section = scheduleNumSections + 1
        tableView.reloadRows(at: [IndexPath(row: 1, section: section)], with: .fade)
    }
    
    func dismissedGoalSelectorWithSelectedGoal(_ goal: Goal?) {
        parentGoal = goal
        reloadParentGoalCell()
    }
    
    func cellTypeForIndexPath(indexPath: IndexPath) -> AddGoalViewCellType {
        let defaultCellType = AddGoalViewCellType.DescriptionCell

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                return .DescriptionCell
            default:
                return defaultCellType
            }
        case scheduleNumSections + 1:
            switch indexPath.row {
            case 0:
                return .ParentGoalCell
            case 1:
                return .ManagePaySchedulesCell
            case 2:
                return .CarryOverBalanceCell
            default:
                return defaultCellType
            }
        default:
            return defaultCellType
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isScheduleSection(section: section) {
            let rows = scheduleController.tableView(tableView, numberOfRowsInSection: section - 1)
            return rows
        }

        switch section {
        case 0:
            return 1
        case scheduleNumSections + 1:
            return 3
        default:
            return 0
        }
    }
}

extension AddGoalViewController: ManagedPaySchedulesControllerDelegate {
    func updatedPaySchedules(schedules: [StagedPaySchedule]!, initial: StagedPaySchedule?, valid: Bool) {
        self.paySchedules = schedules
        self.setupScheduleController(stagedSchedule: initial ?? StagedPaySchedule.defaultValues())
        self.paySchedulesAreValid = valid
        self.tableView.reloadData()
    }
}

protocol AddGoalDelegate {
    func addedOrChangedGoal(_ goal: Goal)
}
