//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/12/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController: UIViewController,
UITableViewDataSource,
UITableViewDelegate,
TodayViewControllerDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    @IBOutlet weak var tableView: UITableView!
    var cellCreator: TableViewCellHelper!
    var goalsController: TodayViewGoalsController!
    
    var expenses = [(desc: String, amount: String)]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        goalsController = TodayViewGoalsController(
            view: navigationController!.view,
            navigationItem: navigationItem,
            navigationBar: navigationController!.navigationBar,
            delegate: self,
            present: self.present
        )
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
        print("Goal changed to \(String(describing: newGoal?.shortDescription))!")
    }

}

protocol TodayViewControllerDelegate {
    func goalChanged(newGoal: Goal?)
}
