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
    
    private var expensesController: ReviewViewExpensesController!

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
    var goalPicker: NavigationGoalPicker!
    
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
        
        expensesController = ReviewViewExpensesController(section: 0, cellCreator: cellCreator)

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
        
    }

    /**
     * Returns a unique string associated with a particular goal.
     */
    func keyForGoal(goal: Goal) -> String {
        let id = goal.objectID.uriRepresentation()
        return "mostRecentComputedAmount_\(id)"
    }
    
    /**
     * Retrieves the amount most recently displayed to the user in the summary
     * view, persisting across app termination.
     */
    func mostRecentlyUsedAmountForGoal(goal: Goal) -> Double {
        return UserDefaults.standard.double(forKey: keyForGoal(goal: goal))
    }
    
    /**
     * Set the amount most recently displayed to the user in the summary
     * view, persisting across app termination.
     */
    func setMostRecentlyUsedAmountForGoal(goal: Goal, amount: Double) {
        UserDefaults.standard.set(amount, forKey: keyForGoal(goal: goal))
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     * Notifies entity controllers that there has been a change in goal or
     * interval, and passes them this class's new information.
     */
    func notifyEntityControllers() {
        self.expensesController.setGoal(goal, interval: interval)
    }
    
    /*
     * Called when the day changes.
     */
    func dayChanged(_: Notification) {
        
    }
}

extension ReviewViewController: GoalPickerDelegate {
    /**
     * Called when the goal has been changed by the goal picker.
     */
    func goalChanged(newGoal: Goal?) {
        self.goal = newGoal
        recurringGoalPeriod = self.goal.mostRecentPeriod()
        pbc.updatePeriodBrowser(goal: self.goal, recurringGoalPeriod: recurringGoalPeriod)

        notifyEntityControllers()
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
        pbc.updatePeriodBrowser(goal: goal, recurringGoalPeriod: recurringGoalPeriod)
        notifyEntityControllers()
        
        tableView.beginUpdates()
        self.tableView.deleteSections(IndexSet(arrayLiteral: 0), with: .left)
        self.tableView.insertSections(IndexSet(arrayLiteral: 0), with: .right)
        tableView.endUpdates()
    }
    
    /**
     * Called when the previous button was tapped in the period browser.
     */
    func tappedPrevious() {
        recurringGoalPeriod = recurringGoalPeriod?.previousCalendarPeriod()
        pbc.updatePeriodBrowser(goal: goal, recurringGoalPeriod: recurringGoalPeriod)
        notifyEntityControllers()
        
        tableView.beginUpdates()
        self.tableView.deleteSections(IndexSet(arrayLiteral: 0), with: .right)
        self.tableView.insertSections(IndexSet(arrayLiteral: 0), with: .left)
        tableView.endUpdates()

    }
}

extension ReviewViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Expenses"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return expensesController.tableView(tableView, numberOfRowsInSection: section)
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return expensesController.tableView(tableView, cellForRowAt: indexPath)
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            expensesController.tableView(tableView, didSelectRowAt: indexPath)
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            expensesController.tableView(tableView, accessoryButtonTappedForRowWith: indexPath)
        default:
            return
        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
