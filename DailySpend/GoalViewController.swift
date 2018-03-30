//
//  GoalsViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/2/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class GoalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddGoalDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    var tableView: UITableView!
    var currentGoals: [Goal] = []
    var archivedGoals: [Goal] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setGoals()
        tableView = UITableView(frame: view.frame, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        navigationItem.title = "Goals"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, {
            self.dismiss(animated: true, completion: nil)
        })
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, {
            let vc = AddGoalViewController(nibName: nil, bundle: nil)
            vc.delegate = self
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setGoals()
        tableView.reloadData()
    }
    
    func setGoals() {
        let sortDescriptors = [NSSortDescriptor(key: "dateCreated_", ascending: true)]
        let goals = Goal.get(context: context, sortDescriptors: sortDescriptors) ?? []
        currentGoals = goals.filter({ !$0.archived })
        archivedGoals = goals.filter({ $0.archived })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "goal")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "goal")
        }
        
        let goals = indexPath.section == 1 ? archivedGoals : currentGoals
        cell.textLabel?.text = goals[indexPath.row].shortDescription

        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return !archivedGoals.isEmpty ? "Archived" : nil
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = AddGoalViewController(nibName: nil, bundle: nil)
        let goals = indexPath.section == 1 ? archivedGoals : currentGoals
        vc.goal = goals[indexPath.row]
        vc.delegate = self
        
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var goals = indexPath.section == 1 ? archivedGoals : currentGoals
            let goal = goals.remove(at: indexPath.row)
            context.delete(goal)
            appDelegate.saveContext()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func addedOrChangedGoal(_ goal: Goal) {
        
    }

}