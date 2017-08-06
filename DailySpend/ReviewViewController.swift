//
//  ReviewTableViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/31/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

enum ReviewMode {
    case DayAdjustments
    case MonthAdjustments
    case Days
    case Months
}

class ReviewTableViewController: UITableViewController {
    
    var dayAdjustments: [DayAdjustment]?
    var monthAdjustments: [MonthAdjustment]?
    var day: Day?
    var month: Month?
    var mode: ReviewMode?
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        
        switch mode! {
        case .Days:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, M/d"
            self.navigationItem.title = dateFormatter.string(from: day!.date!)
        case .Months:
            let monthName = DateFormatter().monthSymbols[month!.month!.month - 1]
            let monthAndYearName = monthName + " \(month!.month!.year)"

            self.navigationItem.title = monthAndYearName
        case .DayAdjustments,
             .MonthAdjustments:
            self.navigationItem.title = "Adjustments"
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the 
        // navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createExpenseVC() -> ExpenseViewController {
        return ExpenseViewController()
    }
    
    func createReviewVC() -> ReviewTableViewController {
        let id = "Review"
        let vc = storyboard!.instantiateViewController(withIdentifier: id)
        return vc as! ReviewTableViewController
    }
    
    func createDayAdjVC() -> DayAdjustmentViewController {
        let id = "AdjustmentDay"
        let vc = storyboard!.instantiateViewController(withIdentifier: id)
        return vc as! DayAdjustmentViewController
    }
    
    func createMonthAdjVC() -> MonthAdjustmentViewController {
        let id = "AdjustmentMonth"
        let vc = storyboard!.instantiateViewController(withIdentifier: id)
        return vc as! MonthAdjustmentViewController
    }
    
    var dayHasAdjustments: Bool {
        return !(day!.adjustments!.isEmpty &&
                 day!.relevantMonthAdjustments.isEmpty)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        switch mode! {
        case .Days:
            return dayHasAdjustments ? 3 : 2
        case .Months:
            return month!.adjustments!.isEmpty ? 2 : 3
        case .DayAdjustments,
             .MonthAdjustments:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        switch mode! {
        case .Days:
            if section == 0 {
                return 1
            } else if section == 1 {
                return dayHasAdjustments ? 1 : day!.expenses!.count
            } else {
                return day!.expenses!.count
            }
        case .Months:
            if section == 0 {
                return 1
            } else if section == 1 {
                return month!.adjustments!.isEmpty ? month!.days!.count : 1
            } else {
                return month!.days!.count
            }
        case .DayAdjustments:
            return dayAdjustments!.count + monthAdjustments!.count
        case .MonthAdjustments:
            return monthAdjustments!.count
        }
    }

    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        switch mode! {
        case .Days:
            if section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "review",
                                                         for: indexPath)
                let reviewCell = cell as! ReviewTableViewCell
                let isFirstDayOfMonth: Bool = {
                    if day!.date!.day == 1 {
                        // This is the first day of the month.
                        return true
                    }
                    for checkDay in day!.month!.days! {
                        if checkDay.date!.beginningOfDay < day!.date!.beginningOfDay {
                            // There's a day earlier than this one
                            // so this day is not the earliest
                            return false
                        }
                    }
                    // There are no days earlier than this one, so today is 
                    // not the earliest.
                    return true
                }()
                var previousDay: Day?
                if !isFirstDayOfMonth {
                    let date = day!.date!.subtract(days: 1)
                    previousDay = Day.get(context: context, date: date)
                }
                let carryFromYesterday = isFirstDayOfMonth ?
                                         0 : previousDay?.leftToCarry
                let isLastDayOfMonth = day!.date!.day == day!.month!.month!.daysInMonth
                reviewCell.setAndFormatLabels(spentAmount: day!.actualSpend,
                                        goalAmount: day!.fullTargetSpend,
                                        carryFromYesterday: carryFromYesterday,
                                        lastDayOfMonth: isLastDayOfMonth)
                return cell
            } else if section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail",
                                                         for: indexPath)
                if !dayHasAdjustments {
                    let expenses = day!.sortedExpenses!
                    let amount = expenses[row].amount!.doubleValue
                    let primaryText = expenses[row].shortDescription
                    let detailText = String.formatAsCurrency(amount: amount)
                    
                    cell.textLabel!.text = primaryText
                    cell.detailTextLabel!.text = detailText
                } else {
                    let amount = day!.totalAdjustments().doubleValue
                    let primaryText = "Adjustments"
                    let detailText = String.formatAsCurrency(amount: amount)
                    
                    cell.textLabel!.text = primaryText
                    cell.detailTextLabel!.text = detailText
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail",
                                                         for: indexPath)

                let expenses = day!.sortedExpenses!
                let amount = expenses[row].amount!.doubleValue
                let primaryText = expenses[row].shortDescription
                let detailText = String.formatAsCurrency(amount: amount)
                
                cell.textLabel!.text = primaryText
                cell.detailTextLabel!.text = detailText
                
                return cell
            }
        case .Months:
            if section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "review",
                                                         for: indexPath)
                let reviewCell = cell as! ReviewTableViewCell
                reviewCell.setAndFormatLabels(spentAmount: month!.actualSpend,
                                              goalAmount: month!.fullTargetSpend)
                return cell
            } else if section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail",
                                                         for: indexPath)
                if month!.adjustments!.isEmpty {
                    let days = month!.sortedDays!
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "E, M/d"
                    let amount = days[row].actualSpend.doubleValue
                    let primaryText = dateFormatter.string(from: days[row].date!)
                    let detailText = String.formatAsCurrency(amount: amount)
                    cell.textLabel!.text = primaryText
                    cell.detailTextLabel!.text = detailText
                    
                    let neg = days[row].actualSpend > days[row].fullTargetSpend
                    cell.detailTextLabel!.textColor = neg ? redColor : greenColor
                } else {
                    var total: Decimal = 0.0
                    for adjustment in month!.adjustments! {
                        total += adjustment.amount!
                    }
                    cell.textLabel!.text = "Adjustments"
                    
                    let amount = total.doubleValue
                    let detailText = String.formatAsCurrency(amount: amount)
                    cell.detailTextLabel!.text = detailText
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail",
                                                         for: indexPath)
                
                let days = month!.sortedDays!
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "E, M/d"
                let amount = days[row].actualSpend.doubleValue
                let primaryText = dateFormatter.string(from: days[row].date!)
                let detailText = String.formatAsCurrency(amount: amount)
                cell.textLabel!.text = primaryText
                cell.detailTextLabel!.text = detailText
                
                return cell
            }
        case .DayAdjustments:
            if indexPath.row < dayAdjustments!.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail",
                                                         for: indexPath)
                cell.textLabel!.text = dayAdjustments![row].reason
                
                let amount = dayAdjustments![row].amount!.doubleValue
                let detailText = String.formatAsCurrency(amount: amount)
                cell.detailTextLabel!.text = detailText
                return cell
            } else {
                let index = row - dayAdjustments!.count
                let monthAdjustment = monthAdjustments![index]
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail",
                                                         for: indexPath)
                
                let df = DateFormatter()
                let monthName = df.monthSymbols[day!.month!.month!.month - 1]
                cell.textLabel!.text = monthAdjustment.reason! + " (\(monthName))"
                
                // This is the amount of this adjustment that affects this day.
                let daysAcross = day!.date!.daysInMonth -
                                 monthAdjustment.dateEffective!.day + 1
                let applicableAmount = monthAdjustment.amount! / Decimal(daysAcross)
                
                let amount = applicableAmount.doubleValue
                let detailText = String.formatAsCurrency(amount: amount)
                cell.detailTextLabel!.text = detailText
                return cell
            }
        case .MonthAdjustments:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detail",
                                                     for: indexPath)
            cell.textLabel!.text = monthAdjustments![row].reason
            
            let amount = monthAdjustments![row].amount!.doubleValue
            let detailText = String.formatAsCurrency(amount: amount)
            cell.detailTextLabel!.text = detailText
            return cell
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        switch mode! {
        case .Days:
            if indexPath.section == 0 {
                return false
            } else if indexPath.section == 1 {
                return !dayHasAdjustments
            } else {
                return true
            }
        case .Months:
            return false
        case .DayAdjustments:
            return true
        case .MonthAdjustments:
            return true
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch mode! {
            case .Days:
                let expenses = day!.sortedExpenses!
                let expense = expenses[indexPath.row]
                expense.day = nil
                context.delete(expense)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            case .Months:
                fatalError()
            case .DayAdjustments:
                if indexPath.row < dayAdjustments!.count {
                    dayAdjustments![indexPath.row].day = nil
                    context.delete(dayAdjustments![indexPath.row])
                    dayAdjustments!.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                } else {
                    let title = "Deleting Month Adjustment"
                    let message = "This is a month adjustment. Deleting it " +
                        "could affect more days than this one. Would you " +
                        "still like to delete?"
                    let alert = UIAlertController(title: title,
                                                  message: message,
                                                  preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "Cancel",
                                               style: .cancel,
                                               handler: nil)
                    let delete = UIAlertAction(title: "Delete",
                                               style: .destructive,
                                               handler: {(action) in
                        let index = indexPath.row - self.dayAdjustments!.count
                        self.monthAdjustments![index].month = nil
                        self.context.delete(self.monthAdjustments![index])
                        self.monthAdjustments!.remove(at: index)
                        self.tableView.deleteRows(at: [indexPath],
                                                  with: .automatic)
                    })
                    alert.addAction(cancel)
                    alert.addAction(delete)
                    self.present(alert, animated: true, completion: nil)
                }
            case .MonthAdjustments:
                monthAdjustments![indexPath.row].month = nil
                context.delete(monthAdjustments![indexPath.row])
                monthAdjustments!.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            appDelegate.saveContext()
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch mode! {
        case .Days:
            if indexPath.section == 0 {
                return nil
            } else {
                return indexPath
            }
        case .Months:
            if indexPath.section == 0 {
                return nil
            } else {
                return indexPath
            }
        case .DayAdjustments:
            return indexPath
        case .MonthAdjustments:
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        let reviewCellHeight: CGFloat = 146
        let standardCellHeight: CGFloat = 44
        switch mode! {
        case .Days:
            if indexPath.section == 0 {
                return reviewCellHeight
            } else {
                return standardCellHeight
            }
        case .Months:
            if indexPath.section == 0 {
                return reviewCellHeight
            } else {
                return standardCellHeight
            }
        case .DayAdjustments,
             .MonthAdjustments:
            return standardCellHeight
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        switch mode! {
        case .Days:
            if section == 1 {
                if !dayHasAdjustments {
                    let expenseVC = createExpenseVC()
                    let expenses = day!.sortedExpenses!
                    expenseVC.expense = expenses[row]
                    navigationController?.pushViewController(expenseVC, animated: true)
                } else {
                    let reviewVC = createReviewVC()
                    let dayAdj = day!.sortedAdjustments!
                    reviewVC.dayAdjustments = dayAdj
                    reviewVC.monthAdjustments = day!.relevantMonthAdjustments
                    reviewVC.day = day!
                    reviewVC.mode = .DayAdjustments
                    navigationController?.pushViewController(reviewVC, animated: true)
                }
            } else {
                let expenseVC = createExpenseVC()
                let expenses = day!.sortedExpenses!
                expenseVC.expense = expenses[row]
                navigationController?.pushViewController(expenseVC, animated: true)
            }
        case .Months:
            if section == 1 {
                if month!.adjustments!.isEmpty {
                    let reviewVC = createReviewVC()
                    let days = month!.sortedDays!
                    reviewVC.day = days[row]
                    reviewVC.mode = .Days
                    navigationController?.pushViewController(reviewVC, animated: true)
                } else {
                    let reviewVC = createReviewVC()
                    let adjustments = month!.sortedAdjustments!
                    reviewVC.monthAdjustments = adjustments
                    reviewVC.mode = .MonthAdjustments
                    navigationController?.pushViewController(reviewVC, animated: true)
                }
            } else {
                let reviewVC = createReviewVC()
                let days = month!.sortedDays!
                reviewVC.day = days[row]
                reviewVC.mode = .Days
                navigationController?.pushViewController(reviewVC, animated: true)
            }
        case .DayAdjustments:
            if indexPath.row < dayAdjustments!.count {
                let adjustmentVC = createDayAdjVC()
                adjustmentVC.dayAdjustment = dayAdjustments![indexPath.row]
                navigationController?.pushViewController(adjustmentVC, animated: true)
            } else {
                let index = indexPath.row - dayAdjustments!.count
                let adjustmentVC = createMonthAdjVC()
                adjustmentVC.monthAdjustment = monthAdjustments![index]
                navigationController?.pushViewController(adjustmentVC, animated: true)
            }
        case .MonthAdjustments:
            let adjustmentVC = createMonthAdjVC()
            adjustmentVC.monthAdjustment = monthAdjustments![indexPath.row]
            navigationController?.pushViewController(adjustmentVC, animated: true)
        }
    }
}
