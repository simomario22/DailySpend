//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/6/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController : UIViewController,
AddExpenseTableViewCellDelegate, UITableViewDataSource, UITableViewDelegate {
    let standardCellHeight: CGFloat = 44
    let addExpenseMinPxVisible: CGFloat = 70
    var currentDayHeight: CGFloat {
        let baseHeight: CGFloat = 130
        let heightOfTodaysSpendingLabel: CGFloat = 21
        if daysThisMonth.last == nil ||
            daysThisMonth.last!.expenses!.count == 0 {
            return baseHeight - heightOfTodaysSpendingLabel
        } else {
            return baseHeight
        }
        
    }
    var addExpenseHeight: CGFloat {
        let baseHeight: CGFloat = 213
        if addingExpense {
            return visibleHeight
        } else {
            return baseHeight
        }
    }

    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    let redColor = UIColor(colorLiteralRed: 179.0/255.0,
                           green: 0.0/255.0,
                           blue: 0.0/255.0,
                           alpha: 1)
    let greenColor = UIColor(colorLiteralRed: 0.0/255.0,
                             green: 179.0/255.0,
                             blue: 0.0/255.0,
                             alpha: 1)
    
    var daysThisMonth: [Day] = []
    var months: [Month] = []
    var addingExpense = false
    var previousDailySpendLeft: Decimal = 0
    var adjustBarButton: UIBarButtonItem?
    var settingsBarButton: UIBarButtonItem?
    
    @IBOutlet weak var tableView: UITableView!
    // Required for unwind segue
    @IBAction override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    

    func willEnterForeground() {
        let latestDayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let latestDaySortDesc = NSSortDescriptor(key: "date_", ascending: false)
        latestDayFetchReq.sortDescriptors = [latestDaySortDesc]
        latestDayFetchReq.fetchLimit = 1
        let latestDayResults = try! context.fetch(latestDayFetchReq)
        if latestDayResults.count > 0 &&
            latestDayResults[0].date!.beginningOfDay < Date().beginningOfDay{
            // The day has changed since we last opened the app.
            // Refresh.
            if addingExpense {
                cancelAddingExpense(sender: self.navigationItem.leftBarButtonItem!)
            }
            viewWillAppear(false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.double(forKey: "dailyTargetSpend") == 0 {
            
            let sb = storyboard!
            let id = "InitialSpend"
            let navController = sb.instantiateViewController(withIdentifier: id)
            
            navController.modalPresentationStyle = .fullScreen
            navController.modalTransitionStyle = .coverVertical
            self.present(navController, animated: true, completion: nil)
            return
        }
        
        // Create days up to today.
        let latestDayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let latestDaySortDesc = NSSortDescriptor(key: "date_", ascending: false)
        latestDayFetchReq.sortDescriptors = [latestDaySortDesc]
        latestDayFetchReq.fetchLimit = 1
        let latestDayResults = try! context.fetch(latestDayFetchReq)
        
        if (latestDayResults.count < 1) {
            // To satisfy requirement of createDays, create month for today
            _ = Month.create(context: context, dateInMonth: Date())
            appDelegate.saveContext()
        }

        
        // Start from one after the latest created date (or today) and go to
        // today
        let from = latestDayResults.count < 1 ?
                    Date() : latestDayResults[0].date!.add(days: 1)
        let to = Date().add(days: 1)
        Day.createDays(context: context, from: from, to: to)
        appDelegate.saveContext()
        
        fetchMonthsAndDays()
        
        let bundleID = Bundle.main.bundleIdentifier
        if bundleID == "com.joshsherick.DailySpendTesting" {
            // Print all core data if testing.
            printAllCoreData()
        }
        
        self.tableView.reloadData()
        

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Spending"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(willEnterForeground),
                       name: NSNotification.Name.UIApplicationWillEnterForeground,
                       object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0001) {
            let currentDayPath = IndexPath(row: self.currentDayCellIndex, section: 0)
            self.tableView.scrollToRow(at: currentDayPath,
                                       at: .top, animated: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* Methods for managment of CoreData */

    func fetchMonthsAndDays() {
        // Populate daysThisMonth and months
        let today = Date()
        
        // Fetch all days this month
        let daysThisMonthFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let daysThisMonthSortDesc = NSSortDescriptor(key: "date_", ascending: true)
        daysThisMonthFetchReq.sortDescriptors = [daysThisMonthSortDesc]
        let daysPred = NSPredicate(format: "month_.month_ == %@",
                                  Date.firstDayOfMonth(dayInMonth: today) as CVarArg)
        daysThisMonthFetchReq.predicate = daysPred
        daysThisMonth = try! context.fetch(daysThisMonthFetchReq)
        
        // Fetch all previous months
        let monthsFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
        let monthSortDesc = NSSortDescriptor(key: "month_", ascending: true)
        monthsFetchReq.sortDescriptors = [monthSortDesc]
        let monthsPred = NSPredicate(format: "month_ != %@",
                                     Date.firstDayOfMonth(dayInMonth: today) as CVarArg)
        monthsFetchReq.predicate = monthsPred
        months = try! context.fetch(monthsFetchReq)
    }

    /*
     * Calculates the number of on-screen spots for expenses (including "see
     * additional" spots) while keeping addExpenseMinPxVisible pixels visible in
     * the addExpense cell
     */
    var maxExpenseSpots: Int {
        // Let's do something simple like integer division. Oh, what a joy.
        let spaceForExpenses = visibleHeight - currentDayHeight - addExpenseMinPxVisible
        return Int(floor(Double(spaceForExpenses) / Double(standardCellHeight)))
    }
    
    /*
     * Calculates the number of on-screen spots taking into account the actual
     * number of expenses.
     */
    var numExpenseSpots: Int {
        let totalExpenses = daysThisMonth.last == nil ?
                            0 : daysThisMonth.last!.expenses!.count
        return min(totalExpenses, maxExpenseSpots)
    }
    
    var lastPrevDayCellIndex: Int {
        return months.count + daysThisMonth.count - 2
    }
    
    var currentDayCellIndex: Int {
        return lastPrevDayCellIndex + 1
    }
    
    var lastExpenseCellIndex: Int {
        return currentDayCellIndex + numExpenseSpots
    }
    
    var addExpenseCellIndex: Int {
        return lastExpenseCellIndex + 1
    }
    
    var blankCellIndex: Int {
        return addExpenseCellIndex + 1
    }
    
    var heightUsed: CGFloat {
        let expensesHeight = CGFloat(numExpenseSpots) * standardCellHeight
        return currentDayHeight + expensesHeight + addExpenseHeight
    }
    
    var visibleHeight: CGFloat {
        let topHeight = UIApplication.shared.statusBarFrame.height +
            self.navigationController!.navigationBar.frame.height
        let windowFrameHeight = UIScreen.main.bounds.size.height
        return windowFrameHeight - topHeight;
    }
    
    /* Table view data source methods */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return months.count +
              daysThisMonth.count +
              numExpenseSpots +
              2
    }
    
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row <= lastPrevDayCellIndex {
            let prevDayCell = tableView.dequeueReusableCell(withIdentifier: "previousDay",
                                                            for: indexPath)
            if indexPath.row < months.count {
                let month = months[indexPath.row]
                let monthName = DateFormatter().monthSymbols[month.month!.month - 1]
                let monthAndYearName = monthName + " \(month.month!.year)"
                let primaryText = month.month!.year == Date().year ? monthName : monthAndYearName
                let detailText = String.formatAsCurrency(amount: month.actualSpend.doubleValue)
                let textColor = month.actualSpend > month.fullTargetSpend ? redColor : greenColor
                
                prevDayCell.textLabel?.text = primaryText
                prevDayCell.detailTextLabel?.text = detailText
                prevDayCell.detailTextLabel?.textColor = textColor
                
            } else {
                let day = daysThisMonth[indexPath.row - months.count]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "E, M/d"
                let primaryText = dateFormatter.string(from: day.date!)
                let detailText = String.formatAsCurrency(amount: day.actualSpend.doubleValue)
                let textColor = day.leftToCarry < 0 ? redColor : greenColor
                
                prevDayCell.textLabel?.text = primaryText
                prevDayCell.detailTextLabel?.text = detailText
                prevDayCell.detailTextLabel?.textColor = textColor
                
            }
            return prevDayCell
        } else if indexPath.row <= currentDayCellIndex {
            let cell = tableView.dequeueReusableCell(withIdentifier: "currentDay",
                                                     for: indexPath)
            let currentDayCell = cell as! CurrentDayTableViewCell
            if let today = daysThisMonth.last {
                let dailySpend = today.leftToCarry
                currentDayCell.setAndFormatLabels(dailySpendLeft: dailySpend,
                                                  previousDailySpendLeft: previousDailySpendLeft,
                                                  expensesToday: today.expenses!.count > 0)
                previousDailySpendLeft = dailySpend
            }
            return currentDayCell
        } else if indexPath.row <= lastExpenseCellIndex {
            let expenseCell = tableView.dequeueReusableCell(withIdentifier: "expense",
                                                            for: indexPath)
            let expenses = daysThisMonth.last!.sortedExpenses!

            if indexPath.row == lastExpenseCellIndex && expenses.count > numExpenseSpots {
                expenseCell.textLabel!.text = "\(expenses.count - numExpenseSpots + 1) more"
                var total: Decimal = 0
                for expense in expenses.suffix(from: numExpenseSpots - 1) {
                    total += expense.amount!
                }
                let detailText = String.formatAsCurrency(amount: total.doubleValue)
                expenseCell.detailTextLabel?.text = detailText
            } else {
                let index = indexPath.row - (currentDayCellIndex + 1)
                let amount = expenses[index].amount!.doubleValue
                let primaryText = expenses[index].shortDescription
                let detailText = String.formatAsCurrency(amount: amount)
                
                expenseCell.textLabel?.text = primaryText
                expenseCell.detailTextLabel?.text = detailText
            }
            return expenseCell
        } else if indexPath.row == lastExpenseCellIndex + 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addExpense",
                                                     for: indexPath)
            let addExpenseCell = cell as! AddExpenseTableViewCell
            addExpenseCell.delegate = self
            return addExpenseCell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "blank",
                                                     for: indexPath)
            cell.isUserInteractionEnabled = false
            return cell
        }
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row <= lastPrevDayCellIndex {
            return standardCellHeight
        } else if indexPath.row <= currentDayCellIndex {
            return currentDayHeight
        } else if indexPath.row <= lastExpenseCellIndex {
            return standardCellHeight
        } else if indexPath.row == lastExpenseCellIndex + 1 {
            return addExpenseHeight
        } else {
            return heightUsed < visibleHeight ? visibleHeight - heightUsed : 0
        }
        
    }
    
    func tableView(_ tableView: UITableView,
                   canEditRowAt indexPath: IndexPath) -> Bool {
        let bonusExpenses = daysThisMonth.last != nil &&
                            daysThisMonth.last!.expenses!.count > numExpenseSpots
        
        let lastEditableExpenseCellIndex = lastExpenseCellIndex - (bonusExpenses ? 1 : 0)
        
        return indexPath.row > currentDayCellIndex &&
               indexPath.row <= lastEditableExpenseCellIndex
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let today = daysThisMonth.last!
            let expenses = today.sortedExpenses!
            let index = indexPath.row - (currentDayCellIndex + 1)
            let expense = expenses[index]
            expense.day = nil
            
            context.delete(expense)
            appDelegate.saveContext()
            tableView.beginUpdates()
            if today.expenses!.count < maxExpenseSpots {
                tableView.deleteRows(at: [indexPath], with: .none)
            } else {
                var indexPaths: [IndexPath] = []
                let firstExpenseCellIndex = (currentDayCellIndex + 1)
                for i in firstExpenseCellIndex...lastExpenseCellIndex {
                     indexPaths.append(IndexPath(row: i, section: 0))
                }
                self.tableView.reloadRows(at: indexPaths, with: .none)
            }
            
            // Reload current day cell.
            let path = IndexPath(row: currentDayCellIndex, section: 0)
            self.tableView.reloadRows(at: [path], with: .none)
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView,
                   willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.row <= lastExpenseCellIndex {
            // Previous day and expense cells are selectable.
            return indexPath
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bonusExpenses = daysThisMonth.last == nil ?
                false :
                daysThisMonth.last!.expenses!.count > numExpenseSpots
        
        if indexPath.row > currentDayCellIndex &&
            indexPath.row <= lastExpenseCellIndex - (bonusExpenses ? 1 : 0) {
            // Expense (not bonus expense) selected
            let expenses = daysThisMonth.last!.sortedExpenses!
            let index = indexPath.row - (currentDayCellIndex + 1)
            let vc = storyboard!.instantiateViewController(withIdentifier: "Expense")
            let expenseVC = vc as! ExpenseViewController
            expenseVC.expense = expenses[index]
            self.navigationController?.pushViewController(expenseVC, animated: true)
        } else if bonusExpenses && indexPath.row == lastExpenseCellIndex ||
                  indexPath.row == currentDayCellIndex {
            // Bonus expense selected
            // Show today.
            let vc = storyboard!.instantiateViewController(withIdentifier: "Review")
            let reviewVC = vc as! ReviewTableViewController
            reviewVC.day = daysThisMonth.last!
            reviewVC.mode = .Days
            self.navigationController?.pushViewController(reviewVC, animated: true)
        } else if indexPath.row < currentDayCellIndex {
            if indexPath.row < months.count {
                // Month selected
                let vc = storyboard!.instantiateViewController(withIdentifier: "Review")
                let reviewVC = vc as! ReviewTableViewController
                reviewVC.month = months[indexPath.row]
                reviewVC.mode = .Months
                self.navigationController?.pushViewController(reviewVC, animated: true)
            } else {
                // Day selected
                let index = indexPath.row - months.count
                let vc = storyboard!.instantiateViewController(withIdentifier: "Review")
                let reviewVC = vc as! ReviewTableViewController
                reviewVC.day = daysThisMonth[index]
                reviewVC.mode = .Days
                self.navigationController?.pushViewController(reviewVC, animated: true)
            }
        }
    }
    
    /* Add Expense TableView Cell delegate methods */
    
    func didBeginEditing(sender: AddExpenseTableViewCell) {
        addingExpense = true
        
        self.tableView.isScrollEnabled = false

        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        
        adjustBarButton = self.navigationItem.rightBarButtonItem
        settingsBarButton = self.navigationItem.leftBarButtonItem
        let saveBBI = UIBarButtonItem(title: "Save",
                                      style: .done,
                                      target: self,
                                      action: #selector(rightBarButtonPressed(sender:)))
        let cancelBBI = UIBarButtonItem(title: "Cancel",
                                        style: .plain,
                                        target: self,
                                        action: #selector(cancelAddingExpense(sender:)))
        self.navigationItem.rightBarButtonItem = saveBBI
        self.navigationItem.leftBarButtonItem = cancelBBI
        
        self.tableView.scrollToRow(at: IndexPath(row: addExpenseCellIndex, section: 0),
                                   at: .top, animated: true)
    }
    
    func cancelAddingExpense(sender: UIBarButtonItem) {
        let nc = NotificationCenter.default
        nc.post(name: NSNotification.Name.init("PressedCancelButton"),
                object: UIApplication.shared)

        self.tableView.isScrollEnabled = true
        self.navigationItem.leftBarButtonItem = settingsBarButton
        self.navigationItem.rightBarButtonItem = adjustBarButton
        addingExpense = false
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        
        self.tableView.scrollToRow(at: IndexPath(row: currentDayCellIndex, section: 0),
                                   at: .top, animated: true)
    }
    
    func rightBarButtonPressed(sender: UIBarButtonItem) {
        let buttonTitle = sender.title!
        let nc = NotificationCenter.default
        nc.post(name: NSNotification.Name.init("Pressed\(buttonTitle)Button"),
                object: UIApplication.shared)
        if buttonTitle == "Done" {
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            sender.title! = "Save"
        }
    }
    
    func didOpenNotes(sender: AddExpenseTableViewCell) {
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationItem.rightBarButtonItem?.title = "Done"
    }
    
    func completedExpense(sender: AddExpenseTableViewCell,
                          expense: Expense,
                          reloadFull: Bool) {
        self.tableView.isScrollEnabled = true
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem = adjustBarButton
        self.navigationItem.leftBarButtonItem = settingsBarButton
        addingExpense = false
        if reloadFull {
            print("reloading full")
            viewWillAppear(false)
        } else {
            self.tableView.beginUpdates()
            if expense.day!.date!.beginningOfDay == Date().beginningOfDay &&
                daysThisMonth.last!.expenses!.count <= numExpenseSpots {
                // The number of rows has changed, so we need to insert them.
                let locationOfNewRow = months.count +
                                       daysThisMonth.count +
                                       daysThisMonth.last!.expenses!.count -
                                       1
                let indices = [IndexPath(row: locationOfNewRow, section: 0)]
                self.tableView.insertRows(at: indices, with: .bottom)
            } else {
                let indices = [IndexPath(row: lastExpenseCellIndex, section: 0)]
                tableView.reloadRows(at: indices, with: .none)
            }
            let indices = [IndexPath(row: currentDayCellIndex, section: 0)]
            tableView.reloadRows(at: indices, with: .none)
            self.tableView.endUpdates()
        }
        let path = IndexPath(row: currentDayCellIndex, section: 0)
        self.tableView.scrollToRow(at: path,
                                   at: .top, animated: true)
    }
    
    func invalidFields(sender: AddExpenseTableViewCell) {
        let message = "Please enter valid values for amount, description, and date."
        let alert = UIAlertController(title: "Invalid Fields",
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    func printAllCoreData() {
        print("\(months.count) months (not including this one)")
        print("\(daysThisMonth.count) days this month")
        
        let monthsFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
        let monthSortDesc = NSSortDescriptor(key: "month_", ascending: true)
        monthsFetchReq.sortDescriptors = [monthSortDesc]
        let allMonths = try! context.fetch(monthsFetchReq)
        
        for (index, month) in allMonths.enumerated() {
            print("allMonths[\(index)]")
            let dateFormatter = DateFormatter()
            let humanMonth = dateFormatter.monthSymbols[month.month!.month - 1]
            let humanMonthYear = humanMonth + " \(month.month!.year)"
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .full
            
            print("\(humanMonthYear) - \(dateFormatter.string(from: month.month!))")
            print("month.dailyBaseTargetSpend: \(month.dailyBaseTargetSpend!)")
            print("month.dateCreated: \(dateFormatter.string(from: month.dateCreated!))")
            
            
            if (month.adjustments!.count > 0) {
                print("\tMonthAdjustments:")
            } else {
                print("\tNo MonthAdjustments.")
            }
            for monthAdjustment in month.sortedAdjustments! {
                let created = dateFormatter.string(from: monthAdjustment.dateCreated!)
                let effective = dateFormatter.string(from: monthAdjustment.dateEffective!)
                print("\tmonthAdjustment.amount: \(monthAdjustment.amount!)")
                print("\tmonthAdjustment.dateCreated: \(created)")
                print("\tmonthAdjustment.dateEffective: \(effective)")
                print("\tmonthAdjustment.reason: \(monthAdjustment.reason!)")
                print("")
            }
            
            
            if (month.days!.count > 0) {
                print("\tDays:")
            } else {
                print("\tNo Days.")
            }
            for day in month.sortedDays! {
                print("\tday.baseTargetSpend: \(day.baseTargetSpend!)")
                print("\tday.date: \(dateFormatter.string(from: day.date!))")
                print("\tday.dateCreated: \(dateFormatter.string(from: day.dateCreated!))")
                
                
                if (day.adjustments!.count > 0) {
                    print("\t\tDayAdjustments:")
                } else {
                    print("\t\tNo DayAdjustments.")
                }
                for dayAdjustment in day.sortedAdjustments! {
                    let created = dateFormatter.string(from: dayAdjustment.dateCreated!)
                    let affected = dateFormatter.string(from: dayAdjustment.dateAffected!)
                    print("\t\tdayAdjustment.amount: \(dayAdjustment.amount!)")
                    print("\t\tdayAdjustment.dateAffected: \(created)")
                    print("\t\tdayAdjustment.dateCreated: \(affected)")
                    print("\t\tdayAdjustment.reason: \(dayAdjustment.reason!)")
                    print("")
                }
                
                
                if (day.expenses!.count > 0) {
                    print("\t\tExpenses:")
                } else {
                    print("\t\tNo Expenses.")
                }
                for expense in day.sortedExpenses! {
                    let created = dateFormatter.string(from: expense.dateCreated!)
                    print("\t\texpense.amount: \(expense.amount!)")
                    print("\t\texpense.dateCreated: \(created)")
                    print("\t\texpense.notes: \(expense.notes ?? "")")
                    print("\t\texpense.shortDescription: \(expense.shortDescription!)")
                    print("")
                }
                print("")
                
            }
            print("")
            
        }
    }

}
