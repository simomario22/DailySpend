//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/12/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController: UIViewController, TodayViewGoalsDelegate, TodayViewExpensesDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    var summaryViewHidden: Bool = true
    var summaryView: TodaySummaryView!
    var neutralBarColor: UIColor!
    var tableView: UITableView!
    var expensesController: TodayViewExpensesController!
    var cellCreator: TableViewCellHelper!
    var period: CalendarPeriod!
    var goal: Goal!
    
    let summaryViewHeightWithHint: CGFloat = 120
    let summaryViewHeightWithoutHint: CGFloat = 97
    
    var expenses = [(desc: String, amount: String)]()
        
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
        let summaryFrame = CGRect(
            x: 0,
            y: -summaryViewHeightWithHint,
            width: width,
            height: summaryViewHeightWithHint
        )
        summaryView = TodaySummaryView(frame: summaryFrame)
        
        // The border line hangs below the summary frame, so we'll use that one
        // so it slides out nicely.
        self.navigationController?.navigationBar.hideBorderLine()

        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        let tableHeight = view.frame.size.height - navHeight - statusBarHeight
        let tableFrame = CGRect(x: 0, y: 0, width: width, height: tableHeight)

        tableView = UITableView(frame: tableFrame, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubviews([tableView, summaryView])
        
        tableView.topAnchor.constraint(equalTo: summaryView.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        expensesController = TodayViewExpensesController(
            tableView: tableView,
            present: self.present
        )
        expensesController.delegate = self
        
        tableView.delegate = expensesController
        tableView.dataSource = expensesController
        
        _ = TodayViewGoalsController(
            view: navigationController!.view,
            navigationItem: navigationItem,
            navigationBar: navigationController!.navigationBar,
            delegate: self,
            present: self.present
        )
        
        Logger.printAllCoreData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateSummaryViewForGoal(goal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func goalChanged(newGoal: Goal?) {
        self.goal = newGoal
        expensesController.loadExpensesForGoal(newGoal)
        updateSummaryViewForGoal(newGoal)
    }
    
    func expensesChanged(goal: Goal) {
        updateSummaryViewForGoal(goal)
    }
    
    @objc func dayChanged() {
        
    }
    
    func updateSummaryViewForGoal(_ goal: Goal?) {
        guard let goal = goal else {
            animateSummaryViewFrameIfNecessary(show: false)
            summaryViewHidden = true
            return
        }
        
        animateSummaryViewFrameIfNecessary(show: true)
        summaryViewHidden = false
        
        // Update summary view with information from this goal for the
        // appropriate period.
        let newAmount = goal.balance(for: CalendarDay()).doubleValue
        let oldAmount = mostRecentlyUsedAmountForGoal(goal: goal)
        if oldAmount != newAmount {
            summaryView.countFrom(CGFloat(oldAmount), to: CGFloat(newAmount))
        } else {
            summaryView.setAmount(value: CGFloat(newAmount))
        }
        setMostRecentlyUsedAmountForGoal(goal: goal, amount: newAmount)
        
        var endDay: CalendarDay?
        if goal.isRecurring {
            guard let currentGoalPeriod = goal.periodInterval(for: CalendarDay().start) else {
                return
            }
            endDay = CalendarDay(dateInDay: currentGoalPeriod.end!).subtract(days: 1)
        } else if goal.end != nil {
            endDay = CalendarDay(dateInDay: goal.end!).subtract(days: 1)
        }
    
        if let endDay = endDay {
            let dateFormatter = DateFormatter()
            if endDay.year == CalendarDay().year {
                dateFormatter.dateFormat = "M/d"
            } else {
                dateFormatter.dateFormat = "M/d/yy"
            }
            let formattedDate = endDay.string(formatter: dateFormatter)
            summaryView.setHint("Period End: \(formattedDate)")
            animateSummaryViewHeightIfNecessary(height: summaryViewHeightWithHint)
        } else {
            summaryView.setHint("")
            animateSummaryViewHeightIfNecessary(height: summaryViewHeightWithoutHint)
        }
    }
    
    /**
     * Animates sliding the summary view in or out based on the value of `show`.
     *
     * If the summary view is already believed to be in the correct state based
     * on the value of `summaryViewHidden`, it will not be animated.
     */
    func animateSummaryViewFrameIfNecessary(show: Bool) {
        let offsetYMultiplier: CGFloat = show ? 1 : -1
        let hiddenValueIndicatingSummaryViewPositionIsCorrect = show ? false : true
        if summaryViewHidden != hiddenValueIndicatingSummaryViewPositionIsCorrect {
            // Need to call layoutIfNeeded outside the animation block and
            // before changing the summary view frame, otherwise we could end
            // up animating subviews we don't mean to that haven't been
            // placed yet.
            self.view.layoutIfNeeded()
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.summaryView.frame = self.summaryView.frame.offsetBy(
                        dx: 0,
                        dy: self.summaryView.frame.height * offsetYMultiplier
                    )
                    self.view.layoutIfNeeded()
                }
            )
        }
    }
    
    /**
     * Animates changing the summary view to a certain height, if it isn't
     * already set to that height.
     */
    func animateSummaryViewHeightIfNecessary(height: CGFloat) {
        if summaryView.frame.size.height != height {
            self.view.layoutIfNeeded()
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    var frame = self.summaryView.frame
                    frame.size.height = height
                    self.summaryView.frame = frame
                    self.view.layoutIfNeeded()
                }
            )
        }
    }
    
    func keyForGoal(goal: Goal) -> String {
        let id = goal.objectID.uriRepresentation()
        return "mostRecentComputedAmount_\(id)"
    }
    
    func mostRecentlyUsedAmountForGoal(goal: Goal) -> Double {
        return UserDefaults.standard.double(forKey: keyForGoal(goal: goal))
    }
    
    func setMostRecentlyUsedAmountForGoal(goal: Goal, amount: Double) {
        UserDefaults.standard.set(amount, forKey: keyForGoal(goal: goal))
    }
    
    @objc func updateBarTintColor() {
        let newColor = self.appDelegate.spendIndicationColor
        if self.summaryView.backgroundColor != newColor {
            UIView.animate(withDuration: 0.2) {
                self.summaryView.backgroundColor = newColor
            }
        }
    }
}
