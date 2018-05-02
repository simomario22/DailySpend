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

protocol TodayViewGoalsControllerDelegate {
    func goalChanged(newGoal: Goal?)
}

class TodayViewGoalsController : NSObject, UITableViewDataSource, UITableViewDelegate {

    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    let cellHeight: CGFloat = 66
    
    var view: UIView
    var navigationItem: UINavigationItem
    var navigationBar: UINavigationBar
    var present: (UIViewController, Bool, (() -> Void)?) -> ()
    var currentGoal: Goal?
    var goals: [Goal]
    var delegate: TodayViewGoalsControllerDelegate
    var tableShown: Bool
    
    var maxTableHeight: CGFloat {
        let navHeight = self.navigationBar.frame.size.height
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        
        return view.window!.frame.height - navHeight - statusBarHeight
    }
    var tableHeight: CGFloat {
        return min(cellHeight * CGFloat(goals.count + 1), maxTableHeight)
    }
    
    var goalTable: UITableView!
    var dimmingView: UIView!

    init(view: UIView,
         navigationItem: UINavigationItem,
         navigationBar: UINavigationBar,
         delegate: TodayViewGoalsControllerDelegate,
         present: @escaping (UIViewController, Bool, (() -> Void)?) -> ()) {
        self.view = view
        self.delegate = delegate
        self.navigationItem = navigationItem
        self.navigationBar = navigationBar
        self.present = present
        self.tableShown = false
        self.goals = []
        self.currentGoal = nil
        super.init()
        
         self.goals = getAllGoals()
         self.currentGoal = getLastUsedGoal()
        
        // **** REMOVE ME ******
//        let g = Goal(context: context)
//        g.shortDescription = "DailySpend"
//        self.goals = [g]
//        self.currentGoal = g
        // **** REMOVE ME ******
        
        let title = self.currentGoal?.shortDescription ?? "DailySpend"
        let navHeight = self.navigationBar.frame.size.height
        self.navigationItem.titleView = makeTitleView(height: navHeight, title: title, caretDown: true)
        
        delegate.goalChanged(newGoal: self.currentGoal)
    }
    
    func getAllGoals() -> [Goal] {
        let sortDescriptors = [NSSortDescriptor(key: "dateCreated_", ascending: true)]
        return Goal.get(context: context, sortDescriptors: sortDescriptors) ?? []
    }
    
    func getLastUsedGoal() -> Goal? {
        // Try to get the last viewed goal.
        if let url = UserDefaults.standard.url(forKey: "lastViewedGoal") {
            let psc = appDelegate.persistentContainer.persistentStoreCoordinator
            if let id = psc.managedObjectID(forURIRepresentation: url),
               let goal = context.object(with: id) as? Goal {
                return goal
            }
        }
        
        // Find the first created goal, or return nil if there are no goals.
        let sortDescriptors = [NSSortDescriptor(key: "dateCreated_", ascending: true)]
        if let firstGoal = Goal.get(context: context, sortDescriptors: sortDescriptors, fetchLimit: 1)?.first {
            let id = firstGoal.objectID.uriRepresentation()
            UserDefaults.standard.set(id, forKey: "lastViewedGoal")
            return firstGoal
        } else {
            return nil
        }
    }
    
    func makeTitleView(height: CGFloat, title: String, caretDown: Bool) -> UIView {
        let caret = caretDown ? "▼" : "▲"
        let explainer = "Change Goal"
        let fullExplainer =  caret + " " + explainer + " " + caret
        
        let titleFont = UIFont.preferredFont(forTextStyle: .headline)
        let explainerFont = UIFont.systemFont(ofSize: 12)
        let caretFont = UIFont.systemFont(ofSize: 8)
        
        let attributedExplainer = NSMutableAttributedString(string: fullExplainer)
        let attributedExplainerDone = NSMutableAttributedString(string: "▲ Collapse ▲")
        let caretAttr: [NSAttributedStringKey: Any] = [
            .font: caretFont,
            .foregroundColor: view.tintColor
        ]
        let explainerAttr: [NSAttributedStringKey: Any] = [
            .font: explainerFont,
            .foregroundColor: view.tintColor
        ]
        attributedExplainer.addAttributes(caretAttr, range: NSMakeRange(0, 1))
        attributedExplainer.addAttributes(explainerAttr, range: NSMakeRange(1, explainer.count + 2))
        attributedExplainer.addAttributes(caretAttr, range: NSMakeRange(explainer.count + 3, 1))
        
        attributedExplainerDone.addAttributes(caretAttr, range: NSMakeRange(0, 1))
        attributedExplainerDone.addAttributes(explainerAttr, range: NSMakeRange(1, 10))
        attributedExplainerDone.addAttributes(caretAttr, range: NSMakeRange(11, 1))
        
        let explainerHeight: CGFloat = 15
        let titleHeight = height - explainerHeight

        let explainerWidth = attributedExplainer.size().width
        let explainerDoneWidth = attributedExplainer.size().width
        let titleWidth = NSString(string: title).size(withAttributes: [.font: titleFont]).width
        let greatestWidth = max(max(explainerDoneWidth, explainerWidth), titleWidth)
        
        let maxBoundingWidth = view.bounds.size.width - (height * 2.5) // Save room for two square buttons
        let width = min(greatestWidth, maxBoundingWidth)
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: titleHeight))
        titleLabel.text = title
        titleLabel.font = titleFont
        titleLabel.textAlignment = .center
        
        let explainerLabel = UILabel(frame: CGRect(x: 0, y: titleHeight - 5, width: width, height: explainerHeight))
        explainerLabel.attributedText = attributedExplainer
        explainerLabel.textAlignment = .center
        
        let titleViewFrame = CGRect(x: 0, y: 0, width: width, height: height)
        
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.clear
        button.frame = titleViewFrame
        button.add(for: .touchUpInside, {
            self.tappedTitleView(setExplainer: { caretDown in
                if caretDown {
                    explainerLabel.attributedText = attributedExplainer
                } else {
                    explainerLabel.attributedText = attributedExplainerDone
                }
            })
        })
        
        let titleView = UIView(frame: titleViewFrame)
        titleView.addSubview(titleLabel)
        titleView.addSubview(explainerLabel)
        titleView.addSubview(button)
        
        return titleView
    }
    
    
    func showTable() {
        let height = tableHeight
        let width = view.bounds.size.width

        if goalTable == nil {
            goalTable = UITableView()
            goalTable.dataSource = self
            goalTable.delegate = self
            goalTable.frame = CGRect(x: 0, y: -height, width: width, height: height)
            view.insertSubview(goalTable, belowSubview: navigationBar)
        }
        
        if dimmingView == nil {
            dimmingView = UIView()
            dimmingView.backgroundColor = UIColor.black
            dimmingView.alpha = 0
            let dimmingViewFrame = CGRect(x: 0, y: 64, width: view.frame.size.width, height: view.frame.size.height)
            dimmingView.frame = dimmingViewFrame
            view.insertSubview(dimmingView, belowSubview: goalTable)
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            let y = self.navigationBar.frame.bottomEdge
            self.goalTable.frame = CGRect(x: 0, y: y, width: width, height: height)
            self.dimmingView.alpha = 0.3
        })
    }
    
    func hideTable() {
        if goalTable == nil {
            return
        }
        
        let height = tableHeight
        let width = view.bounds.size.width

        UIView.animate(withDuration: 0.2, animations: {
            self.goalTable.frame = CGRect(x: 0, y: -height, width: width, height: height)
            self.dimmingView.alpha = 0
        })
    }
    
    func tappedTitleView(setExplainer: @escaping (Bool) -> ()) {
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
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "goalChoice")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "goalChoice")
        }
        
        cell.textLabel?.textAlignment = .center
        
        let row = indexPath.row

        if row < goals.count {
            cell.textLabel?.text = goals[row].shortDescription!
            cell.accessoryType = goals[row] == currentGoal ? .checkmark : .none
        } else {
            cell.textLabel?.text = "Manage Goals"
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == goals.count {
            let vc = GoalViewController(nibName: nil, bundle: nil)
            let nvc = UINavigationController(rootViewController: vc)
            present(nvc, true, nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
