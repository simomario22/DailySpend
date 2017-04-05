//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/6/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController : UIViewController, AddExpenseTableViewCellDelegate, UITableViewDataSource, UITableViewDelegate {
    let standardCellHeight: CGFloat = 44
    let currentDayHeight: CGFloat = 130
    let addExpenseHeight: CGFloat = 213
    let addExpenseMinPxVisible: CGFloat = 70
    let heightOfTodaysSpendingLabel: CGFloat = 21

    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let redColor = UIColor(colorLiteralRed: 179.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1)
    let greenColor = UIColor(colorLiteralRed: 0.0/255.0, green: 179.0/255.0, blue: 0.0/255.0, alpha: 1)
    
    var daysThisMonth: [Day] = []
    var months: [Month] = []
    var addingExpense = false
    var previousDailySpendLeft: Decimal = 0
    var adjustBarButton: UIBarButtonItem?
    
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
            
            let navController = storyboard!.instantiateViewController(withIdentifier: "InitialSpend")
            
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
        let from = latestDayResults.count < 1 ? Date() : latestDayResults[0].date!.add(days: 1)
        let to = Date().add(days: 1)
        createDays(from: from, to: to)
        
        fetchMonthsAndDays()
        
        printAllCoreData()
        
        self.tableView.reloadData()
        
        self.tableView.scrollToRow(at: IndexPath(row: currentDayCellIndex, section: 0),
                                   at: .top, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Spending"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* Methods for managment of CoreData */

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
                _ = Day.create(context: context, date: currentDate, month: month)
                appDelegate.saveContext()
                currentDate = currentDate.add(days: 1)
            } else {
                // This month doesn't yet exist.
                // Create and review the previous month, then call this function again.
                _ = Month.create(context: context, dateInMonth: currentDate)
                appDelegate.saveContext()
            }
        }
    }
    
    var maxExpenseSpots: Int {
        let topHeight = UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.frame.height
        let windowFrameHeight = tableView.frame.height
        let visibleHeight = windowFrameHeight - topHeight;
        
        // Let's do something simple like integer division. Oh, what a joy.
        return Int(floor(Double(visibleHeight - currentDayHeight - addExpenseMinPxVisible) / Double(standardCellHeight)))
    }
    
    /*
     * Calculates the number of on-screen spots for expenses (including "see
     * additional" spots) while keeping addExpenseMinPxVisible pixels visible in
     * the addExpense cell
     */
    var numExpenseSpots: Int {
        let totalExpenses = daysThisMonth.count > 0 ? daysThisMonth.last!.expenses!.count : 0
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

    func fetchMonthsAndDays() {
        // Populate daysThisMonth and months
        let today = Date()
        
        // Fetch all days this month
        let daysThisMonthFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let daysThisMonthSortDesc = NSSortDescriptor(key: "date_", ascending: true)
        daysThisMonthFetchReq.sortDescriptors = [daysThisMonthSortDesc]
        daysThisMonthFetchReq.predicate = NSPredicate(format: "month_.month_ == %@", Date.firstDayOfMonth(dayInMonth: today) as CVarArg)
        daysThisMonth = try! context.fetch(daysThisMonthFetchReq)
        
        // Fetch all previous months
        let monthsFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
        let monthSortDesc = NSSortDescriptor(key: "month_", ascending: true)
        monthsFetchReq.sortDescriptors = [monthSortDesc]
        monthsFetchReq.predicate = NSPredicate(format: "month_ != %@", Date.firstDayOfMonth(dayInMonth: today) as CVarArg)
        months = try! context.fetch(monthsFetchReq)
    }
    

    
    
    
    
    /* Table view data source methods */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return months.count + daysThisMonth.count + numExpenseSpots + 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row <= lastPrevDayCellIndex {
            let prevDayCell = tableView.dequeueReusableCell(withIdentifier: "previousDay", for: indexPath)
            if indexPath.row < months.count {
                let month = months[indexPath.row]
                let monthName = DateFormatter().monthSymbols[month.month!.month - 1]
                let monthAndYearName = monthName + " \(month.month!.year)"
                prevDayCell.textLabel?.text = month.month!.year == Date().year ? monthName : monthAndYearName
                prevDayCell.detailTextLabel?.text = String.formatAsCurrency(amount: month.actualSpend.doubleValue)

                if month.actualSpend > month.fullTargetSpend {
                    prevDayCell.detailTextLabel?.textColor = redColor
                } else {
                    prevDayCell.detailTextLabel?.textColor = greenColor
                }
                
            } else {
                let day = daysThisMonth[indexPath.row - months.count]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "E, M/d"
                prevDayCell.textLabel?.text = dateFormatter.string(from: day.date!)
                prevDayCell.detailTextLabel?.text = String.formatAsCurrency(amount: day.actualSpend.doubleValue)
                
                if day.leftToCarry < 0 {
                    prevDayCell.detailTextLabel?.textColor = redColor
                } else {
                    prevDayCell.detailTextLabel?.textColor = greenColor
                }
                
            }
            return prevDayCell
        } else if indexPath.row <= currentDayCellIndex {
            let currentDayCell = tableView.dequeueReusableCell(withIdentifier: "currentDay", for: indexPath) as! CurrentDayTableViewCell
            if let today = daysThisMonth.last {
                let dailySpend = today.leftToCarry
                currentDayCell.setAndFormatLabels(dailySpendLeft: dailySpend,
                                                  previousDailySpendLeft: previousDailySpendLeft,
                                                  expensesToday: today.expenses!.count > 0)
                previousDailySpendLeft = dailySpend
            }
            return currentDayCell
        } else if indexPath.row <= lastExpenseCellIndex {
            let expenseCell = tableView.dequeueReusableCell(withIdentifier: "expense", for: indexPath)
            let expenses = daysThisMonth.last!.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })

            if indexPath.row == lastExpenseCellIndex && expenses.count > numExpenseSpots {
                expenseCell.textLabel!.text = "\(expenses.count - numExpenseSpots + 1) more"
                var total: Decimal = 0
                for expense in expenses.suffix(from: numExpenseSpots - 1) {
                    total += expense.amount!
                }
                expenseCell.detailTextLabel?.text = String.formatAsCurrency(amount: total.doubleValue)
            } else {
                let index = indexPath.row - (currentDayCellIndex + 1)
                expenseCell.textLabel?.text = expenses[index].shortDescription
                expenseCell.detailTextLabel?.text = String.formatAsCurrency(amount: expenses[index].amount!.doubleValue)
            }
            
            return expenseCell
        } else {
            let addExpenseCell = tableView.dequeueReusableCell(withIdentifier: "addExpense", for: indexPath) as! AddExpenseTableViewCell
            addExpenseCell.delegate = self
            return addExpenseCell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row <= lastPrevDayCellIndex {
            return standardCellHeight
        } else if indexPath.row <= currentDayCellIndex {
            if daysThisMonth.last == nil || daysThisMonth.last!.expenses!.count == 0 {
                return currentDayHeight - heightOfTodaysSpendingLabel
            } else {
                return currentDayHeight
            }
        } else if indexPath.row <= lastExpenseCellIndex {
            return standardCellHeight
        } else {
            if addingExpense {
                let topHeight = UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.frame.height
                let windowFrameHeight = tableView.frame.height
                let visibleHeight = windowFrameHeight - topHeight;
                return visibleHeight
            } else {
                return addExpenseHeight
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let bonusExpenses = daysThisMonth.last != nil && daysThisMonth.last!.expenses!.count > numExpenseSpots
        
        if indexPath.row > currentDayCellIndex &&
            indexPath.row <= lastExpenseCellIndex - (bonusExpenses ? 1 : 0) {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let today = daysThisMonth.last!
            let expenses = today.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
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
                for i in (currentDayCellIndex + 1)...(currentDayCellIndex + numExpenseSpots) {
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
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
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
            let expenses = daysThisMonth.last!.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
            let index = indexPath.row - (currentDayCellIndex + 1)
            let expenseVC = storyboard!.instantiateViewController(withIdentifier: "Expense") as! ExpenseViewController
            expenseVC.expense = expenses[index]
            self.navigationController?.pushViewController(expenseVC, animated: true)
        } else if bonusExpenses && indexPath.row == lastExpenseCellIndex ||
                  indexPath.row == currentDayCellIndex {
            // Bonus expense selected
            // Show today.
            let reviewVC = storyboard!.instantiateViewController(withIdentifier: "Review") as! ReviewTableViewController
            reviewVC.day = daysThisMonth.last!
            reviewVC.mode = .Days
            self.navigationController?.pushViewController(reviewVC, animated: true)
        } else if indexPath.row < currentDayCellIndex {
            if indexPath.row < months.count {
                // Month selected
                let reviewVC = storyboard!.instantiateViewController(withIdentifier: "Review") as! ReviewTableViewController
                reviewVC.month = months[indexPath.row]
                reviewVC.mode = .Months
                self.navigationController?.pushViewController(reviewVC, animated: true)
            } else {
                // Day selected
                let index = indexPath.row - months.count
                let reviewVC = storyboard!.instantiateViewController(withIdentifier: "Review") as! ReviewTableViewController
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(rightBarButtonPressed(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAddingExpense(sender:)))
        
        let locationOfAddExpenseCell = months.count + daysThisMonth.count + numExpenseSpots
        
        self.tableView.scrollToRow(at: IndexPath(row: locationOfAddExpenseCell, section: 0),
                                   at: .top, animated: true)
    }
    
    func cancelAddingExpense(sender: UIBarButtonItem) {
        NotificationCenter.default.post(name: NSNotification.Name.init("PressedCancelButton"), object: UIApplication.shared)

        self.tableView.isScrollEnabled = true
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = adjustBarButton
        addingExpense = false
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        
        self.tableView.scrollToRow(at: IndexPath(row: currentDayCellIndex, section: 0),
                                   at: .top, animated: true)
    }
    
    func rightBarButtonPressed(sender: UIBarButtonItem) {
        let buttonTitle = sender.title!
        NotificationCenter.default.post(name: NSNotification.Name.init("Pressed\(buttonTitle)Button"), object: UIApplication.shared)
        if buttonTitle == "Done" {
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            sender.title! = "Save"
        }
    }
    
    func didOpenNotes(sender: AddExpenseTableViewCell) {
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationItem.rightBarButtonItem?.title = "Done"
    }
    
    func completedExpense(sender: AddExpenseTableViewCell, expense: Expense, reloadFull: Bool) {
        self.tableView.isScrollEnabled = true
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem = self.adjustBarButton
        self.navigationItem.leftBarButtonItem = nil
        addingExpense = false
        if reloadFull {
            print("reloading full")
            viewWillAppear(false)
        } else {
            self.tableView.beginUpdates()
            if expense.day!.date!.beginningOfDay == Date().beginningOfDay &&
                daysThisMonth.last!.expenses!.count <= numExpenseSpots {
                // The number of rows has changed, so we need to insert them.
                let locationOfNewRow = months.count + daysThisMonth.count + daysThisMonth.last!.expenses!.count - 1
                self.tableView.insertRows(at: [IndexPath(row: locationOfNewRow, section: 0)], with: .bottom)
            } else {
                tableView.reloadRows(at: [IndexPath(row: lastExpenseCellIndex, section: 0)], with: .none)
            }
            tableView.reloadRows(at: [IndexPath(row: currentDayCellIndex, section: 0)], with: .none)
            self.tableView.endUpdates()
        }
        self.tableView.scrollToRow(at: IndexPath(row: currentDayCellIndex, section: 0),
                                   at: .top, animated: true)
    }
    
    func invalidFields(sender: AddExpenseTableViewCell) {
        let alert = UIAlertController(title: "Invalid Fields", message: "Please enter valid values for amount, description, and date.", preferredStyle: UIAlertControllerStyle.alert)
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
            let humanReadableMonthName = dateFormatter.monthSymbols[month.month!.month - 1] + " \(month.month!.year)"
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .full
            
            print("\(humanReadableMonthName) - \(dateFormatter.string(from: month.month!))")
            print("month.dailyBaseTargetSpend: \(month.dailyBaseTargetSpend!)")
            print("month.dateCreated: \(dateFormatter.string(from: month.dateCreated!))")
            
            
            if (month.adjustments!.count > 0) {
                print("\tMonthAdjustments:")
            } else {
                print("\tNo MonthAdjustments.")
            }
            for monthAdjustment in month.adjustments!.sorted(by: {$0.dateCreated! < $1.dateCreated!}) {
                print("\tmonthAdjustment.amount: \(monthAdjustment.amount!)")
                print("\tmonthAdjustment.dateCreated: \(dateFormatter.string(from: monthAdjustment.dateCreated!))")
                print("\tmonthAdjustment.dateEffective: \(dateFormatter.string(from: monthAdjustment.dateEffective!))")
                print("\tmonthAdjustment.reason: \(monthAdjustment.reason!)")
                print("")
            }
            
            
            if (month.days!.count > 0) {
                print("\tDays:")
            } else {
                print("\tNo Days.")
            }
            for day in month.days!.sorted(by: {$0.date! < $1.date!}) {
                print("\tday.baseTargetSpend: \(day.baseTargetSpend!)")
                print("\tday.date: \(dateFormatter.string(from: day.date!))")
                print("\tday.dateCreated: \(dateFormatter.string(from: day.dateCreated!))")
                
                
                if (day.adjustments!.count > 0) {
                    print("\t\tDayAdjustments:")
                } else {
                    print("\t\tNo DayAdjustments.")
                }
                for dayAdjustment in day.adjustments!.sorted(by: {$0.dateCreated! < $1.dateCreated!}) {
                    print("\t\tdayAdjustment.amount: \(dayAdjustment.amount!)")
                    print("\t\tdayAdjustment.dateAffected: \(dateFormatter.string(from: dayAdjustment.dateAffected!))")
                    print("\t\tdayAdjustment.dateCreated: \(dateFormatter.string(from: dayAdjustment.dateCreated!))")
                    print("\t\tdayAdjustment.reason: \(dayAdjustment.reason!)")
                    print("")
                }
                
                
                if (day.expenses!.count > 0) {
                    print("\t\tExpenses:")
                } else {
                    print("\t\tNo Expenses.")
                }
                for expense in day.expenses!.sorted(by: {$0.dateCreated! < $1.dateCreated!}) {
                    print("\t\texpense.amount: \(expense.amount!)")
                    print("\t\texpense.dateCreated: \(dateFormatter.string(from: expense.dateCreated!))")
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
