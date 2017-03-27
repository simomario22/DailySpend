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
    let currentDayHeight: CGFloat = 115
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
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        latestDayFetchReq.sortDescriptors = [latestDaySortDesc]
        latestDayFetchReq.fetchLimit = 10
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
        
        let locationOfTodayCell = months.count + daysThisMonth.count - 1
        self.tableView.scrollToRow(at: IndexPath(row: locationOfTodayCell, section: 0),
                                   at: .top, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Spending"
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    /* Methods for managment of CoreData */
    
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
                _ = Day.create(context: context, date: currentDate, month: month)
                appDelegate.saveContext()
                currentDate = currentDate.add(days: 1)
            } else {
                // This month doesn't yet exist.
                // Create and review the previous month, then call this function again.
                _ = Month.create(context: context, dateInMonth: currentDate)
                appDelegate.saveContext()
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
        return months.count + daysThisMonth.count + numExpenseSpots() + 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let lastPrevDayCellIndex = months.count + daysThisMonth.count - 2
        let currentDayCellIndex = lastPrevDayCellIndex + 1
        let lastExpenseCellIndex = currentDayCellIndex + numExpenseSpots()
        
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
                
                if day.actualSpend > day.fullTargetSpend {
                    prevDayCell.detailTextLabel?.textColor = redColor
                } else {
                    prevDayCell.detailTextLabel?.textColor = greenColor
                }
                
            }
            return prevDayCell
        } else if indexPath.row <= currentDayCellIndex {
            let currentDayCell = tableView.dequeueReusableCell(withIdentifier: "currentDay", for: indexPath) as! CurrentDayTableViewCell
            if let today = daysThisMonth.last {
                let dailyLeft = today.fullTargetSpend - today.actualSpend
                let monthlyLeft = today.month!.fullTargetSpend - today.month!.actualSpend
                
                currentDayCell.setAndFormatLabels(dailySpendLeft: dailyLeft,
                                                  previousDailySpendLeft: previousDailySpendLeft,
                                                  monthlySpendLeft: monthlyLeft,
                                                  expensesToday: today.expenses!.count > 0)
                previousDailySpendLeft = dailyLeft
            }
            return currentDayCell
        } else if indexPath.row <= lastExpenseCellIndex {
            let expenseCell = tableView.dequeueReusableCell(withIdentifier: "expense", for: indexPath)
            let expenses = daysThisMonth.last!.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
            let index = indexPath.row - (currentDayCellIndex + 1)
            expenseCell.textLabel?.text = expenses[index].shortDescription
            expenseCell.detailTextLabel?.text = String.formatAsCurrency(amount: expenses[index].amount!.doubleValue)
            return expenseCell
        } else {
            let addExpenseCell = tableView.dequeueReusableCell(withIdentifier: "addExpense", for: indexPath) as! AddExpenseTableViewCell
            addExpenseCell.delegate = self
            return addExpenseCell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let lastPrevDayCellIndex = months.count + daysThisMonth.count - 2
        let currentDayCellIndex = lastPrevDayCellIndex + 1
        let lastExpenseCellIndex = currentDayCellIndex + numExpenseSpots()
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
        let lastPrevDayCellIndex = months.count + daysThisMonth.count - 2
        let currentDayCellIndex = lastPrevDayCellIndex + 1
        let lastExpenseCellIndex = currentDayCellIndex + numExpenseSpots()
        if indexPath.row > currentDayCellIndex && indexPath.row <= lastExpenseCellIndex {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let lastPrevDayCellIndex = months.count + daysThisMonth.count - 2
            let currentDayCellIndex = lastPrevDayCellIndex + 1

            let today = daysThisMonth.last!
            let expenses = today.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
            let index = indexPath.row - (currentDayCellIndex + 1)
            let expense = expenses[index]
            expense.day = nil
            
            context.delete(expenses[index])
            appDelegate.saveContext()

            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            self.tableView.reloadRows(at: [IndexPath(row: currentDayCellIndex, section: 0)], with: .none)

        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    
    
    
    
    
    /* Add Expense TableView Cell delegate methods */
    
    func didBeginEditing(sender: AddExpenseTableViewCell) {
        addingExpense = true
        
        self.tableView.isScrollEnabled = false

        self.tableView.beginUpdates()
        self.tableView.endUpdates()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(rightBarButtonPressed(sender:)))
        adjustBarButton = self.navigationItem.leftBarButtonItem
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelAddingExpense(sender:)))
        
        let locationOfAddExpenseCell = months.count + daysThisMonth.count + numExpenseSpots()
        
        self.tableView.scrollToRow(at: IndexPath(row: locationOfAddExpenseCell, section: 0),
                                   at: .top, animated: true)
    }
    
    func cancelAddingExpense(sender: UIBarButtonItem) {
        NotificationCenter.default.post(name: NSNotification.Name.init("PressedCancelButton"), object: UIApplication.shared)

        self.tableView.isScrollEnabled = true
        self.navigationItem.leftBarButtonItem = adjustBarButton
        adjustBarButton = nil
        self.navigationItem.rightBarButtonItem = nil
        addingExpense = false
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        
        let locationOfTodayCell = months.count + daysThisMonth.count - 1
        self.tableView.scrollToRow(at: IndexPath(row: locationOfTodayCell, section: 0),
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
        self.tableView.isScrollEnabled = true
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem = nil
        addingExpense = false
        self.tableView.beginUpdates()
        if expense.day!.date!.beginningOfDay == Date().beginningOfDay &&
            daysThisMonth.last!.expenses!.count <= numExpenseSpots() {
            // The number of rows has changed, so we need to insert them.
            let locationOfNewRow = months.count + daysThisMonth.count + daysThisMonth.last!.expenses!.count - 1
            self.tableView.insertRows(at: [IndexPath(row: locationOfNewRow, section: 0)], with: .bottom)
        }
        self.tableView.endUpdates()
        
        let lastPrevDayCellIndex = months.count + daysThisMonth.count - 2
        let currentDayCellIndex = lastPrevDayCellIndex + 1

        self.tableView.reloadRows(at: [IndexPath(row: currentDayCellIndex, section: 0)], with: .none)
        //self.tableView.reloadData()
        
        let locationOfTodayCell = months.count + daysThisMonth.count - 1
        self.tableView.scrollToRow(at: IndexPath(row: locationOfTodayCell, section: 0),
                                   at: .top, animated: true)
    }
    
    func invalidFields(sender: AddExpenseTableViewCell) {
        let alert = UIAlertController(title: "Invalid Fields", message: "Please enter valid values for amount, description, and date.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
        
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
            print("month.dailyBaseTargetSpend: \(month.dailyBaseTargetSpend)")
            print("month.dateCreated: \(dateFormatter.string(from: month.dateCreated!))")
            
            
            if (month.adjustments!.count > 0) {
                print("\tMonthAdjustments:")
            } else {
                print("\tNo MonthAdjustments.")
            }
            for monthAdjustment in month.adjustments!.sorted(by: {$0.dateCreated! < $1.dateCreated!}) {
                print("\tmonthAdjustment.amount: \(monthAdjustment.amount)")
                print("\tmonthAdjustment.dateCreated: \(monthAdjustment.dateCreated)")
                print("\tmonthAdjustment.dateEffective: \(monthAdjustment.dateEffective)")
                print("\tmonthAdjustment.reason: \(monthAdjustment.reason)")
                print("")
            }
            
            
            if (month.days!.count > 0) {
                print("\tDays:")
            } else {
                print("\tNo Days.")
            }
            for day in month.days!.sorted(by: {$0.date! < $1.date!}) {
                print("\tday.baseTargetSpend: \(day.baseTargetSpend)")
                print("\tday.date: \(dateFormatter.string(from: day.date!))")
                print("\tday.dateCreated: \(dateFormatter.string(from: day.dateCreated!))")
                
                
                if (day.expenses!.count > 0) {
                    print("\t\tDayAdjustments:")
                } else {
                    print("\t\tNo DayAdjustments.")
                }
                for dayAdjustment in day.adjustments!.sorted(by: {$0.dateCreated! < $1.dateCreated!}) {
                    print("\t\tdayAdjustment.amount: \(dayAdjustment.amount)")
                    print("\t\tdayAdjustment.dateAffected: \(dateFormatter.string(from: dayAdjustment.dateAffected!))")
                    print("\t\tdayAdjustment.dateCreated: \(dateFormatter.string(from: dayAdjustment.dateCreated!))")
                    print("\t\tdayAdjustment.reason: \(dayAdjustment.reason)")
                    print("")
                }
                
                
                if (day.expenses!.count > 0) {
                    print("\t\tExpenses:")
                } else {
                    print("\t\tNo Expenses.")
                }
                for expense in day.expenses!.sorted(by: {$0.dateCreated! < $1.dateCreated!}) {
                    print("\t\texpense.amount: \(expense.amount)")
                    print("\t\texpense.dateCreated: \(dateFormatter.string(from: expense.dateCreated!))")
                    print("\t\texpense.notes: \(expense.notes)")
                    print("\t\texpense.shortDescription: \(expense.shortDescription)")
                    print("")
                }
                print("")
                
            }
            print("")
            
        }
    }

}
