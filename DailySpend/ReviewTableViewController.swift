//
//  ReviewTableViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/31/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

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
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let redColor = UIColor(colorLiteralRed: 179.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1)
    let greenColor = UIColor(colorLiteralRed: 0.0/255.0, green: 179.0/255.0, blue: 0.0/255.0, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        switch mode! {
        case .Days:
            return day!.adjustments!.isEmpty ? 2 : 3
        case .Months:
            return month!.adjustments!.isEmpty ? 2 : 3
        case .DayAdjustments,
             .MonthAdjustments:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch mode! {
        case .Days:
            if section == 0 {
                return 1
            } else if section == 1 {
                return day!.adjustments!.isEmpty ? day!.expenses!.count : 1
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
            return dayAdjustments!.count
        case .MonthAdjustments:
            return monthAdjustments!.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        switch mode! {
        case .Days:
            if section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "review", for: indexPath) as! ReviewTableViewCell
                cell.setAndFormatLabels(spentAmount: day!.actualSpend, goalAmount: day!.fullTargetSpend)
                return cell
            } else if section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
                if day!.adjustments!.isEmpty {
                    let expenses = day!.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
                    cell.textLabel!.text = expenses[row].shortDescription
                    cell.detailTextLabel!.text = String.formatAsCurrency(amount: expenses[row].amount!.doubleValue)
                } else {
                    var total: Decimal = 0.0
                    for adjustment in day!.adjustments! {
                        total += adjustment.amount!
                    }
                    cell.textLabel!.text = "Adjustments"
                    cell.detailTextLabel!.text = String(describing: total)
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)

                let expenses = day!.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
                cell.textLabel!.text = expenses[row].shortDescription
                cell.detailTextLabel!.text = String(describing: expenses[row].amount)
                
                return cell
            }
        case .Months:
            if section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "review", for: indexPath) as! ReviewTableViewCell
                cell.setAndFormatLabels(spentAmount: month!.actualSpend, goalAmount: month!.fullTargetSpend)
                return cell
            } else if section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
                if month!.adjustments!.isEmpty {
                    let days = month!.days!.sorted(by: { $0.date! < $1.date! })
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "E, M/d"
                    cell.textLabel!.text = dateFormatter.string(from: days[row].date!)
                    cell.detailTextLabel!.text = String.formatAsCurrency(amount: days[row].actualSpend.doubleValue)
                    
                    if days[row].actualSpend > days[row].fullTargetSpend {
                        cell.detailTextLabel!.textColor = redColor
                    } else {
                        cell.detailTextLabel!.textColor = greenColor
                    }
                } else {
                    var total: Decimal = 0.0
                    for adjustment in month!.adjustments! {
                        total += adjustment.amount!
                    }
                    cell.textLabel!.text = "Adjustments"
                    cell.detailTextLabel!.text = String(describing: total)
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
                
                let days = month!.days!.sorted(by: { $0.date! < $1.date! })
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "E, M/d"
                cell.textLabel!.text = dateFormatter.string(from: days[row].date!)
                cell.detailTextLabel!.text = String.formatAsCurrency(amount: days[row].actualSpend.doubleValue)
                
                return cell
            }
        case .DayAdjustments:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
            cell.textLabel!.text = dayAdjustments![row].reason
            cell.detailTextLabel!.text = String(describing: dayAdjustments![row].amount)
            return cell
        case .MonthAdjustments:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
            cell.textLabel!.text = monthAdjustments![row].reason
            cell.detailTextLabel!.text = String(describing: monthAdjustments![row].amount)
            return cell
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch mode! {
        case .Days:
            if indexPath.section == 0 {
                return false
            } else if indexPath.section == 1 {
                return day!.adjustments!.isEmpty
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch mode! {
            case .Days:
                let expenses = day!.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
                let expense = expenses[indexPath.row]
                expense.day = nil
                context.delete(expense)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            case .Months:
                fatalError()
            case .DayAdjustments:
                dayAdjustments![indexPath.row].day = nil
                context.delete(dayAdjustments![indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .automatic)
            case .MonthAdjustments:
                monthAdjustments![indexPath.row].month = nil
                context.delete(monthAdjustments![indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            appDelegate.saveContext()
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        switch mode! {
        case .Days:
            if section == 1 {
                if day!.adjustments!.isEmpty {
                    let expenseVC = storyboard!.instantiateViewController(withIdentifier: "Expense") as! ExpenseViewController
                    let expenses = day!.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
                    expenseVC.expense = expenses[row]
                    navigationController?.pushViewController(expenseVC, animated: true)
                } else {
                    let reviewVC = storyboard!.instantiateViewController(withIdentifier: "Review") as! ReviewTableViewController
                    let adjustments = day!.adjustments!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
                    reviewVC.dayAdjustments = adjustments
                    reviewVC.mode = .DayAdjustments
                    navigationController?.pushViewController(reviewVC, animated: true)
                }
            } else {
                let expenseVC = storyboard!.instantiateViewController(withIdentifier: "Expense") as! ExpenseViewController
                let expenses = day!.expenses!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
                expenseVC.expense = expenses[row]
                navigationController?.pushViewController(expenseVC, animated: true)
            }
        case .Months:
            if section == 1 {
                if month!.adjustments!.isEmpty {
                    let reviewVC = storyboard!.instantiateViewController(withIdentifier: "Review") as! ReviewTableViewController
                    let days = month!.days!.sorted(by: { $0.date! < $1.date! })
                    reviewVC.day = days[row]
                    reviewVC.mode = .Days
                    navigationController?.pushViewController(reviewVC, animated: true)
                } else {
                    let reviewVC = storyboard!.instantiateViewController(withIdentifier: "Review") as! ReviewTableViewController
                    let adjustments = month!.adjustments!.sorted(by: { $0.dateCreated! < $1.dateCreated! })
                    reviewVC.monthAdjustments = adjustments
                    reviewVC.mode = .MonthAdjustments
                    navigationController?.pushViewController(reviewVC, animated: true)
                }
            } else {
                let reviewVC = storyboard!.instantiateViewController(withIdentifier: "Review") as! ReviewTableViewController
                let days = month!.days!.sorted(by: { $0.date! < $1.date! })
                reviewVC.day = days[row]
                reviewVC.mode = .Days
                navigationController?.pushViewController(reviewVC, animated: true)
            }
        case .DayAdjustments:
            let adjustmentVC = storyboard!.instantiateViewController(withIdentifier: "AdjustmentDay") as! DayAdjustmentViewController
            adjustmentVC.dayAdjustment = dayAdjustments![indexPath.row]
            navigationController?.pushViewController(adjustmentVC, animated: true)
        case .MonthAdjustments:
            let adjustmentVC = storyboard!.instantiateViewController(withIdentifier: "AdjustmentMonth") as! MonthAdjustmentViewController
            adjustmentVC.monthAdjustment = monthAdjustments![indexPath.row]
            navigationController?.pushViewController(adjustmentVC, animated: true)
        }
    }
}
