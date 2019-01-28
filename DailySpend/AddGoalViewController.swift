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
            let initialPeriod = goal.getInitialPeriod()!
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
            end: initialStagedSchedule.end
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
    
    func save() {
        var validation: (valid: Bool, problem: String?)!
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

            if !validation.valid {
                context.rollback()
            } else {
                if context.hasChanges {
                    try! context.save()
                }
                self.view.endEditing(false)
                goalId = goal.objectID
            }
        }

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
                valueText: paySchedulesAreValid ? nil : "Invalid",
                tintColor: .red,
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
            let managePaySchedulesVC = ManagePaySchedulesController()
            managePaySchedulesVC.paySchedules = self.paySchedules
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
    func updatedPaySchedules(schedules: [StagedPaySchedule]!, initial: StagedPaySchedule, valid: Bool) {
        self.paySchedules = schedules
        self.setupScheduleController(stagedSchedule: initial)
        self.paySchedulesAreValid = valid
    }
}

protocol AddGoalDelegate {
    func addedOrChangedGoal(_ goal: Goal)
}
