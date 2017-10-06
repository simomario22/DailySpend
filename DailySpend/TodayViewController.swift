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
        let baseHeight: CGFloat = 140
        let heightOfTodaysSpendingLabel: CGFloat = 21
        if daysThisMonth.last == nil ||
            daysThisMonth.last!.expenses!.count == 0 {
            return baseHeight - heightOfTodaysSpendingLabel
        } else {
            return baseHeight
        }
        
    }
    var addExpenseHeight: CGFloat {
        let baseHeight: CGFloat = 400
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
    let redColor = UIColor(red: 179.0/255.0,
                           green: 0.0/255.0,
                           blue: 0.0/255.0,
                           alpha: 1)
    let greenColor = UIColor(red: 0.0/255.0,
                             green: 179.0/255.0,
                             blue: 0.0/255.0,
                             alpha: 1)
    let blueColor = UIColor(red: 0.0/255.0,
                             green: 0.0/255.0,
                             blue: 179.0/255.0,
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
            latestDayResults[0].calendarDay! < CalendarDay() {
            // The day has changed since we last opened the app.
            // Refresh.
            if addingExpense {
                let nc = NotificationCenter.default
                nc.post(name: NSNotification.Name.init("CancelAddingExpense"),
                        object: UIApplication.shared)
            }
            viewWillAppear(false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.double(forKey: "dailyTargetSpend") <= 0 {
            let sb = storyboard!
            let id = "InitialSpend"
            let navController = sb.instantiateViewController(withIdentifier: id)
            
            navController.modalPresentationStyle = .fullScreen
            navController.modalTransitionStyle = .coverVertical
            self.present(navController, animated: true, completion: nil)
            return
        }
        
        // Check if any months exist
        let latestMonthFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
        let latestMonthSortDesc = NSSortDescriptor(key: "month_", ascending: false)
        latestMonthFetchReq.sortDescriptors = [latestMonthSortDesc]
        latestMonthFetchReq.fetchLimit = 1
        let latestMonthResults = try! context.fetch(latestMonthFetchReq)
        
        if (latestMonthResults.count < 1) {
            // To satisfy requirement of createDays, create month for this month
            _ = Month.create(context: context, calMonth: CalendarMonth())
            appDelegate.saveContext()
        }
        
        if UserDefaults.standard.bool(forKey: "timezoneFix1Applied") == false {
            TimezoneFix1.fix()
            UserDefaults.standard.set(true, forKey: "timezoneFix1Applied")
        }
        
        // Fetch the latest day created.
        let latestDayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let latestDaySortDesc = NSSortDescriptor(key: "date_", ascending: false)
        latestDayFetchReq.sortDescriptors = [latestDaySortDesc]
        latestDayFetchReq.fetchLimit = 1
        let latestDayResults = try! context.fetch(latestDayFetchReq)
        
        // Start from one after the latest created date (or today) and go to
        // today
        let from = latestDayResults.first?.calendarDay?.add(days: 1) ?? CalendarDay()
        let to = CalendarDay().add(days: 1)
        Day.createDays(context: context, from: from, to: to)
        appDelegate.saveContext()
        
        fetchMonthsAndDays()
        
        printAllCoreData()
        
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = navigationController!.navigationBar.frame.size.width * (2 / 3)
        let titleLabelView = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: 44))
        titleLabelView.backgroundColor = UIColor.clear
        titleLabelView.textAlignment = .center
        titleLabelView.textColor = UINavigationBar.appearance().tintColor
        titleLabelView.font = UIFont.boldSystemFont(ofSize: 16.0)
        titleLabelView.text = "Spending"
        self.navigationItem.titleView = titleLabelView

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        NotificationCenter.default.addObserver(self,
                       selector: #selector(willEnterForeground),
                       name: NSNotification.Name.UIApplicationWillEnterForeground,
                       object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0001) {
            if UserDefaults.standard.double(forKey: "dailyTargetSpend") > 0 {
                let currentDayPath = IndexPath(row: self.currentDayCellIndex,
                                               section: 0)
                self.tableView.scrollToRow(at: currentDayPath,
                                           at: .top, animated: false)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* Functions for managment of CoreData */

    func fetchMonthsAndDays() {
        // Populate daysThisMonth and months

        // Fetch all  months
        let monthsFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
        let monthSortDesc = NSSortDescriptor(key: "month_", ascending: true)
        monthsFetchReq.sortDescriptors = [monthSortDesc]
        months = try! context.fetch(monthsFetchReq)
        
        // Pop this month and get its days.
        if let thisMonth = months.popLast() {
            let today = CalendarDay()
            daysThisMonth = thisMonth.sortedDays!.filter { $0.calendarDay! <= today }
        }
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
                
                let dateFormatter = DateFormatter()
                let monthsYear = month.calendarMonth!.year
                let currentYear = CalendarMonth().year
                // Only include the year if it's different than the current year.
                dateFormatter.dateFormat = monthsYear != currentYear ? "MMMM YYYY" : "MMMM"
                
                let primaryText = month.calendarMonth!.string(formatter: dateFormatter)
                let detailText = String.formatAsCurrency(amount: month.actualSpend!.doubleValue)
                let textColor = month.actualSpend! > month.fullTargetSpend! ? redColor : greenColor
                
                prevDayCell.textLabel?.text = primaryText
                prevDayCell.detailTextLabel?.text = detailText
                prevDayCell.detailTextLabel?.textColor = textColor
                
            } else {
                let day = daysThisMonth[indexPath.row - months.count]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "E, M/d"
                let primaryText = day.calendarDay!.string(formatter: dateFormatter)
                let detailText = String.formatAsCurrency(amount: day.actualSpend.doubleValue)
                
                var textColor = day.leftToCarry < 0 ? redColor : greenColor
                if day.pause != nil {
                    textColor = blueColor
                }
                
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
            let addExpenseCell = cell as! ExpenseTableViewCell
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
            let expenseVC = ExpenseViewController(nibName: nil, bundle: nil)
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
    
    func expandCell(sender: ExpenseTableViewCell) {
        addingExpense = true
        
        self.tableView.isScrollEnabled = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })
        
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseInOut,
        animations: {
            self.animateTitle(newTitle: "Add Expense", fromTop: true)
        }, completion: nil)

        self.tableView.scrollToRow(at: IndexPath(row: addExpenseCellIndex, section: 0),
                                   at: .top, animated: true)
    }
    
    
    func collapseCell(sender: ExpenseTableViewCell) {
        self.tableView.isScrollEnabled = true
        
        addingExpense = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })
        
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseInOut,
                       animations: {
                        self.animateTitle(newTitle: "Spending", fromTop: false)
        }, completion: nil)
        self.tableView.scrollToRow(at: IndexPath(row: currentDayCellIndex, section: 0),
                                   at: .top, animated: true)
    }
    
    func addedExpense(expense: Expense) {
        if expense.day!.calendarDay! != CalendarDay() {
            // This expense isn't for today. Do a full refresh because it 
            // affected month and day rows.
            viewWillAppear(false)
        } else {
            self.tableView.beginUpdates()
            if daysThisMonth.last!.expenses!.count <= numExpenseSpots {
                // We have not yet reached bonus expenses, so we will be 
                // inserting a new row.
                let locationOfNewRow = months.count +
                    daysThisMonth.count +
                    daysThisMonth.last!.expenses!.count - 1
                let indices = [IndexPath(row: locationOfNewRow, section: 0)]
                self.tableView.insertRows(at: indices, with: .bottom)
            } else {
                // There are bonus expenses, just reload the bonus expense cell.
                let indices = [IndexPath(row: lastExpenseCellIndex, section: 0)]
                tableView.reloadRows(at: indices, with: .none)
            }
            // Reload the current day cell, since the DailySpend amount changed.
            let indices = [IndexPath(row: currentDayCellIndex, section: 0)]
            tableView.reloadRows(at: indices, with: .none)
            self.tableView.endUpdates()
        }

    }
    
    func setRightBBI(_ bbi: UIBarButtonItem) {
        navigationItem.rightBarButtonItem = bbi
    }
    
    func setLeftBBI(_ bbi: UIBarButtonItem) {
        navigationItem.leftBarButtonItem = bbi
    }
    
    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?, sender: Any?) {
        self.present(vc, animated: animated, completion: completion)
    }
    
    func animateTitle(newTitle: String, fromTop: Bool) {
        // Remove old animation, if necessary.
        if let keys = navigationItem.titleView!.layer.animationKeys() {
            if keys.contains("changeTitle") {
                navigationItem.titleView!.layer.removeAnimation(forKey: "changeTitle")
            }
        }
        let titleAnimation = CATransition()
        titleAnimation.duration = 0.2
        titleAnimation.type = kCATransitionPush
        titleAnimation.subtype = fromTop ? kCATransitionFromTop : kCATransitionFromBottom
        let timing = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        titleAnimation.timingFunction = timing
        navigationItem.titleView!.layer.add(titleAnimation, forKey: "changeTitle")
        
        (navigationItem.titleView as! UILabel).text = newTitle
        //(navigationItem.titleView as! UILabel).sizeToFit()
    }

    func printAllCoreData() {
        Logger.debug("\(months.count) months (not including this one)")
        Logger.debug("\(daysThisMonth.count) days this month")
        
        let monthsFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
        let monthSortDesc = NSSortDescriptor(key: "month_", ascending: true)
        monthsFetchReq.sortDescriptors = [monthSortDesc]
        let allMonths = try! context.fetch(monthsFetchReq)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full

        
        for (index, month) in allMonths.enumerated() {
            Logger.debug("allMonths[\(index)]")

            let humanMonth = dateFormatter.monthSymbols[month.calendarMonth!.month - 1]
            let humanMonthYear = humanMonth + " \(month.calendarMonth!.year)"
            
            let fullDate = month.calendarMonth!.string(formatter: dateFormatter)
            
            Logger.debug("\(humanMonthYear) - \(fullDate)")
            Logger.debug("month.dailyBaseTargetSpend: \(month.dailyBaseTargetSpend!)")
            Logger.debug("month.dateCreated: \(dateFormatter.string(from: month.dateCreated!))")
            Logger.debug("")
            
            if (month.adjustments!.count > 0) {
                Logger.debug("\tMonthAdjustments:")
            } else {
                Logger.debug("\tNo MonthAdjustments.")
            }
            for monthAdjustment in month.sortedAdjustments! {
                let created = dateFormatter.string(from: monthAdjustment.dateCreated!)
                let effective = monthAdjustment.calendarDayEffective!.string(formatter: dateFormatter)
                Logger.debug("\tmonthAdjustment.amount: \(monthAdjustment.amount!)")
                Logger.debug("\tmonthAdjustment.dateCreated: \(created)")
                Logger.debug("\tmonthAdjustment.dateEffective: \(effective)")
                Logger.debug("\tmonthAdjustment.reason: \(monthAdjustment.reason!)")
                Logger.debug("")
            }
            
            
            if (month.days!.count > 0) {
                Logger.debug("\tDays:")
            } else {
                Logger.debug("\tNo Days.")
            }
            for day in month.sortedDays! {
                Logger.debug("\tday.baseTargetSpend: \(day.baseTargetSpend!)")
                Logger.debug("\tday.date: \(day.calendarDay!.string(formatter: dateFormatter))")
                Logger.debug("\tday.dateCreated: \(dateFormatter.string(from: day.dateCreated!))")
                Logger.debug("")
                
                if (day.adjustments!.count > 0) {
                    Logger.debug("\t\tDayAdjustments:")
                } else {
                    Logger.debug("\t\tNo DayAdjustments.")
                }
                for dayAdjustment in day.sortedAdjustments! {
                    let created = dateFormatter.string(from: dayAdjustment.dateCreated!)
                    let affected = dayAdjustment.calendarDayAffected!.string(formatter: dateFormatter)
                    Logger.debug("\t\tdayAdjustment.amount: \(dayAdjustment.amount!)")
                    Logger.debug("\t\tdayAdjustment.dateAffected: \(created)")
                    Logger.debug("\t\tdayAdjustment.dateCreated: \(affected)")
                    Logger.debug("\t\tdayAdjustment.reason: \(dayAdjustment.reason!)")
                    Logger.debug("")
                }
                
                
                if (day.expenses!.count > 0) {
                    Logger.debug("\t\tExpenses:")
                } else {
                    Logger.debug("\t\tNo Expenses.")
                }
                for expense in day.sortedExpenses! {
                    let created = dateFormatter.string(from: expense.dateCreated!)
                    Logger.debug("\t\texpense.amount: \(expense.amount!)")
                    Logger.debug("\t\texpense.dateCreated: \(created)")
                    Logger.debug("\t\texpense.notes: \(expense.notes ?? "")")
                    Logger.debug("\t\texpense.shortDescription: \(expense.shortDescription!)")
                    Logger.debug("")
                    
                    if (expense.images!.count > 0) {
                        Logger.debug("\t\t\tImages:")
                    } else {
                        Logger.debug("\t\t\tNo Images.")
                    }
                    for image in expense.sortedImages! {
                        let created = dateFormatter.string(from: expense.dateCreated!)
                        Logger.debug("\t\t\timage.imageName: \(image.imageName!)")
                        Logger.debug("\t\t\timage.dateCreated: \(created)")
                        Logger.debug("")
                    }
                }
                Logger.debug("")
                
                if let pause = day.pause {
                    Logger.debug("\t\tPause:")
                    let created = dateFormatter.string(from: pause.dateCreated!)
                    let first = pause.firstDayEffective!.string(formatter: dateFormatter)
                    let last = pause.lastDayEffective!.string(formatter: dateFormatter)

                    Logger.debug("\t\tpause.shortDescription: \(pause.shortDescription!)")
                    Logger.debug("\t\tpause.dateCreated: \(created)")
                    Logger.debug("\t\tpause.firstDayEffective: \(first)")
                    Logger.debug("\t\tpause.lastDayEffective: \(last)")
                    Logger.debug("")

                } else {
                    Logger.debug("\t\tNo Pause.")
                }
                Logger.debug("")
            }
            Logger.debug("")
        }
        
        
        let allPauses = Pause.getPauses(context: context)!
        
        Logger.debug("allPauses:")
        Logger.debug("\(allPauses.count) pauses")

        for pause in allPauses {
            
            Logger.debug("\t\tPause:")
            let created = dateFormatter.string(from: pause.dateCreated!)
            let first = pause.firstDayEffective!.string(formatter: dateFormatter)
            let last = pause.lastDayEffective!.string(formatter: dateFormatter)
            
            Logger.debug("\t\tpause.shortDescription: \(pause.shortDescription!)")
            Logger.debug("\t\tpause.dateCreated: \(created)")
            Logger.debug("\t\tpause.firstDayEffective: \(first)")
            Logger.debug("\t\tpause.lastDayEffective: \(last)")
            Logger.debug("")
        }
    }

}
