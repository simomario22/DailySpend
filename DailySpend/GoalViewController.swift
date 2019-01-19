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

    var delegate: GoalViewControllerDelegate?
    var tableView: UITableView!
    var currentGoals: [Goal.IndentedGoal] = []
    var archivedGoals: [Goal.IndentedGoal] = []
    var futureStartGoals: [Goal.IndentedGoal] = []
    var changes = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setGoals()
        tableView = UITableView(frame: view.frame, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        navigationItem.title = "Goals"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, {
            if self.changes {
                self.delegate?.goalControllerWillDismissWithChangedGoals()
            }
            self.dismiss(animated: true, completion: nil)
        })
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, {
            let vc = AddGoalViewController(nibName: nil, bundle: nil)
            vc.delegate = self
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
        })
    }
    
    func setGoals() {
        let context = appDelegate.persistentContainer.viewContext
        currentGoals = Goal.getIndentedGoals(context: context, excludeGoal: { $0.isArchived || $0.hasFutureStart })
        futureStartGoals = Goal.getIndentedGoals(context: context, excludeGoal: { !$0.hasFutureStart } )
        archivedGoals = Goal.getIndentedGoals(context: context, excludeGoal: { !$0.isArchived })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private enum GoalViewSectionType {
        case CurrentGoalsSection
        case FutureStartGoalsSection
        case ArchivedGoalsSection
    }
    
    private func sectionForSectionIndex(_ section: Int) -> GoalViewSectionType {
        switch section {
        case 0:
            if !currentGoals.isEmpty {
                return .CurrentGoalsSection
            } else if !futureStartGoals.isEmpty {
                return .FutureStartGoalsSection
            } else {
                return .ArchivedGoalsSection
            }
        case 1:
            if !futureStartGoals.isEmpty {
                return .FutureStartGoalsSection
            } else {
                return .ArchivedGoalsSection
            }
        case 2:
            return .ArchivedGoalsSection
        default:
            return .CurrentGoalsSection
        }
    }
    
    private func goalsForSection(_ section: Int) -> [Goal.IndentedGoal] {
        switch sectionForSectionIndex(section) {
        case .CurrentGoalsSection:
            return currentGoals
        case .FutureStartGoalsSection:
            return futureStartGoals
        case .ArchivedGoalsSection:
            return archivedGoals
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "goal")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "goal")
        }

        cell.accessoryType = .detailButton
        
        let goals = goalsForSection(indexPath.section)
        let section = sectionForSectionIndex(indexPath.section)
        
        if section == .CurrentGoalsSection {
            cell.indentationLevel = goals[indexPath.row].indentation
        } else {
            cell.indentationLevel = 0
        }
        cell.textLabel?.text = goals[indexPath.row].goal.shortDescription

        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sectionForSectionIndex(section) {
        case .FutureStartGoalsSection:
            return "Future Start"
        case .ArchivedGoalsSection:
            return "Archived"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionForSectionIndex(section) {
        case .CurrentGoalsSection:
            return currentGoals.count
        case .FutureStartGoalsSection:
            return futureStartGoals.count
        case .ArchivedGoalsSection:
            return archivedGoals.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 1
        if !archivedGoals.isEmpty {
            sections += 1
        }
        if !futureStartGoals.isEmpty {
            sections += 1
        }
        return sections
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = AddGoalViewController(nibName: nil, bundle: nil)
        let goals = goalsForSection(indexPath.section)
        vc.goalId = goals[indexPath.row].goal.objectID
        vc.delegate = self
        
        let navController = UINavigationController(rootViewController: vc)
        tableView.deselectRow(at: indexPath, animated: true)
        self.present(navController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        self.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let goal = goalsForSection(indexPath.section)[indexPath.row].goal

            let title = "Delete \(goal.shortDescription!)?"
            var message = "Are you sure you want to delete \(goal.shortDescription!)? All associated expenses and other attatched data will be deleted."
            if !(goal.childGoals?.isEmpty ?? true) {
                 message += " Child goals will become top level goals and retain their data."
            }
            let deleteConfirmation = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            deleteConfirmation.addActions([
                UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                    self.deleteGoal(indexPath: indexPath)
                }),
                UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            ])
            self.present(deleteConfirmation, animated: true, completion: nil)
        }
    }

    private func deleteGoal(indexPath: IndexPath) {
        let context = appDelegate.persistentContainer.newBackgroundContext()

        var children = 0
        context.performAndWait {
            var goal: Goal
            switch sectionForSectionIndex(indexPath.section) {
            case .CurrentGoalsSection:
                goal = Goal.inContext(currentGoals.remove(at: indexPath.row).goal, context: context)!
                children = goal.childGoals?.count ?? 0
            case .FutureStartGoalsSection:
                goal = Goal.inContext(futureStartGoals.remove(at: indexPath.row).goal, context: context)!
            case .ArchivedGoalsSection:
                goal = Goal.inContext(archivedGoals.remove(at: indexPath.row).goal, context: context)!
            }

            context.delete(goal)
            self.changes = true
            try! context.save()
        }

        var childPaths = [IndexPath]()

        let row = indexPath.row
        for i in row + 1..<row + 1 + children {
            // This will only run if children > 0
            currentGoals[i - 1].indentation -= 1
            childPaths.append(IndexPath(row: i, section: indexPath.section))
            appDelegate.persistentContainer.viewContext.refresh(currentGoals[i - 1].goal, mergeChanges: true)
        }

        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .fade)
        tableView.reloadRows(at: childPaths, with: .fade)
        tableView.endUpdates()
    }
    
    func addedOrChangedGoal(_ goal: Goal) {
        changes = true
        setGoals()
        tableView.reloadData()
    }
}

protocol GoalViewControllerDelegate {
    func goalControllerWillDismissWithChangedGoals()
}
