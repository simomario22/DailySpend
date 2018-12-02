//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/12/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class ReviewViewController: UIViewController {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    private var pbc: PeriodBrowserController!
    private var neutralBarColor: UIColor!
    private var tableView: UITableView!
    private var cellCreator: TableViewCellHelper!
    
    private var entityProviders = [(
        provider: ReviewEntityDataProvider,
        labelMessage: String,
        createMessage: String
    )]()

    /**
     * The current period that is being shown to the user, or `nil` if `goal`
     * not a recurring period.
     */
    private var recurringGoalPeriod: CalendarPeriod?
    
    /**
     * Goal picker must be set prior to view loading with a
     * NavigationGoalPicker associated with this controller's navigation
     * controller.
     */
    var goalPicker: NavigationGoalPickerController!
    
    /**
     * The current interval that is being shown to the user, which may be an
     * open ended period if this goal is not recurring and does not have an end
     * date.
     */
    var interval: CalendarIntervalProvider! {
        return recurringGoalPeriod ?? self.goal?.periodInterval(for: self.goal.start!)
    }
    
    /**
     * Goal picker must be set prior to view loading with a goal to show
     * in this review controller.
     */
    var goal: Goal!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .tint
        
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: nil,
            using: dayChanged
        )
        
        self.navigationController?.navigationBar.hideBorderLine()
        pbc = PeriodBrowserController(delegate: self, view: self.view)
        
        let width = view.frame.size.width
        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        let tableHeight = view.frame.size.height - navHeight - statusBarHeight
        let tableFrame = CGRect(x: 0, y: 0, width: width, height: tableHeight)
        tableView = UITableView(frame: tableFrame, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        tableView.topAnchor.constraint(equalTo: pbc.periodBrowser.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, tappedAdd)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, {
            self.navigationController?.popViewController(animated: true)
        })

        cellCreator = TableViewCellHelper(tableView: tableView)
        goalPicker.delegate = self
        goalPicker.makeTitleView(
            view: navigationController!.view,
            item: navigationItem,
            bar: navigationController!.navigationBar,
            present: present,
            detailViewLanguage: true,
            buttonWidth: 70 // TODO: Make this a real number based on the done button width
        )
        
        entityProviders = [
            (
                provider: ReviewViewExpensesController(
                    section: 0,
                    cellCreator: cellCreator,
                    delegate: self,
                    present: self.present
                ),
                labelMessage: "Expenses",
                createMessage: "New Expense"
            ),
            (
                provider: ReviewViewAdjustmentsController(
                    section: 1,
                    cellCreator: cellCreator,
                    delegate: self,
                    present: self.present
                ),
                labelMessage: "Adjustments",
                createMessage: "New Adjustment"
            )
        ]
        self.goalChanged(newGoal: goalPicker.currentGoal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pbc.updatePeriodBrowser(goal: goal, recurringGoalPeriod: recurringGoalPeriod)
    }

    /**
     * Updates the summary view frame and displayed data to that of the passed
     * goal, or hides the summary view if the passed goal is `nil`.
     */
    func tappedAdd() {
        let addSelectorAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        var actions = [UIAlertAction]()
        for providerTuple in entityProviders {
            let title = providerTuple.createMessage
            actions.append(
                UIAlertAction(title: title, style: .default, handler: { _ in providerTuple.provider.presentCreateModal()
                })
            )
        }
        actions.append(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        addSelectorAlert.addActions(actions)
        self.present(addSelectorAlert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     * Called when the day changes.
     */
    func dayChanged(_: Notification) {
        
    }
    
    /**
     * Updates the amount, globally, for the current goal and interval,
     * updating the spend color as appropriate.
     */
    private func updateAmount() {
        let evaluationDay = CalendarDay(dateInDay: interval.end)?.subtract(days: 1) ?? CalendarDay()
        
        let balanceCalculator = GoalBalanceCalculator()
        balanceCalculator.calculateBalance(for: goal, on: evaluationDay)
        { (balance: Decimal?, _, _) in
            guard let newAmount = balance?.doubleValue else {
                return
            }
            self.appDelegate.spendIndicationColor = newAmount < 0 ? .overspent : .underspent
            
            if evaluationDay == CalendarDay() {
                // Store this balance as the most recently displayed, since we do that for today.
                GoalBalanceCache.setMostRecentlyDisplayedBalance(goal: self.goal, amount: newAmount)
            }
        }
    }
    
    /**
     * Notifies controllers controlling data in the review view that there has
     * been a change in goal or interval, and passes them the new information
     * from this class's member variables.
     */
    private func notifyControllersDataChanged() {
        pbc.updatePeriodBrowser(goal: goal, recurringGoalPeriod: recurringGoalPeriod)
        
        for providerTuple in entityProviders {
            providerTuple.provider.setGoal(goal, interval: interval)
        }
    }
    
    /**
     * Animate an interval change, forward if `forward` is true, otherwise
     * backward.
     */
    private func animateIntervalChange(forward: Bool) {
        let providersSections = IndexSet(integersIn: 0..<entityProviders.count)
        tableView.beginUpdates()
        tableView.deleteSections(providersSections, with: forward ? .left : .right)
        tableView.insertSections(providersSections, with: forward ? .right : .left)
        tableView.endUpdates()
    }
}

extension ReviewViewController: GoalPickerDelegate {
    /**
     * Called when the goal has been changed by the goal picker.
     */
    func goalChanged(newGoal: Goal?) {
        self.goal = newGoal
        recurringGoalPeriod = self.goal.mostRecentPeriod()
        notifyControllersDataChanged()
        updateAmount()
        self.tableView.reloadData()
    }
}

extension ReviewViewController: PeriodSelectorViewDelegate {
    /**
     * Called when the next button was tapped in the period browser.
     */
    func tappedNext() {
        guard let nextPeriod = recurringGoalPeriod?.nextCalendarPeriod() else {
            return
        }
        recurringGoalPeriod = nextPeriod
        notifyControllersDataChanged()
        updateAmount()
        animateIntervalChange(forward: true)
    }
    
    /**
     * Called when the previous button was tapped in the period browser.
     */
    func tappedPrevious() {
        recurringGoalPeriod = recurringGoalPeriod?.previousCalendarPeriod()
        notifyControllersDataChanged()
        updateAmount()
        animateIntervalChange(forward: false)
    }
}

extension ReviewViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return entityProviders.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return entityProviders[section].labelMessage
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entityProviders[section].provider.tableView(tableView, numberOfRowsInSection: section) 
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        return entityProviders[section].provider.tableView(tableView, cellForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        entityProviders[section].provider.tableView?(tableView, didSelectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let section = indexPath.section
        entityProviders[section].provider.tableView?(tableView, accessoryButtonTappedForRowWith: indexPath)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        return entityProviders[section].provider.tableView?(tableView, canEditRowAt: indexPath) ?? false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let section = indexPath.section
        entityProviders[section].provider.tableView?(tableView, commit: editingStyle, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        return entityProviders[section].provider.tableView?(tableView, heightForRowAt: indexPath) ?? 0
    }
}


extension ReviewViewController: ReviewEntityControllerDelegate {
    
    /**
     * Used to load a new interval and goal and switch the view so that a newly
     * added or edited entity is visible.
     */
    private func loadNewInterval(in goal: Goal, for date: CalendarDateProvider) {
        let goalChanged = self.goal != goal
        if goalChanged {
            self.goal = goal
            self.goalPicker.setGoal(newGoal: goal)
        }
        
        if let newInterval = goal.periodInterval(for: date) {
            recurringGoalPeriod = newInterval as? CalendarPeriod
            notifyControllersDataChanged()
            
            if goalChanged {
                // Since we're changing goals, don't animate like we're switching
                // intervals within a goal.
                tableView.reloadData()
            } else {
                animateIntervalChange(forward: newInterval.start.gmtDate > interval.start.gmtDate)
            }
        } else {
            Logger.warning("The added entity was not within any of this goal's periods.")
        }
    }
    
    /**
     * Returns true if an entity with the passed interval and goal would be
     * displayed in the current view based on the currently selected interval
     * and goal.
     */
    private func entityIsInCurrentView(interval: CalendarIntervalProvider, goal: Goal) -> Bool {
        return self.interval.overlaps(with: interval) && (goal == self.goal || self.goal.isParentOf(goal: goal))
    }
    
    func addedEntity(with interval: CalendarIntervalProvider, within goal: Goal, at path: IndexPath, use animation: UITableView.RowAnimation, isOnlyEntity: Bool) {
        if isOnlyEntity {
            tableView.reloadSections(IndexSet(integer: path.section), with: animation)
            return
        }
        
        if !entityIsInCurrentView(interval: interval, goal: goal) {
            loadNewInterval(in: goal, for: interval.start)
            return
        }

        tableView.insertRows(at: [path], with: animation)
        updateAmount()
    }
    
    func editedEntity(with interval: CalendarIntervalProvider, within goal: Goal, at path: IndexPath, movedTo newPath: IndexPath?, use animation: UITableView.RowAnimation) {
        if !entityIsInCurrentView(interval: interval, goal: goal) {
            loadNewInterval(in: goal, for: interval.start)
            return
        }
        
        if newPath != nil {
            tableView.moveRow(at: path, to: newPath!)
            tableView.reloadRows(at: [newPath!], with: animation)
        } else {
            tableView.reloadRows(at: [path], with: animation)
        }
        updateAmount()
    }
    
    func deletedEntity(at path: IndexPath, use animation: UITableView.RowAnimation, isOnlyEntity: Bool) {
        if isOnlyEntity {
            tableView.reloadSections(IndexSet(integer: path.section), with: animation)
            return
        }
        tableView.deleteRows(at: [path], with: animation)
        updateAmount()
    }
}

protocol ReviewEntityControllerDelegate {
    /**
     * Notifies the delegate that an entity has been added with an interval of
     * `interval`, located in the table view at `path`, and requests that the
     * delegate use `animation` to show the new cell data.
     *
     * Note that the delegate may not animate as requested.
     * Depending on the value of `interval`, `isFirst`, and `goal`, it may
     * choose to reload the view with a different set of dates or a different
     * goal.
     */
    func addedEntity(with interval: CalendarIntervalProvider, within goal: Goal, at path: IndexPath, use animation: UITableView.RowAnimation, isOnlyEntity: Bool)
    
    /**
     * Notifies the delegate that an entity has been modified with a new
     * interval of `interval`, located in the table view at `path`, and requests
     * that the delegate use `animation` to show the new cell data.
     *
     * Optionally, a `newPath` can be provided, if the entities order has
     * changed.
     *
     * Note that the delegate may not animate as requested.
     * Depending on the value of `interval` and `goal`, it may choose to reload
     * the view with a different set of dates or a different goal.
     */
    func editedEntity(with interval: CalendarIntervalProvider, within goal: Goal, at path: IndexPath, movedTo newPath: IndexPath?, use animation: UITableView.RowAnimation)
    
    /**
     * Notifies the delegate that an entity has been deleted located in the
     * table view at `path`, and requests that the delegate use `animation`
     * remove that cell.
     *
     * Depending on the value of `isLast`, the delegate may choose to reload the
     * view with a different set of dates or a different goal.
     */
    func deletedEntity(at path: IndexPath, use animation: UITableView.RowAnimation, isOnlyEntity: Bool)
}

protocol ReviewEntityDataProvider : UITableViewDataSource, UITableViewDelegate {
    /**
     * Present a modal that allows the user to create this type of entity.
     */
    func presentCreateModal()
    
    /**
     * Reload data store with entities from the given interval that are
     * associated with the given goal.
     */
    func setGoal(_ newGoal: Goal?, interval: CalendarIntervalProvider)
}
