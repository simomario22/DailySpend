//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/6/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController : UITableViewController {
    let standardCellHeight = 44
    let currentDayHeight = 115
    let addExpenseHeight = 213
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var daysThisMonth: [Day] = []
    var months: [Month] = []
    
    // Required for unwind segue
    @IBAction override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    
    func totalAdjustments(day: Day) -> Double {
        var total: Double = 0
        for dayAdjustment in day.adjustments as! Set<DayAdjustment> {
            total += dayAdjustment.amount
        }
        
        for monthAdjustment in day.month?.adjustments as! Set<MonthAdjustment> {
            let date = day.date! as Date
            let dateEffective = monthAdjustment.dateEffective! as Date
            if date > dateEffective  {
                // This affects this day.
                let daysAcross = date.daysInMonth - dateEffective.day + 1
                // This is the amount of this adjustment that effects this day.
                total += monthAdjustment.amount / Double(daysAcross)
            }
        }
        return total
    }
    
    func totalAdjustments(month: Month) -> Double {
        var total: Double = 0
        for monthAdjustment in month.adjustments as! Set<MonthAdjustment> {
            total += monthAdjustment.amount
        }
        
        for day in month.days as! Set<Day> {
            for dayAdjustment in day.adjustments as! Set<DayAdjustment> {
                total += dayAdjustment.amount
            }
        }
        return total
    }
    
    /*
     * Return the month object that a day is in, or nil if it doesn't exist.
     */
    func getMonth(dateInMonth day: Date) -> Month? {
        let month = day.month
        let year = day.year
        // Fetch all months equal to the month and year
        let fetchRequest: NSFetchRequest<Month> = Month.fetchRequest()
        fetchRequest.predicate =
            NSCompoundPredicate(type: .and,
                                subpredicates: [NSPredicate(format: "month == %d, ", month),
                                                NSPredicate(format: "year == %d, ", year)])
        var monthResults: [Month] = []
        monthResults = try! context.fetch(fetchRequest)
        if monthResults.count < 1 {
            // No month exists.
            return nil
        } else if monthResults.count > 1 {
            // Multiple months exist.
            fatalError("Error: multiple months exist for \(month)/\(year)")
        }
        return monthResults[0]
    }
    
    /*
     * Present the review dialog for a given month.
     */
    func reviewMonth(_ month: Month, completion: (() -> Void)?) {
        let storyboard = UIStoryboard(name: "MainStoryboard", bundle: nil)
        let navController = storyboard.instantiateViewController(withIdentifier: "ReviewMonth") as! UINavigationController
        let viewController = navController.visibleViewController as! ReviewMonthViewController
        
        
        let goal = month.targetSpend + totalAdjustments(month: month)
        viewController.setAndFormatLabels(spentAmount: month.actualSpend,
                                          goalAmount: goal,
                                          underOverAmount: goal - month.actualSpend,
                                          dayInMonth: month.month! as Date)
        
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .coverVertical
        self.present(viewController, animated: true, completion: completion)
    }
    
    /*
     * Create and return a month.
     */
    func createMonth(dateInMonth date: Date) -> Month {
        let dailySpend = UserDefaults.standard.double(forKey: "dailyTargetSpend")
        
        let month = Month(context: context)
        month.month = date as NSDate?
        month.daysInMonth = Int64(date.daysInMonth)
        month.baseDailyTargetSpend = dailySpend
        month.targetSpend = month.baseDailyTargetSpend * Double(month.daysInMonth)
        month.actualSpend = 0
        
        return month
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
            if let month = getMonth(dateInMonth: currentDate) {
                // Create the day
                let day = Day(context: context)
                day.date = currentDate as NSDate
                day.month = month
                day.baseTargetSpend = day.month!.baseDailyTargetSpend
                day.actualSpend = 0
                
                currentDate = currentDate.add(days: 1)
            } else {
                // This month doesn't yet exist.
                // Create and review the previous month, then call this function again.
                _ = createMonth(dateInMonth: currentDate)
                reviewMonth(getMonth(dateInMonth: currentDate.subtract(months: 1))!, completion: {
                    self.createDays(from: currentDate, to: to)
                })
            }

        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Spending"
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "currentDay", for: indexPath)
        }
        else if indexPath.row == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "addExpense", for: indexPath)
        } else {
            return UITableViewCell()
        }
        
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let topHeight = UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.frame.height
        let windowFrameHeight = tableView.frame.height
        let visibleHeight = windowFrameHeight - topHeight;
        return 44;
        
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}
