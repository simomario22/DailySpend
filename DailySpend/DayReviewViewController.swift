//
//  DayReviewViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 10/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class DayReviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    var adjustments: [(desc: String, amount: String)]!
    var expenses: [(desc: String, amount: String)]!
    var formattedPause: (desc: String, range: String)?
    
    var reviewCell: ReviewTableViewCell!
    
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustments = day.sortedAdjustments?.map { adj in
            let formattedAmount = String.formatAsCurrency(amount: adj.amountPerDay!)!
            return (desc: adj.shortDescription!, amount: formattedAmount)
        } ?? []
        
        expenses = day.sortedExpenses?.map { exp in
            let formattedAmount = String.formatAsCurrency(amount: exp.amount!)!
            return (desc: exp.shortDescription!, amount: formattedAmount)
        } ?? []
        
        if let pause = day.pause {
            formattedPause = (desc: pause.shortDescription!, range: pause.humanReadableRange())
        }
        
        reviewCell = ReviewTableViewCell(style: .default, reuseIdentifier: nil)
        
        var reviewCellData = [ReviewCellDatum]()
        let yesterday = Day.get(context: context, calDay: day.calendarDay!.subtract(days: 1))
        let carriedFromYesterday = yesterday?.leftToCarry() ?? 0
        let formattedYesterdayCarry = String.formatAsCurrency(amount: carriedFromYesterday)!
        
        reviewCellData.append(ReviewCellDatum(description: "Yesterday's Balance",
                                              value: formattedYesterdayCarry,
                                              color: carriedFromYesterday < 0 ? .overspent : .black,
                                              sign: .None))
        
        if !adjustments.isEmpty {
            let totalAdjustments = day.totalAdjustments()
            let formattedAdjustments = String.formatAsCurrency(amount: totalAdjustments)!
            reviewCellData.append(ReviewCellDatum(description: "Adjustments",
                                                  value: formattedAdjustments,
                                                  color: .black,
                                                  sign: totalAdjustments < 0 ? .Minus : .Plus))
        }
        
        if !expenses.isEmpty {
            let totalExpenses = day.totalExpenses()
            let formattedExpenses = String.formatAsCurrency(amount: totalExpenses)!
            reviewCellData.append(ReviewCellDatum(description: "Expenses",
                                                  value: formattedExpenses,
                                                  color: .black,
                                                  sign: totalExpenses < 0 ? .Minus : .Plus))
        }
        
        // day.leftToCarry() takes into account pauses, but it'll have to
        // recalculate yesterday's carry, which we already have, so just use
        // that.
        let leftToCarry = day.pause == nil ? day.leftToCarry() : carriedFromYesterday
        let formattedCarry = String.formatAsCurrency(amount: leftToCarry)!
        reviewCellData.append(ReviewCellDatum(description: "Today's Balance",
                                              value: formattedCarry,
                                              color: leftToCarry < 0 ? .overspent : .black,
                                              sign: .None))
        if day.pause != nil {
            reviewCell.showPausedNote(true)
        }
        reviewCell.setLabelData(reviewCellData)
        
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    enum DayReviewCellType {
        case ReviewCell
        case PauseCell
        case AdjustmentCell
        case ExpenseCell
    }
    
    func cellTypeForSection(_ section: Int) -> DayReviewCellType {
        if section == 1 {
            if day.pause != nil {
                return .PauseCell
            } else if !adjustments.isEmpty {
                return .AdjustmentCell
            } else {
                return .ExpenseCell
            }
        }
        
        if section == 2 {
            if !adjustments.isEmpty {
                return .AdjustmentCell
            } else {
                return .ExpenseCell
            }
        }
        
        if section == 3 {
            return .ExpenseCell
        }
        
        return .ReviewCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "value")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "value")
        }
        cell.detailTextLabel?.textColor = UIColor.black
        
        switch cellTypeForSection(indexPath.section) {
        case .ReviewCell:
            return reviewCell
        case .PauseCell:
            cell.textLabel!.text = formattedPause!.desc
            cell.detailTextLabel!.text = formattedPause!.range
        case .AdjustmentCell:
            cell.textLabel!.text = adjustments[indexPath.row].desc
            cell.detailTextLabel!.text = adjustments[indexPath.row].amount
        case .ExpenseCell:
            cell.textLabel!.text = expenses[indexPath.row].desc
            cell.detailTextLabel!.text = expenses[indexPath.row].amount
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch cellTypeForSection(section) {
        case .PauseCell:
            return "Pause"
        case .AdjustmentCell:
            return "Adjustments"
        case .ExpenseCell:
            return "Expenses"
        case .ReviewCell:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch cellTypeForSection(indexPath.section) {
        case .ReviewCell:
            return reviewCell.desiredHeightForCurrentState()
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch cellTypeForSection(section) {
        case .PauseCell:
            return 1
        case .AdjustmentCell:
            return adjustments.count
        case .ExpenseCell:
            return expenses.count
        case .ReviewCell:
            return 1
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 +
            (day.pause == nil ? 0 : 1) +
            (adjustments.isEmpty ? 0 : 1) +
            (expenses.isEmpty ? 0 : 1)
    }
    
}
