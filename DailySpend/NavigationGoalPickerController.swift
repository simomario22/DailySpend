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
    private var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    private let cellHeight: CGFloat = 66
    private let lastViewedGoalKey = "lastUsedGoal"
    private var titleViewWidth: CGFloat = 0
    private var detailViewLanguage: Bool = false
    
    private var view: UIView!
    private var navigationItem: UINavigationItem!
    private var navigationBar: UINavigationBar!
    private var present: ((UIViewController, Bool, (() -> Void)?) -> ())!
    
    private(set) var currentGoal: Goal? {
        didSet {
            setLastUsedGoal(goal: self.currentGoal)
            
            var title = self.currentGoal?.shortDescription ?? "DailySpend"
            if detailViewLanguage {
                title += " Detail"
            }
            let navHeight = self.navigationBar.frame.size.height
            self.navigationItem.titleView = makeTitleView(height: navHeight, width: titleViewWidth, title: title)
            setExplainer(!tableShown)
        }
    }
    private var goals: [Goal.IndentedGoal]
    private var tableShown: Bool
    private var setExplainer: ((Bool) -> ())!

    private var maxTableHeight: CGFloat {
        let navHeight = self.navigationBar.frame.size.height
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        
        return view.frame.height - navHeight - statusBarHeight
    }
    private var trueTableHeight: CGFloat {
        return cellHeight * CGFloat(goals.count + 1)
    }
    private var tableHeight: CGFloat {
        return min(cellHeight * CGFloat(goals.count + 1), maxTableHeight)
    }
    
    private var goalTable: UITableView!
    private var dimmingView: UIButton!
    
    var delegate: GoalPickerDelegate?

    override init() {
        self.tableShown = false
        self.goals = []
        self.currentGoal = nil
        super.init()
        
        self.goals = getAllGoals()
        self.currentGoal = getLastUsedGoal()
        delegate?.goalChanged(newGoal: self.currentGoal)
    }
    public func makeTitleView(
        view: UIView,
        item: UINavigationItem,
        bar: UINavigationBar,
        present: @escaping (UIViewController, Bool, (() -> Void)?) -> (),
        detailViewLanguage: Bool,
        buttonWidth: CGFloat? = nil
    ) {
        self.view = view
        self.navigationItem = item
        self.navigationBar = bar
        self.present = present
        self.detailViewLanguage = detailViewLanguage
        
        var title = self.currentGoal?.shortDescription ?? "DailySpend"
        if detailViewLanguage {
            title += " Detail"
        }
        let margin: CGFloat = 5
        let navHeight = self.navigationBar.frame.size.height
        
        let buttonWidth = (buttonWidth == nil) ? navHeight : buttonWidth
        titleViewWidth = self.navigationBar.frame.size.width - ((buttonWidth! + margin) * 2)
        self.navigationItem.titleView = makeTitleView(height: navHeight, width: titleViewWidth, title: title)
        setExplainer(!tableShown)
    }
    
    func setGoal(newGoal: Goal) {
        self.currentGoal = newGoal
        self.goalTable?.reloadData()
    }
    
    private func getAllGoals() -> [Goal.IndentedGoal] {
        return Goal.getIndentedGoals(context: context, excludeGoal: { $0.isArchived || $0.hasFutureStart })
    }
    
    private func getLastUsedGoal() -> Goal? {
        // Try to get the last viewed goal.
        if let url = UserDefaults.standard.url(forKey: lastViewedGoalKey) {
            let psc = appDelegate.persistentContainer.persistentStoreCoordinator
            if let id = psc.managedObjectID(forURIRepresentation: url),
               let goal = context.object(with: id) as? Goal {
                if !goal.isFault {
                    return goal
                }
            }
        }
        
        // Find the first created goal, or return nil if there are no goals.
        let sortDescriptors = [NSSortDescriptor(key: "dateCreated_", ascending: true)]
        if let firstGoal = Goal.get(context: context, sortDescriptors: sortDescriptors, fetchLimit: 1)?.first {
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

    private func caretAttr(_ highlighted: Bool) -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: highlighted ? view.tintColor.withAlphaComponent(0.2) : view.tintColor
        ]
    }
    
    private func explainerAttr(_ highlighted: Bool) ->  [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: highlighted ? view.tintColor.withAlphaComponent(0.2) : view.tintColor
        ]
    }
    
    private func downExplainer(_ highlighted: Bool) -> NSMutableAttributedString {
        let attributedExplainer = NSMutableAttributedString(string: "▼ Change Goal ▼")
        attributedExplainer.addAttributes(caretAttr(highlighted), range: NSMakeRange(0, 1))
        attributedExplainer.addAttributes(explainerAttr(highlighted), range: NSMakeRange(1, 13))
        attributedExplainer.addAttributes(caretAttr(highlighted), range: NSMakeRange(14, 1))
        return attributedExplainer
    }
    
    private func upExplainer(_ highlighted: Bool) -> NSMutableAttributedString {
        let attributedExplainer = NSMutableAttributedString(string: "▲ Collapse ▲")
        attributedExplainer.addAttributes(caretAttr(highlighted), range: NSMakeRange(0, 1))
        attributedExplainer.addAttributes(explainerAttr(highlighted), range: NSMakeRange(1, 10))
        attributedExplainer.addAttributes(caretAttr(highlighted), range: NSMakeRange(11, 1))
        return attributedExplainer
    }
    
    private func makeTitleView(height: CGFloat, width: CGFloat, title: String) -> UIView {
        let titleFont = UIFont.preferredFont(forTextStyle: .headline)
        let explainerHeight: CGFloat = 15
        let titleHeight = height - explainerHeight
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: titleHeight))
        titleLabel.text = title
        titleLabel.font = titleFont
        titleLabel.textAlignment = .center
        
        let explainerLabel = UILabel(frame: CGRect(x: 0, y: titleHeight - 5, width: width, height: explainerHeight))
        explainerLabel.attributedText = downExplainer(false)
        explainerLabel.textAlignment = .center
        
        let titleViewFrame = CGRect(x: 0, y: 0, width: width, height: height)
        
        var highlighted = false
        setExplainer = { caretDown in
            if caretDown {
                explainerLabel.attributedText = self.downExplainer(highlighted)
            } else {
                explainerLabel.attributedText = self.upExplainer(highlighted)
            }
        }
        
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.clear
        button.frame = titleViewFrame
        button.add(for: [.touchDown, .touchDragEnter]) {
            highlighted = true
            self.setExplainer(!self.tableShown)
        }
        button.add(for: .touchDragExit) {
            highlighted = false
            self.setExplainer(!self.tableShown)
        }
        button.add(for: .touchUpInside, {
            highlighted = false
            self.tappedTitleView()
        })
        
        let titleView = UIView(frame: titleViewFrame)
        titleView.addSubviews([titleLabel, explainerLabel, button])
        
        return titleView
    }
    
    
    private func showTable() {
        let height = tableHeight
        let width = view.bounds.size.width

        if goalTable == nil {
            goalTable = UITableView()
            goalTable.dataSource = self
            goalTable.delegate = self
            goalTable.frame = CGRect(x: 0, y: -height, width: width, height: height)
            goalTable.backgroundColor = .groupTableViewBackground
            view.insertSubview(goalTable, belowSubview: navigationBar)
        }
        
        if trueTableHeight <= maxTableHeight {
            goalTable.isScrollEnabled = false
        } else {
            goalTable.isScrollEnabled = true
        }
        
        if dimmingView == nil {
            let dimmingViewFrame = CGRect(x: 0, y: 64, width: view.frame.size.width, height: view.frame.size.height)
            dimmingView = UIButton(frame: dimmingViewFrame)
            dimmingView.backgroundColor = UIColor.black
            dimmingView.alpha = 0
            dimmingView.isHidden = true
            dimmingView.add(for: .touchUpInside) {
                self.hideTable()
                self.setExplainer(true)
                self.tableShown = false
            }
            view.insertSubview(dimmingView, belowSubview: goalTable)
        }
        
        UIView.animate(
            withDuration: 0.2,
            animations: {
                let y = self.navigationBar.frame.bottomEdge
                self.goalTable.frame = CGRect(x: 0, y: y, width: width, height: height)
                self.dimmingView.isHidden = false
                self.dimmingView.alpha = 0.3
            }
        )
    }
    
    private func hideTable() {
        if goalTable == nil {
            return
        }
        
        let height = tableHeight
        let width = view.bounds.size.width

        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.goalTable.frame = CGRect(x: 0, y: -height, width: width, height: height)
                self.dimmingView.alpha = 0
            }, completion: { _ in
                // Need to check if the table is still shown in case the
                // animation was cancelled.
                if !self.tableShown {
                    self.dimmingView.isHidden = true
                }
            }
        )
    }
    
    private func tappedTitleView() {
        if tableShown {
            hideTable()
            setExplainer(true)
        } else {
            showTable()
            setExplainer(false)
        }
        tableShown = !tableShown
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
                setExplainer(true)
                tableShown = false
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func goalControllerWillDismissWithChangedGoals() {
        self.goals = getAllGoals()
        self.currentGoal = getLastUsedGoal()
        delegate?.goalChanged(newGoal: self.currentGoal)
        
        var frame = self.goalTable.frame
        frame.size.height = tableHeight
        self.goalTable.frame = frame
        self.goalTable.reloadData()
        if self.trueTableHeight <= self.maxTableHeight {
            self.goalTable.isScrollEnabled = false
            self.goalTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        } else {
            self.goalTable.isScrollEnabled = true
        }
    }
}

protocol GoalPickerDelegate {
    func goalChanged(newGoal: Goal?)
}
