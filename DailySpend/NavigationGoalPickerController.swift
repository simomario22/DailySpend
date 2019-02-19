//
//  TodayViewGoalsController.swift
//  DailySpend
//
//  Created by Josh Sherick on 2/24/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class NavigationGoalPickerController: NSObject, UITableViewDataSource, UITableViewDelegate, GoalViewControllerDelegate {
    private let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    
    private let cellHeight: CGFloat = 66
    private let lastViewedGoalKey = "lastUsedGoal"
    private var titleViewWidth: CGFloat = 0
    private var detailViewLanguage: Bool = false
    private var titleView: GoalNavigationTitleView!
    
    private var present: ((UIViewController, Bool, (() -> Void)?) -> ())!
    
    private(set) var currentGoal: Goal? {
        didSet {
            setLastUsedGoal(goal: self.currentGoal)
            
            var title = self.currentGoal?.shortDescription ?? "DailySpend"
            if detailViewLanguage {
                title += " Detail"
            }

            titleView.title = title
            titleView.isCollapsed = false
        }
    }
    private var goals: [Goal.IndentedGoal]
    private var isTableVisible: Bool


    private var hiddenTableFrame: CGRect = .zero
    private var visibleTableFrame: CGRect = .zero
    private var maxTableHeight: CGFloat = 0
    
    private var goalTable: UITableView!
    private var dimmingView: UIButton!
    
    var delegate: GoalPickerDelegate?

    override init() {
        self.isTableVisible = false
        self.goals = []
        super.init()

        self.goalTable = UITableView()
        goalTable.dataSource = self
        goalTable.delegate = self
        goalTable.backgroundColor = .groupTableViewBackground

        self.dimmingView = UIButton()
        dimmingView.backgroundColor = .black
        dimmingView.alpha = 0
        dimmingView.isHidden = true
        dimmingView.add(for: .touchUpInside) {
            self.hideTable()
            self.titleView.isCollapsed = true
            self.isTableVisible = false
        }

        self.goals = getAllGoals()
        self.currentGoal = getLastUsedGoal()
        delegate?.goalChanged(newGoal: self.currentGoal)
    }

    public func makeTitleView(width: CGFloat, height: CGFloat) -> UIView {
        let frame = CGRect(x: 0, y: 0, width: width, height: height)
        let titleView = GoalNavigationTitleView(frame: frame)
        titleView.didTap = {
            if self.isTableVisible {
                self.hideTable()
                titleView.isCollapsed = true
            } else {
                self.showTable()
                titleView.isCollapsed = false
            }
            self.isTableVisible = !self.isTableVisible
        }
        return titleView
    }

    public func changedViewController(
        view: UIView,
        bar: UINavigationBar,
        goalNavigationTitleView: UIView,
        present: @escaping (UIViewController, Bool, (() -> Void)?) -> (),
        detailViewLanguage: Bool
    ) {
        self.present = present
        self.detailViewLanguage = detailViewLanguage
        self.titleView = (goalNavigationTitleView as! GoalNavigationTitleView)
        
        var title = self.currentGoal?.shortDescription ?? "DailySpend"
        if detailViewLanguage {
            title += " Detail"
        }
        self.titleView.title = title

        goalTable.removeFromSuperview()
        dimmingView.removeFromSuperview()

        let viewWidth = view.bounds.size.width
        let viewHeight = view.bounds.size.height
        let navHeight = bar.frame.size.height
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)

        maxTableHeight = viewHeight - navHeight - statusBarHeight

        let tableHeight = min(cellHeight * CGFloat(goals.count + 1), maxTableHeight)

        hiddenTableFrame = CGRect(x: 0, y: -tableHeight, width: viewWidth, height: tableHeight)
        visibleTableFrame = CGRect(x: 0, y: bar.frame.bottomEdge, width: viewWidth, height: tableHeight)

        goalTable.frame = isTableVisible ? visibleTableFrame : hiddenTableFrame
        view.insertSubview(goalTable, belowSubview: bar)
        setTableScrollEnabled()

        dimmingView.frame = CGRect(x: 0, y: 64, width: viewWidth, height: viewHeight)
        view.insertSubview(dimmingView, belowSubview: goalTable)

        titleView.setNeedsLayout()
    }
    
    func setGoal(newGoal: Goal) {
        self.currentGoal = newGoal
        self.goalTable?.reloadData()
    }
    
    private func getAllGoals() -> [Goal.IndentedGoal] {
        return Goal.getIndentedGoals(context: appDelegate.persistentContainer.viewContext)
    }
    
    private func getLastUsedGoal() -> Goal? {
        // Try to get the last viewed goal.
        if let url = UserDefaults.standard.url(forKey: lastViewedGoalKey) {
            let psc = appDelegate.persistentContainer.persistentStoreCoordinator
            if let id = psc.managedObjectID(forURIRepresentation: url),
               let goal = appDelegate.persistentContainer.viewContext.object(with: id) as? Goal {
                if !goal.isFault { // Not sure this would make it invalid.
                    return goal
                }
            }
        }
        
        // Find the first created goal, or return nil if there are no goals.
        let sortDescriptors = [NSSortDescriptor(key: "dateCreated_", ascending: true)]
        if let firstGoal = Goal.get(context: appDelegate.persistentContainer.viewContext, sortDescriptors: sortDescriptors, fetchLimit: 1)?.first {
            let id = firstGoal.objectID.uriRepresentation()
            UserDefaults.standard.set(id, forKey: lastViewedGoalKey)
            return firstGoal
        } else {
            return nil
        }
    }
    
    private func setLastUsedGoal(goal: Goal?) {
        if let goal = goal {
            let id = goal.objectID.uriRepresentation()
            UserDefaults.standard.set(id, forKey: lastViewedGoalKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lastViewedGoalKey)
        }
    }

    private func showTable() {
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.goalTable.frame = self.visibleTableFrame
                self.dimmingView.isHidden = false
                self.dimmingView.alpha = 0.3
            }
        )
    }
    
    private func hideTable() {
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.goalTable.frame = self.hiddenTableFrame
                self.dimmingView.alpha = 0
            }, completion: { _ in
                // Need to check if the table is still shown in case the
                // animation was cancelled.
                if !self.isTableVisible {
                    self.dimmingView.isHidden = true
                }
            }
        )
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: ChoiceTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "goalChoice") as? ChoiceTableViewCell
        if cell == nil {
            cell = ChoiceTableViewCell(style: .default, reuseIdentifier: "goalChoice")
        }
        
        cell.indentationLevel = 0
        cell.backgroundColor = UIColor.groupTableViewBackground
        cell.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

        let row = indexPath.row
        if row < goals.count {
            cell.textLabel?.text = goals[row].goal.shortDescription!
            cell.accessoryType = goals[row].goal == currentGoal ? .checkmark : .none
            cell.textLabel?.font = UIFont.systemFont(ofSize: cell.textLabel!.font.pointSize)
            cell.textLabel?.textAlignment = .left
            cell.indentationLevel = goals[row].indentation
            cell.setNeedsLayout()
            if row == goals.count - 1 {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
        } else {
            cell.textLabel?.text = "Manage Goals"
            cell.textLabel?.font = UIFont.systemFont(ofSize: cell.textLabel!.font.pointSize, weight: .medium)
            cell.accessoryType = .none
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor = UIColor(red255: 233, green: 233, blue: 238)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == goals.count {
            let vc = GoalViewController(nibName: nil, bundle: nil)
            vc.delegate = self
            let nvc = UINavigationController(rootViewController: vc)
            present(nvc, true, nil)
        } else {
            let newGoal = goals[indexPath.row].goal
            if self.currentGoal != newGoal {
                let oldGoalIndex = goals.index(where: { $0.goal == currentGoal! }) ?? indexPath.row
                let oldGoalIndexPath = IndexPath(row: oldGoalIndex, section: 0)
                self.currentGoal = newGoal
                delegate?.goalChanged(newGoal: self.currentGoal)
                self.goalTable.reloadRows(at: [indexPath, oldGoalIndexPath], with: .fade)
                
                // Hide goal selector table
                self.hideTable()
                self.titleView.isCollapsed = true
                self.isTableVisible = false
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    /**
     * Sets `isScrollEnabled` on the table based on goals, cell height, and the
     * current table's height.
     */
    private func setTableScrollEnabled() {
        let trueTableHeight = cellHeight * CGFloat(goals.count + 1)
        if trueTableHeight <= self.goalTable.frame.size.height {
            goalTable.isScrollEnabled = false
        } else {
            goalTable.isScrollEnabled = true
        }
    }
    
    func goalControllerWillDismissWithChangedGoals() {
        self.goals = getAllGoals()
        self.currentGoal = getLastUsedGoal()
        delegate?.goalChanged(newGoal: self.currentGoal)

        setTableScrollEnabled()

        let tableHeight = min(cellHeight * CGFloat(goals.count + 1), maxTableHeight)
        var frame = self.goalTable.frame
        frame.size.height = tableHeight

        self.goalTable.frame = frame
        self.goalTable.reloadData()
    }
}

protocol GoalPickerDelegate {
    func goalChanged(newGoal: Goal?)
}
