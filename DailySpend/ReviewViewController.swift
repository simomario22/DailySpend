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
    private var period: CalendarPeriod?
    
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
        periodBrowserView.delegate = self
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
            detailViewLanguage: true,
            buttonWidth: 70 // TODO: Make this a real number based on the done button width
        )
        
        self.goalChanged(newGoal: goalPicker.currentGoal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updatePeriodBrowser()
    }
    
    /**
     * Updates period browser with information based on selected period and goal.
     */
    func updatePeriodBrowser() {
        if goal == nil {
            periodBrowserView.previousButtonEnabled = false
            periodBrowserView.nextButtonEnabled = false
            periodBrowserView.labelText = "None"
            return
        }
        let df = DateFormatter()
        df.dateFormat = "M/d/yy"
        
        // Begin by assuming start is goal start and no end (non recurring).
        var start = goal.start!.string(formatter: df)
        var end = "Today"
        periodBrowserView.previousButtonEnabled = false
        periodBrowserView.nextButtonEnabled = false
        
        if let period = period {
            // This is a recurring goal.
            periodBrowserView.previousButtonEnabled = true
            periodBrowserView.nextButtonEnabled = true
            start = period.start.string(formatter: df)
            
            // Check if we need to update the end date.
            if period.end != nil &&
               goal.exclusiveEnd != nil &&
               period.end!.gmtDate > goal.exclusiveEnd!.gmtDate {
                // Goal has an end date before the end of this period.
                end = CalendarDay(dateInDay: goal.end!).string(formatter: df)
            } else if period.end != nil {
                // Period has an end date.
                end = CalendarDay(dateInDay: period.end!).subtract(days: 1).string(formatter: df)
            }
            
            // Check for no previous period.
            if period.previousCalendarPeriod().start.gmtDate < goal.start!.gmtDate {
                periodBrowserView.previousButtonEnabled = false
            }
            
            // Check for no next period.
            let nextPeriodDate = period.nextCalendarPeriod().start.gmtDate
            if nextPeriodDate > CalendarDay().start.gmtDate ||
               (
                    goal.exclusiveEnd != nil &&
                    nextPeriodDate > goal.exclusiveEnd!.gmtDate
               ) {
                periodBrowserView.nextButtonEnabled = false
            }
        } else {
            // This is a non-recurring goal. Check if it has an end date.
            if goal.end != nil {
                end = CalendarDay(dateInDay: goal.end!).string(formatter: df)
            }
        }
        
        periodBrowserView.labelText = "\(start) - \(end)"
    }
    
    /**
     * Called when the next button was tapped in the period browser.
     */
    func tappedNext() {
        period = period?.nextCalendarPeriod()
        updatePeriodBrowser()
    }
    
    /**
     * Called when the previous button was tapped in the period browser.
     */
    func tappedPrevious() {
        period = period?.previousCalendarPeriod()
        updatePeriodBrowser()
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
        self.goal = newGoal
        if goal != nil && goal.isRecurring {
            // Try to get an interval for the current day.
            var interval = goal.periodInterval(for: CalendarDay().start)
            if interval == nil && goal.end != nil {
                // Try to get an interval for last period of the goal.
                interval = goal.periodInterval(for: goal.end!)
            }

            if interval != nil {
                // Turn it into a calendar period.
                // Note that if there's an end date in this period, it may
                // not be the true interval of this period, but CalendarPeriod
                // has convenient member functions.
                period = CalendarPeriod(
                    calendarDate: interval!.start,
                    period: goal.period,
                    beginningDateOfPeriod: interval!.start
                )
            } else {
                // Can't get an interval (likely due to the goal having a start
                // date after today, or the goal not having a start date)
                period = nil
                goal = nil
            }
        } else {
            period = nil
        }
        updatePeriodBrowser()
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
