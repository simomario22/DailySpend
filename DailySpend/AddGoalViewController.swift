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
    
    var delegate: AddGoalDelegate?
    
    var tableView: UITableView!
    var segmentedControl: UISegmentedControl!
    var toolbar: BorderedToolbar!
    
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
        let toolbarFrame = CGRect(x: 0, y: navHeight + statusBarHeight, width: view.frame.size.width, height: 44)

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

            let initialPeriod = goal.getInitialPeriod()!
            let initialSchedule = goal.activePaySchedule(on: initialPeriod.start)!
            scheduleController.setupPaySchedule(schedule: StagedPaySchedule.from(initialSchedule))
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

        if let goalId = goalId {
            let goalOnViewContext: Goal = Goal.inContext(goalId)!
            if let parentGoal = goalOnViewContext.parentGoal {
                appDelegate.persistentContainer.viewContext.refresh(parentGoal, mergeChanges: true)
            }
            delegate?.addedOrChangedGoal(goalOnViewContext)
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
        navigationController?.navigationBar.hideBorderLine()
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.showBorderLine()
        super.viewWillDisappear(animated)
    }
    
    enum AddGoalViewCellType {
        case DescriptionCell
        case CarryOverBalanceCell
        case ParentGoalCell
    }

    private func isScheduleCell(path: IndexPath) -> Bool {
        return path.section > 0
    }

    private func isScheduleSection(section: Int) -> Bool {
        return section > 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellCreator == nil {
            return UITableViewCell()
        }

        if isScheduleCell(path: indexPath) {
            return scheduleController.tableView(tableView, cellForRowAt: indexPath)
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
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        case .CarryOverBalanceCell:
            return height(.CarryOverBalanceCell, SwitchTableViewCell.self, carryOverExplanatoryText)
        default:
            return 44
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let paySections = scheduleController.numberOfSections(in: self.tableView)
        return 1 + paySections
    }

    func reloadParentGoalCell() {
        let section = 0
        tableView.reloadRows(at: [IndexPath(row: 0, section: section)], with: .fade)
    }
    
    func dismissedGoalSelectorWithSelectedGoal(_ goal: Goal?) {
        parentGoal = goal
        reloadParentGoalCell()
    }
    
    func cellTypeForIndexPath(indexPath: IndexPath) -> AddGoalViewCellType {
        switch indexPath.row {
        case 0:
            return .DescriptionCell
        case 1:
            return .ParentGoalCell
        case 2:
            return .CarryOverBalanceCell
        default:
            return .DescriptionCell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isScheduleSection(section: section) {
            return scheduleController.tableView(tableView, numberOfRowsInSection: section)
        }

        return 3
    }
}

protocol AddGoalDelegate {
    func addedOrChangedGoal(_ goal: Goal)
}
