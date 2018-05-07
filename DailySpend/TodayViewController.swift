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
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (_) in
            if self.appDelegate.spendIndicationColor == .underspent {
                self.appDelegate.spendIndicationColor = .overspent
            } else {
                self.appDelegate.spendIndicationColor = .underspent
            }
            
        })
        
        let width = view.frame.size.width
        let summaryFrame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 120)
        summaryView = TodaySummaryView(frame: summaryFrame)
        summaryView.setAmount(value: 105)
        
        
        
        let tableHeight = view.frame.size.height - summaryFrame.bottomEdge
        let tableFrame = CGRect(x: 0, y: summaryFrame.bottomEdge, width: width, height: tableHeight)
        tableView = UITableView(frame: tableFrame, style: .grouped)
        
        self.view.addSubviews([summaryView, tableView])
        
        let todayPeriod = CalendarPeriod(
            dateInGMTPeriod: CalendarDay().gmtDate,
            period: Period(scope: .Day, multiplier: 1)
        )!
        expensesController = TodayViewExpensesController(
            tableView: tableView,
            period: todayPeriod
        )
        tableView.delegate = expensesController
        tableView.dataSource = expensesController
        
        let goalsController = TodayViewGoalsController(
            view: navigationController!.view,
            navigationItem: navigationItem,
            navigationBar: navigationController!.navigationBar,
            delegate: self,
            present: self.present
        )
        goalsController.setup()
        
        cellCreator = TableViewCellHelper(tableView: tableView, view: view)
        Logger.printAllCoreData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    enum TodayViewCellType {
        case TodayCell
        case ExpenseCell
    }
    
    func cellTypeForIndexPath(indexPath: IndexPath) -> TodayViewCellType {
//        let section = indexPath.section
        
        return .ExpenseCell
        
//        if section == 0 {
//            return .TodayCell
//        }
//
//        return .ExpenseCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .TodayCell:
            return UITableViewCell()
        case .ExpenseCell:
            return cellCreator.expenseCell(expense: Expense(), day: CalendarDay(), addedExpense: {
                (shortDescription: String, amount: Decimal) in
                print("added expense with \(shortDescription), \(amount)")
            }, selectedDetailDisclosure: {
                print("selected detail disclosure")
            }, beganEditing: { (i: Int) in
                print("began editing")
            }, endedEditing: { (i: Int) in
                print("ended editing")
            })
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenses.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
