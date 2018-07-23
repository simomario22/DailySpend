//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/12/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController: UIViewController, TodayViewControllerDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    var summaryView: TodaySummaryView!
    var tableView: UITableView!
    var expensesController: TodayViewExpensesController!
    var cellCreator: TableViewCellHelper!
    var period: CalendarPeriod!
    
    var expenses = [(desc: String, amount: String)]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .tint
        
        navigationController?.navigationBar.hideBorderLine()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBarTintColor),
            name: NSNotification.Name.init("ChangedSpendIndicationColor"),
            object: nil
        )
        
        let width = view.frame.size.width
        let summaryFrame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 120)
        summaryView = TodaySummaryView(frame: summaryFrame)
        summaryView.setAmount(value: 105)
        
        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        let tableHeight = view.frame.size.height - summaryFrame.bottomEdge - navHeight - statusBarHeight
        let tableFrame = CGRect(x: 0, y: summaryFrame.bottomEdge, width: width, height: tableHeight)
        tableView = UITableView(frame: tableFrame, style: .grouped)
        
        self.view.addSubviews([summaryView, tableView])
        
        expensesController = TodayViewExpensesController(
            tableView: tableView,
            present: self.present
        )
        tableView.delegate = expensesController
        tableView.dataSource = expensesController
        
        let _ = TodayViewGoalsController(
            view: navigationController!.view,
            navigationItem: navigationItem,
            navigationBar: navigationController!.navigationBar,
            delegate: self,
            present: self.present
        )
        
        Logger.printAllCoreData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func goalChanged(newGoal: Goal?) {
        expensesController.loadExpensesForGoal(newGoal)
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

protocol TodayViewControllerDelegate {
    func goalChanged(newGoal: Goal?)
}
