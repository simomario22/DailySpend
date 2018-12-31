//
//  AdjustmentViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/10/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class AdjustmentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddAdjustmentDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var noAdjustmentsLabel: UILabel!
    @IBOutlet weak var noAdjustmentsHeading: UILabel!
    
    @IBOutlet weak var toggleButton: UIButton!
    
    var adjustments = [Adjustment]()
    
    var showingAll = false
    
    let noRelevantAdjustmentsMessage = "You don't have any current or future " +
        "adjustments. View all your adjustments by tapping the button below."
    let noAdjustmentsMessage = "You don't have any adjustments. Create a new " +
        "adjustment above."
    let noRelevantAdjustmentsHeader = "No Relevant Adjustments"
    let noAdjustmentsHeader = "No Adjustments"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Adjustments"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add) {
            let addAdjustmentVC = AddAdjustmentViewController(nibName: nil, bundle: nil)
            addAdjustmentVC.delegate = self
            let navController = UINavigationController(rootViewController: addAdjustmentVC)
            self.present(navController, animated: true, completion: nil)
        }
        self.navigationItem.rightBarButtonItem = addButton
        noAdjustmentsLabel.isHidden = true
        infoLabel.isHidden = true
        noAdjustmentsHeading.isHidden = true
        noAdjustmentsLabel.text = noRelevantAdjustmentsMessage
        noAdjustmentsHeading.text = noRelevantAdjustmentsHeader
    }
    
    override func viewWillAppear(_ animated: Bool) {
        adjustments = showingAll ? getAllAdjustments()! : getRelevantAdjustments()!
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getRelevantAdjustments() -> [Adjustment]? {
        let sortDescriptors = [NSSortDescriptor(key: "lastDateEffective_", ascending: false)]
        let predicate = NSPredicate(format: "lastDateEffective_ >= %@", CalendarDay().start.gmtDate as CVarArg)
        return Adjustment.get(context: context, predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func getAllAdjustments() -> [Adjustment]? {
        let sortDescriptors = [NSSortDescriptor(key: "lastDateEffective_", ascending: false)]
        return Adjustment.get(context: context, sortDescriptors: sortDescriptors)
    }
    
    @IBAction func toggleShowingAll(_ sender: UIButton) {
        if showingAll {
            sender.setTitle("Show All Adjustments", for: .normal)
            showingAll = false
            let relevantAdjustments = getRelevantAdjustments()
            let allAdjustmentsCount = adjustments.count
            adjustments = relevantAdjustments!
            if adjustments.count < allAdjustmentsCount {
                var indexPaths = [IndexPath]()
                for row in adjustments.count..<allAdjustmentsCount {
                    indexPaths.append(IndexPath(row: row, section: 0))
                }
                tableView.deleteRows(at: indexPaths, with: .fade)
            }
            noAdjustmentsLabel.text = noRelevantAdjustmentsMessage
            noAdjustmentsHeading.text = noRelevantAdjustmentsHeader
        } else {
            sender.setTitle("Show Current and Future Adjustments", for: .normal)
            showingAll = true
            let allAdjustments = getAllAdjustments()
            let relevantAdjustmentsCount = adjustments.count
            adjustments = allAdjustments!
            if relevantAdjustmentsCount < adjustments.count {
                var indexPaths = [IndexPath]()
                for row in relevantAdjustmentsCount..<adjustments.count {
                    indexPaths.append(IndexPath(row: row, section: 0))
                }
                tableView.insertRows(at: indexPaths, with: .fade)
            }
            noAdjustmentsLabel.text = noAdjustmentsMessage
            noAdjustmentsHeading.text = noAdjustmentsHeader
        }
    }
    
    func addedOrChangedAdjustment(_ adjustment: Adjustment) {
        if !showingAll && adjustment.lastDayEffective! < CalendarDay() {
            // The table data will refresh automatically, but make
            // sure the user can see the adjustment they just added.
            toggleShowingAll(toggleButton)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if adjustments.isEmpty {
            noAdjustmentsLabel.isHidden = false
            infoLabel.isHidden = false
            noAdjustmentsHeading.isHidden = false
        } else {
            noAdjustmentsLabel.isHidden = true
            infoLabel.isHidden = true
            noAdjustmentsHeading.isHidden = true
        }
        
        return adjustments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
        
        let adjustment = adjustments[indexPath.row]
        cell.textLabel!.text = adjustment.shortDescription
        
        // Format the dates like 3/6 or 3/6/16.
        let thisYear = CalendarDay().year
        let dateFormatter = DateFormatter()
        if adjustment.firstDayEffective!.year == thisYear &&
            adjustment.lastDayEffective!.year == thisYear {
            dateFormatter.dateFormat = "M/d"
        } else {
            dateFormatter.dateFormat = "M/d/yy"
        }
        
        let firstDay = adjustment.firstDayEffective!.string(formatter: dateFormatter)
        if adjustment.firstDayEffective! == adjustment.lastDayEffective! {
            cell.detailTextLabel!.text = "\(firstDay)"
        } else {
            let lastDay = adjustment.lastDayEffective!.string(formatter: dateFormatter)
            cell.detailTextLabel!.text = "\(firstDay) - \(lastDay)"
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let addAdjustmentVC = AddAdjustmentViewController()
        addAdjustmentVC.adjustment = adjustments[indexPath.row]
        addAdjustmentVC.delegate = self
        
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController!.pushViewController(addAdjustmentVC, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let adjustment = adjustments.remove(at: indexPath.row)
            context.delete(adjustment)
            appDelegate.saveContext()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
