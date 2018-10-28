//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/12/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class ReviewViewController: UIViewController, UINavigationControllerDelegate, PeriodSelectorViewDelegate, GoalPickerDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    private var periodBrowserView: PeriodBrowserView!
    private var neutralBarColor: UIColor!
    private var tableView: UITableView!
    private var cellCreator: TableViewCellHelper!
    private var period: CalendarPeriod!
    
    /**
     * Goal picker must be set prior to view loading with a
     * NavigationGoalPicker associated with this controller's navigation
     * controller.
     */
    var goalPicker: NavigationGoalPicker!
    
    /**
     * Goal picker must be set prior to view loading with a goal to show
     * in this review controller.
     */
    var goal: Goal!
    
    let periodBrowserViewHeight: CGFloat = 40

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .tint
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBarTintColor),
            name: NSNotification.Name.init("ChangedSpendIndicationColor"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: NSNotification.Name.NSCalendarDayChanged,
            object: nil
        )

        let width = view.frame.size.width
        let periodBrowserFrame = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: periodBrowserViewHeight
        )
        periodBrowserView = PeriodBrowserView(frame: periodBrowserFrame)
        periodBrowserView.backgroundColor = appDelegate.spendIndicationColor
        self.navigationController?.navigationBar.hideBorderLine()

        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        let tableHeight = view.frame.size.height - navHeight - statusBarHeight
        let tableFrame = CGRect(x: 0, y: 0, width: width, height: tableHeight)

        tableView = UITableView(frame: tableFrame, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubviews([tableView, periodBrowserView])
        
        tableView.topAnchor.constraint(equalTo: periodBrowserView.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, tappedAdd)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, {
            self.navigationController?.popViewController(animated: true)
        })

        goalPicker.delegate = self
        goalPicker.makeTitleView(
            view: navigationController!.view,
            item: navigationItem,
            bar: navigationController!.navigationBar,
            present: present,
            detailViewLanguage: true
        )
        self.goalChanged(newGoal: goalPicker.currentGoal)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateSummaryCell()
    }
    
    /**
     * Updates the summary view frame and displayed data to that of the passed
     * goal, or hides the summary view if the passed goal is `nil`.
     */
    func updateSummaryCell() {
        
    }
    
    /**
     * Called when the next button was tapped in the period browser.
     */
    func tappedNext() {
    
    }
    
    /**
     * Called when the previous button was tapped in the period browser.
     */
    func tappedPrevious() {
        
    }
    
    /**
     * Updates the summary view frame and displayed data to that of the passed
     * goal, or hides the summary view if the passed goal is `nil`.
     */
    func tappedAdd() {
        
    }
    
    /**
     * Called when the goal has been changed by the goal picker.
     */
    func goalChanged(newGoal: Goal?) {
        
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
    
    /*
     * Called when the day changes.
     */
    @objc func dayChanged() {
        
    }

    /**
     * Updates the tint color of the navigation bar to the color specified
     * by the app delegate.
     */
    @objc func updateBarTintColor() {
        let newColor = self.appDelegate.spendIndicationColor
        if self.periodBrowserView.backgroundColor != newColor {
            UIView.animate(withDuration: 0.2) {
                self.periodBrowserView.backgroundColor = newColor
            }
        }
    }
}
