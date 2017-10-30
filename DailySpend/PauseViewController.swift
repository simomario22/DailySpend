//
//  PauseViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/10/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class PauseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddPauseDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var noPausesLabel: UILabel!
    @IBOutlet weak var noPausesHeading: UILabel!
    
    @IBOutlet weak var toggleButton: UIButton!
    
    var pauses = [Pause]()
    
    var showingAll = false
    
    let noRelevantPausesMessage = "You don't have any current or future " +
        "pauses. View past pauses by tapping the button below, or create a " +
        "new pause above."
    let noPausesMessage = "You don't have any pauses. Create a new pause above."
    let noRelevantPausesHeader = "No Relevant Pauses"
    let noPausesHeader = "No Pauses"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Pauses"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add) {
            let addPauseVC = AddPauseViewController(nibName: nil, bundle: nil)
            addPauseVC.delegate = self
            let navController = UINavigationController(rootViewController: addPauseVC)
            self.present(navController, animated: true, completion: nil)
        }
        self.navigationItem.rightBarButtonItem = addButton
        noPausesLabel.isHidden = true
        infoLabel.isHidden = true
        noPausesHeading.isHidden = true
        noPausesLabel.text = noRelevantPausesMessage
        noPausesHeading.text = noRelevantPausesHeader
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pauses = showingAll ? getAllPauses()! : getRelevantPauses()!
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getRelevantPauses() -> [Pause]? {
        let sortDescriptors = [NSSortDescriptor(key: "lastDateEffective_", ascending: false)]
        let predicate = NSPredicate(format: "lastDateEffective_ >= %@", CalendarDay().gmtDate as CVarArg)
        return Pause.get(context: context, predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func getAllPauses() -> [Pause]? {
        let sortDescriptors = [NSSortDescriptor(key: "lastDateEffective_", ascending: false)]
        return Pause.get(context: context, sortDescriptors: sortDescriptors)
    }
    
    @IBAction func toggleShowingAll(_ sender: UIButton) {
        if showingAll {
            sender.setTitle("Show All Pauses", for: .normal)
            showingAll = false
            let relevantPauses = getRelevantPauses()
            let allPausesCount = pauses.count
            pauses = relevantPauses!
            if pauses.count < allPausesCount {
                var indexPaths = [IndexPath]()
                for row in pauses.count..<allPausesCount {
                    indexPaths.append(IndexPath(row: row, section: 0))
                }
                tableView.deleteRows(at: indexPaths, with: .automatic)
            }
            noPausesLabel.text = noRelevantPausesMessage
            noPausesHeading.text = noRelevantPausesHeader
        } else {
            sender.setTitle("Show Current and Future Pauses", for: .normal)
            showingAll = true
            let allPauses = getAllPauses()
            let relevantPausesCount = pauses.count
            pauses = allPauses!
            if relevantPausesCount < pauses.count {
                var indexPaths = [IndexPath]()
                for row in relevantPausesCount..<pauses.count {
                    indexPaths.append(IndexPath(row: row, section: 0))
                }
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
            noPausesLabel.text = noPausesMessage
            noPausesHeading.text = noPausesHeader
        }
    }
    
    func addedOrChangedPause(_ pause: Pause) {
        if !showingAll && pause.lastDayEffective! < CalendarDay() {
            // The table data will refresh automatically, but make
            // sure the user can see the pause they just added.
            toggleShowingAll(toggleButton)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if pauses.isEmpty {
            noPausesLabel.isHidden = false
            infoLabel.isHidden = false
            noPausesHeading.isHidden = false
        } else {
            noPausesLabel.isHidden = true
            infoLabel.isHidden = true
            noPausesHeading.isHidden = true
        }
        
        return pauses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
        
        let pause = pauses[indexPath.row]
        cell.textLabel!.text = pause.shortDescription
        cell.detailTextLabel!.text = pause.humanReadableRange()

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let addPauseVC = AddPauseViewController()
        addPauseVC.pause = pauses[indexPath.row]
        addPauseVC.delegate = self
        
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController!.pushViewController(addPauseVC, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let pause = pauses.remove(at: indexPath.row)
            context.delete(pause)
            appDelegate.saveContext()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
