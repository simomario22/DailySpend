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

    var summaryViewHidden: Bool = false
    var summaryView: TodaySummaryView!
    var neutralBarColor: UIColor!
    var tableView: UITableView!
    var expensesController: TodayViewExpensesController!
    var cellCreator: TableViewCellHelper!
    var period: CalendarPeriod!
    
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
        
        
        let width = view.frame.size.width
        let summaryFrame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 120)
        summaryView = TodaySummaryView(frame: summaryFrame)
        
        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        let tableHeight = view.frame.size.height - summaryFrame.bottomEdge - navHeight - statusBarHeight
        let tableFrame = CGRect(x: 0, y: summaryFrame.bottomEdge, width: width, height: tableHeight)
        tableView = UITableView(frame: tableFrame, style: .grouped)
        
        self.view.addSubviews([summaryView, tableView])
        navigationController?.navigationBar.hideBorderLine()
        
        expensesController = TodayViewExpensesController(
            tableView: tableView,
            present: self.present
        )
        expensesController.delegate = self
        
        tableView.delegate = expensesController
        tableView.dataSource = expensesController
        
        let goalController = TodayViewGoalsController(
            view: navigationController!.view,
            navigationItem: navigationItem,
            navigationBar: navigationController!.navigationBar,
            delegate: self,
            present: self.present
        )
        
        if goalController.getLastUsedGoal() == nil {
            summaryView.frame = summaryView.frame.offsetBy(dx: 0, dy: -summaryView.frame.height)
            summaryViewHidden = true
        }
        
        Logger.printAllCoreData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func goalChanged(newGoal: Goal?) {
        expensesController.loadExpensesForGoal(newGoal)
        updateSummaryViewForGoal(goal: newGoal)
    }
    
    func expensesChanged(goal: Goal) {
        updateSummaryViewForGoal(goal: goal)
    }
    
    func updateSummaryViewForGoal(goal: Goal?) {
        guard let goal = goal else {
            clearSummaryView()
            return
        }
        
        if summaryViewHidden {
            UIView.beginAnimations("TodayViewController.showSummaryView", context: nil)
            summaryView.frame = summaryView.frame.offsetBy(dx: 0, dy: summaryView.frame.height)
            summaryViewHidden = false
            UIView.commitAnimations()
        }
        
        let newAmount = goal.balance(for: CalendarDay()).doubleValue
        let oldAmount = mostRecentlyUsedAmountForGoal(goal: goal)
        if oldAmount != newAmount {
            summaryView.countFrom(CGFloat(oldAmount), to: CGFloat(newAmount))
        } else {
            summaryView.setAmount(value: CGFloat(newAmount))
        }
        setMostRecentlyUsedAmountForGoal(goal: goal, amount: newAmount)
        
        var day: CalendarDay?
        if goal.isRecurring {
            guard let currentGoalPeriod = goal.periodInterval(for: CalendarDay().start) else {
                return
            }
            day = CalendarDay(dateInDay: currentGoalPeriod.end!).subtract(days: 1)
        } else if goal.end != nil {
            day = CalendarDay(dateInDay: goal.end!).subtract(days: 1)
        }
    
        // TODO: Make summary view smaller if there's no hint.
        if let day = day {
            let dateFormatter = DateFormatter()
            if day.year == CalendarDay().year {
                dateFormatter.dateFormat = "M/d"
            } else {
                dateFormatter.dateFormat = "M/d/yy"
            }
            let formattedDate = day.string(formatter: dateFormatter)
            summaryView.setHint("Period End: \(formattedDate)")
        } else {
            summaryView.setHint("")
        }

    }
    
    func clearSummaryView() {
        if !summaryViewHidden {
            UIView.beginAnimations("TodayViewController.showSummaryView", context: nil)
            summaryView.frame = summaryView.frame.offsetBy(dx: 0, dy: -summaryView.frame.height)
            summaryView.backgroundColor = neutralBarColor
            summaryViewHidden = true
            UIView.commitAnimations()
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
