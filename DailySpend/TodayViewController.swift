//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/6/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController : UITableViewController, AddExpenseTableViewCellDelegate, TableViewCellDelegate {
    let standardCellHeight: CGFloat = 44
    let currentDayHeight: CGFloat = 115
    let addExpenseHeight: CGFloat = 213
    let addExpenseMinPxVisible: CGFloat = 70
    let heightOfTodaysSpendingLabel: CGFloat = 21

    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var daysThisMonth: [Day] = []
    var months: [Month] = []
    var addingExpense = false
    
    // Required for unwind segue
    @IBAction override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}

    /*
     * Present the review dialog for a given month.
     */
    func reviewMonth(_ month: Month, completion: (() -> Void)?) {
        let storyboard = UIStoryboard(name: "FuckXcode", bundle: nil)
        let navController = storyboard.instantiateViewController(withIdentifier: "ReviewMonth") as! UINavigationController
        let viewController = navController.visibleViewController as! ReviewMonthViewController
        
        
        viewController.setAndFormatLabels(spentAmount: month.actualSpend,
                                          goalAmount: month.fullTargetSpend,
                                          underOverAmount: month.fullTargetSpend - month.actualSpend,
                                          dayInMonth: month.month!)
        
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .coverVertical
        self.present(navController, animated: true, completion: completion)
    }
    
    /*
     * Creates consecutive days in data store inclusive of beginning date and
     * exclusive of ending date
     * The from date is required to have a date in a Month that is already 
     * created.
     */
    func createDays(from: Date, to: Date) {
        var currentDate = from
        while (currentDate.beginningOfDay != to.beginningOfDay) {
            if let month = Month.get(context: context, dateInMonth: currentDate) {
                // Create the day
                Day.create(context: context, date: currentDate, month: month)
                currentDate = currentDate.add(days: 1)
            } else {
                // This month doesn't yet exist.
                // Create and review the previous month, then call this function again.
                _ = Month.create(context: context, dateInMonth: currentDate)
                reviewMonth(Month.get(context:context,
                                      dateInMonth: currentDate.subtract(months: 1))!,
                                      completion: {
                    self.createDays(from: currentDate, to: to)
                })
            }
        }
    }
    
    /*
     * Calculates the number of on-screen spots for expenses (including "see
     * additional" spots) while keeping addExpenseMinPxVisible pixels visible in
     * the addExpense cell
     */
    func numExpenseSpots() -> Int {
        let topHeight = UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.frame.height
        let windowFrameHeight = tableView.frame.height
        let visibleHeight = windowFrameHeight - topHeight;

        let maxExpenses = Int((visibleHeight - currentDayHeight - addExpenseMinPxVisible)
            .truncatingRemainder(dividingBy: standardCellHeight))
        let totalExpenses = daysThisMonth.count > 0 ? daysThisMonth.last!.expenses!.count : 0
        return min(totalExpenses, maxExpenses)
    }
    
    func fetchMonthsAndDays() {
        // Populate daysThisMonth and months
        let today = Date()
        
        // Fetch all days this month
        let daysThisMonthFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let daysThisMonthSortDesc = NSSortDescriptor(key: "date_", ascending: true)
        daysThisMonthFetchReq.sortDescriptors?.append(daysThisMonthSortDesc)
        daysThisMonthFetchReq.predicate = NSPredicate(format: "month_.month_ == %@", Date.firstDayOfMonth(dayInMonth: today) as CVarArg)
        daysThisMonth = try! context.fetch(daysThisMonthFetchReq)
        
        // Fetch all previous months
        let monthsFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
        let monthSortDesc = NSSortDescriptor(key: "month_", ascending: true)
        monthsFetchReq.sortDescriptors?.append(monthSortDesc)
        monthsFetchReq.predicate = NSPredicate(format: "month_ != %@", Date.firstDayOfMonth(dayInMonth: today) as CVarArg)
        months = try! context.fetch(monthsFetchReq)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Spending"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UserDefaults.standard.double(forKey: "dailyTargetSpend") == 0 {

            let storyboard = UIStoryboard(name: "FuckXcode", bundle: nil)
            let navController = storyboard.instantiateViewController(withIdentifier: "InitialSpend")
            
            navController.modalPresentationStyle = .fullScreen
            navController.modalTransitionStyle = .coverVertical
            self.present(navController, animated: true, completion: nil)
            return
        }

        
        // Create days up to today.
        let latestDayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let latestDaySortDesc = NSSortDescriptor(key: "date_", ascending: false)
        latestDayFetchReq.sortDescriptors?.append(latestDaySortDesc)
        latestDayFetchReq.fetchLimit = 1
        let latestDayResults = try! context.fetch(latestDayFetchReq)
        
        if (latestDayResults.count < 1) {
            // To satisfy requirement of createDays, create month for today
            _ = Month.create(context: context, dateInMonth: Date())
        }
        
        // Start from one after the latest created date (or today) and go to
        // today
        let from = latestDayResults.count < 1 ? Date() : latestDayResults[0].date!.add(days: 1)
        let to = Date().add(days: 1)
        createDays(from: from, to: to)

        fetchMonthsAndDays()
        
        self.tableView.reloadData()
        
        let locationOfTodayCell = months.count + daysThisMonth.count - 1
        self.tableView.scrollToRow(at: IndexPath(row: locationOfTodayCell, section: 0),
                                   at: .top, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return months.count + daysThisMonth.count + numExpenseSpots() + 1
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let lastPrevDayCell = months.count + daysThisMonth.count - 2
        let currentDayCell = lastPrevDayCell + 1
        let lastExpenseCell = currentDayCell + numExpenseSpots()
        
        if indexPath.row <= lastPrevDayCell {
            return tableView.dequeueReusableCell(withIdentifier: "previousDay", for: indexPath)
        } else if indexPath.row <= currentDayCell {
            let currentDay = tableView.dequeueReusableCell(withIdentifier: "currentDay", for: indexPath) as! CurrentDayTableViewCell
            if let today = daysThisMonth.last {
                let dailyLeft = today.fullTargetSpend - today.actualSpend
                let monthlyLeft = today.month!.fullTargetSpend - today.month!.actualSpend
                
                currentDay.setAndFormatLabels(dailySpendLeft: dailyLeft,
                                              monthlySpendLeft: monthlyLeft,
                                              expensesToday: today.expenses!.count > 0)
            }
            return currentDay
        } else if indexPath.row <= lastExpenseCell {
            return tableView.dequeueReusableCell(withIdentifier: "expense", for: indexPath)
        } else {
//            let addExpense = tableView.dequeueReusableCell(withIdentifier: "addExpense", for: indexPath) as! AddExpenseTableViewCell
//            addExpense.delegate = self
//            return addExpense
            let cell = tableView.dequeueReusableCell(withIdentifier: "asdf", for: indexPath) as! TableViewCell
            cell.delegate = self
            cell.rowPosition = indexPath.row
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let lastPrevDayCell = months.count + daysThisMonth.count - 2
        let currentDayCell = lastPrevDayCell + 1
        let lastExpenseCell = currentDayCell + numExpenseSpots()
        if indexPath.row <= lastPrevDayCell {
            return standardCellHeight
        } else if indexPath.row <= currentDayCell {
            if daysThisMonth.last == nil || daysThisMonth.last!.expenses!.count == 0 {
                return currentDayHeight - heightOfTodaysSpendingLabel
            } else {
                return currentDayHeight
            }
        } else if indexPath.row <= lastExpenseCell {
            return standardCellHeight
        } else {
//            if addingExpense {
//                let topHeight = UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.frame.height
//                let windowFrameHeight = tableView.frame.height
//                let visibleHeight = windowFrameHeight - topHeight;
//                print("visibleHeight:\(visibleHeight)")
//                return visibleHeight
//            } else {
//                return addExpenseHeight
//            }
            if addingExpense {
                return self.view.bounds.height
            } else {
                return 213
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    func didBeginEditing(sender: AddExpenseTableViewCell) {
        print("didBeginEditing")
        addingExpense = true
        
        self.tableView.isScrollEnabled = false

        self.tableView.beginUpdates()
        self.tableView.endUpdates()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(rightBarButtonPressed(sender:)))
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        
        let locationOfExpenseCell = months.count + daysThisMonth.count + numExpenseSpots()
        print("locationOfExpenseCell:\(locationOfExpenseCell)")
        
        self.tableView.scrollToRow(at: IndexPath(row: locationOfExpenseCell, section: 0),
                                   at: .top, animated: true)
    }
    
    func rightBarButtonPressed(sender: UIBarButtonItem) {
        let buttonTitle = sender.title!
        NotificationCenter.default.post(name: NSNotification.Name.init("Pressed\(buttonTitle)Button"), object: UIApplication.shared)
        if buttonTitle == "Done" {
            sender.title! = "Save"
        }
    }
    
    func didOpenNotes(sender: AddExpenseTableViewCell) {
        self.navigationItem.rightBarButtonItem?.title = "Done"
    }
    
    func completedExpense(sender: AddExpenseTableViewCell, expense: Expense) {
        print("completedExpense")
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem = nil
        addingExpense = false
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        fetchMonthsAndDays()
        self.tableView.reloadData()
        
        let locationOfTodayCell = months.count + daysThisMonth.count - 1
        self.tableView.scrollToRow(at: IndexPath(row: locationOfTodayCell, section: 0),
                                   at: .top, animated: true)
    }
    
    func invalidFields(sender: AddExpenseTableViewCell) {
        let alert = UIAlertController(title: "Invalid Fields", message: "Please enter valid values for amount, description, and date.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func didBeginEditingg(sender: TableViewCell) {
        print("didbeginediting!")
        addingExpense = true
        tableView.beginUpdates()
        tableView.endUpdates()
        tableView.scrollToRow(at: IndexPath(row: 1, section: 0), at: .top, animated: false)
    }
}
