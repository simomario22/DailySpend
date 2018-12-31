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
    
    private var tableView: UITableView!
    private var cellCreator: TableViewCellHelper!
    private var goals: [Goal.IndentedGoal]!
    private var showHelperText = false
    private var selectedGoal: Goal?
    private var selectedIndex: IndexPath?
    func setSelectedGoal(goal: Goal?) {
        selectedGoal = goal
    }
    
    var parentSelectionHelperText: String?
    var showParentSelection = true
    var initiallySelectedGoal: Goal?
    var excludedGoals = Set<Goal>()
    var delegate: GoalSelectorDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Select Goal"
        
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        cellCreator = TableViewCellHelper(tableView: tableView)
        
        goals = Goal.getIndentedGoals(context: context, excludedGoals: excludedGoals)
        for (i, indentedGoal) in goals.enumerated() {
            if parentSelectionHelperText != nil && indentedGoal.indentation > 0 {
                showHelperText = true
            }
            if indentedGoal.goal == selectedGoal {
                selectedIndex = IndexPath(row: i, section: 0)
            }
        }
        
        if selectedGoal != nil && selectedIndex == nil {
            // We couldn't find the selected goal, so just disable the
            // selected index.
            Logger.warning("Could not find the selected goal in the available goals.")
            selectedIndex = nil
        }
        
        if goals.isEmpty {
            let text = "No goals available."
            let font = UIFont.systemFont(ofSize: 17)
            let sideMargin: CGFloat = 10
            let statusBarSize = UIApplication.shared.statusBarFrame.size
            let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
            let navBarHeight = navigationController?.navigationBar.frame.size.height ?? 0
            let topMargin: CGFloat = statusBarHeight + navBarHeight + 30
            let width = view.bounds.size.width - sideMargin * 2
            let height = text.calculatedHeightForWidth(width, font: font)
            let labelFrame = CGRect(
                x: sideMargin,
                y: topMargin,
                width: width,
                height: height
            )
            let label = UILabel(frame: labelFrame)
            label.text = text
            label.font = font
            label.textColor = UIColor(red255: 128, green: 128, blue: 128)
            label.numberOfLines = 0
            label.textAlignment = .center
            self.view.addSubview(label)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        delegate?.dismissedGoalSelectorWithSelectedGoal(selectedGoal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let indentedGoal = goals[indexPath.row]
        let goal = indentedGoal.goal
        
        let selected =
            selectedGoal == goal ||
            (
                showParentSelection &&
                selectedGoal != nil &&
                goal.isParentOf(goal: selectedGoal!)
            )
        return cellCreator.indentedLabelCell(
            labelText: goal.shortDescription!,
            indentationLevel: indentedGoal.indentation,
            selected: selected
        )
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return showHelperText ? parentSelectionHelperText : nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indentedGoal = goals[indexPath.row]
        let goal = indentedGoal.goal
        
        func rowsUpToParent(indexPath: IndexPath) -> [IndexPath] {
            var rows = [indexPath]
            var indexRow = indexPath.row
            var indentation = goals[indexRow].indentation - 1
            while indentation >= 0 {
                if goals[indexRow].indentation == indentation {
                    rows.append(IndexPath(row: indexRow, section: indexPath.section))
                    indentation -= 1
                }
                indexRow -= 1
            }
            return rows
        }
        var rowsToReload = rowsUpToParent(indexPath: indexPath)
        
        if goal == selectedGoal {
            selectedGoal = nil
            selectedIndex = nil
        } else {
            if let selectedIndex = selectedIndex {
                rowsToReload += rowsUpToParent(indexPath: selectedIndex)
            }
            selectedGoal = goal
            selectedIndex = indexPath
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
    /**
     * Called when a GoalSelector dismisses.
     * - Parameters:
     *    - goals: The goal selected by the user.
     */
    func dismissedGoalSelectorWithSelectedGoal(_ goal: Goal?)
}
