//
//  GoalSelectorViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 8/4/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class GoalSelectorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    private struct IndentedGoal {
        var goal: Goal
        var indentation: Int
        init(_ goal: Goal, _ indentation: Int) {
            self.goal = goal
            self.indentation = indentation
        }
    }
    
    private var tableView: UITableView!
    private var cellCreator: TableViewCellHelper!
    private var goals: [IndentedGoal]!
    private var selectedGoalIndices = Set<IndexPath>()
    
    var allowMultipleSelection = true
    var initiallySelectedGoals = Set<Goal>()
    var excludedGoals = Set<Goal>()
    var delegate: GoalSelectorDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Select Goals"
        
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        cellCreator = TableViewCellHelper(tableView: tableView)
        
        guard let topLevelGoals = Goal.get(
            context: context,
            predicate: NSPredicate(format: "parentGoal_ == nil"),
            sortDescriptors: [NSSortDescriptor(key: "shortDescription_", ascending: true)]
        ) else {
            return
        }
        
        goals = makeIndentedGoals(children: topLevelGoals, indentation: 0)
        
        for (i, indentedGoal) in goals.enumerated() {
            if initiallySelectedGoals.contains(indentedGoal.goal) {
                selectedGoalIndices.insert(IndexPath(row: i, section: 0))
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        var selectedGoals = Set<Goal>()
        for indexPath in selectedGoalIndices {
            selectedGoals.insert(goals[indexPath.row].goal)
        }
        delegate?.dismissedGoalSelectorWithSelectedGoals(selectedGoals)
    }
    
    /**
     * Recurses into goals to create a set of goals with proper
     * indentation levels, based on their place in the hierarchy.
     * - Parameters:
     *    - children: Child goals to be made into indented goals
     *    - indentation: The level of indentation fo assign to each passed child
     * - Returns: An array of sorted goals and their children, excluding goals
                  that are in the excludedGoals set
     */
    private func makeIndentedGoals(children: [Goal]?, indentation: Int) -> [IndentedGoal] {
        return children?.flatMap({ childGoal -> [IndentedGoal] in
            if excludedGoals.contains(childGoal) {
                return []
            }
            let children = makeIndentedGoals(children: childGoal.sortedChildGoals, indentation: indentation + 1)
            return [IndentedGoal(childGoal, indentation)] + children
        }) ?? []
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let indentedGoal = goals[indexPath.row]
        return cellCreator.indentedLabelCell(
            labelText: indentedGoal.goal.shortDescription!,
            indentationLevel: indentedGoal.indentation,
            selected: selectedGoalIndices.contains(indexPath)
        )
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var rowsToReload = [IndexPath]()
        
        func insertWithParents(row: Int) {
            var candidateRow = row
            while goals[candidateRow].indentation > 0 {
                let indexPath = IndexPath(row: candidateRow, section: 0)
                selectedGoalIndices.insert(indexPath)
                rowsToReload.append(indexPath)
                candidateRow -= 1
            }
            // Need to do one more, since 0 is still in the tree.
            let indexPath = IndexPath(row: candidateRow, section: 0)
            selectedGoalIndices.insert(indexPath)
            rowsToReload.append(indexPath)
        }
        
        func removeWithChildren(row: Int) {
            // Remove first one, regardless of whether it's 0.
            let indexPath = IndexPath(row: row, section: 0)
            selectedGoalIndices.remove(indexPath)
            rowsToReload.append(indexPath)

            var candidateRow = row + 1
            while candidateRow < goals.count && goals[candidateRow].indentation > 0 {
                let indexPath = IndexPath(row: candidateRow, section: 0)
                selectedGoalIndices.remove(indexPath)
                rowsToReload.append(indexPath)
                candidateRow += 1
            }
        }
        
        if !allowMultipleSelection {
            rowsToReload.append(contentsOf: selectedGoalIndices)
            selectedGoalIndices.removeAll()
            insertWithParents(row: indexPath.row)
        } else {
            if selectedGoalIndices.contains(indexPath) {
                removeWithChildren(row: indexPath.row)
            } else {
                insertWithParents(row: indexPath.row)
            }
        }

        tableView.reloadRows(at: rowsToReload, with: .fade)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }
}

protocol GoalSelectorDelegate {
    func dismissedGoalSelectorWithSelectedGoals(_ goals: Set<Goal>)
}