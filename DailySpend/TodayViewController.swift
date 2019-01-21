//
//  TodayViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/12/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController: UIViewController, GoalPickerDelegate, TodayViewExpensesDelegate {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)

    private var summaryViewHidden: Bool = true
    private var summaryView: TodaySummaryView!
    private var neutralBarColor: UIColor!
    private var tableView: UITableView!
    private var expensesController: TodayViewExpensesController!
    private var cellCreator: TableViewCellHelper!
    
    var goalPicker: NavigationGoalPickerController!
    var goal: Goal!
    
    let summaryViewHeightWithHint: CGFloat = 120
    let summaryViewHeightWithoutHint: CGFloat = 97
    
    var expenses = [(desc: String, amount: String)]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .tint
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBarTintColor),
            name: NSNotification.Name.init("ChangedSpendIndicationColor"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: NSNotification.Name.NSCalendarDayChanged,
            object: nil
        )

        let width = view.frame.size.width
        let summaryFrame = CGRect(
            x: 0,
            y: -summaryViewHeightWithHint,
            width: width,
            height: summaryViewHeightWithHint
        )
        summaryView = TodaySummaryView(frame: summaryFrame)
        
        // The border line hangs below the summary frame, so we'll use that one
        // so it slides out nicely.
        self.navigationController?.navigationBar.hideBorderLine()
        self.navigationController?.delegate = self

        let navHeight = navigationController?.navigationBar.frame.size.height ?? 0
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
        let tableHeight = view.frame.size.height - navHeight - statusBarHeight
        let tableFrame = CGRect(x: 0, y: 0, width: width, height: tableHeight)

        tableView = UITableView(frame: tableFrame, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubviews([tableView, summaryView])
        
        tableView.topAnchor.constraint(equalTo: summaryView.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        expensesController = TodayViewExpensesController(
            tableView: tableView,
            present: self.present
        )
        expensesController.delegate = self
        
        tableView.delegate = expensesController
        tableView.dataSource = expensesController
        
        goalPicker = goalPicker ?? NavigationGoalPickerController()
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.isEnabled = false
        infoButton.add(for: .touchUpInside, {
            let reviewController = ReviewViewController()
            reviewController.goalPicker = self.goalPicker
            reviewController.goal = self.goal
            self.navigationController?.pushViewController(reviewController, animated: true)
        })
        let infoBBI = UIBarButtonItem(customView: infoButton)
        self.navigationItem.leftBarButtonItem = infoBBI
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        updateSummaryViewForGoal(self.goal)

         // Settings can change suggested options in add cell.
        expensesController.reloadAddCell()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /**
     * Implements TodayViewGoalsDelegate.
     *
     * Updates expenses and summary view to reflect the new goal, or if the new
     * goal is `nil`, puts those views into an appropriate state.
     */
    func goalChanged(newGoal: Goal?) {
        self.navigationItem.leftBarButtonItem?.isEnabled = (newGoal != nil)
        self.goal = newGoal
        expensesController.loadExpensesForGoal(newGoal)
        updateSummaryViewForGoal(newGoal)
    }
    
    /**
     * Implements TodayViewExpensesDelegate.
     *
     * Updates the summary view to reflect any changes in data for this goal.
     */
    func expensesChanged(goal: Goal) {
        if goal != self.goal {
            self.goal = goal
            goalPicker.setGoal(newGoal: goal)
            goalChanged(newGoal: goal)
        } else {
            updateSummaryViewForGoal(goal)
        }
    }
    
    /**
     * need to account fo the case where a goal has ended
     */
    @objc func dayChanged() {
        
    }
    
    /**
     * Updates the summary view frame and displayed data to that of the passed
     * goal, or hides the summary view if the passed goal is `nil`.
     */
    func updateSummaryViewForGoal(_ goal: Goal?) {
        guard let goal = goal else {
            animateSummaryViewFrameIfNecessary(show: false)
            summaryViewHidden = true
            return
        }
        
        animateSummaryViewFrameIfNecessary(show: true)
        summaryViewHidden = false
        
        // Update summary view with information from this goal for the
        // appropriate period.
        let balanceCalculator = GoalBalanceCalculator(persistentContainer: appDelegate.persistentContainer)
        balanceCalculator.calculateBalance(for: goal, on: CalendarDay()) {
            (balance: Decimal?, _, _) in
            guard let newAmount = balance?.doubleValue else {
                return
            }
            let oldAmount = GoalBalanceCache.mostRecentlyDisplayedBalance(goal: goal)
            if oldAmount != newAmount {
                self.summaryView.countFrom(CGFloat(oldAmount), to: CGFloat(newAmount))
            } else {
                self.summaryView.setAmount(value: CGFloat(newAmount))
                self.appDelegate.spendIndicationColor = newAmount < 0 ? .overspent : .underspent
            }
            GoalBalanceCache.setMostRecentlyDisplayedBalance(goal: goal, amount: newAmount)
        }
        
        // Determine what should be in the summary view hint and set it.
        let period = GoalPeriod(goal: goal, date: CalendarDay().start, style: .period)
        if let endDay = CalendarDay(dateInDay: period?.end) {
            let dateFormatter = DateFormatter()
            if endDay.year == CalendarDay().year {
                dateFormatter.dateFormat = "M/d"
            } else {
                dateFormatter.dateFormat = "M/d/yy"
            }
            let formattedDate = endDay.string(formatter: dateFormatter)
            summaryView.setHint("Period End: \(formattedDate)")
            animateSummaryViewHeightIfNecessary(height: summaryViewHeightWithHint)
        } else {
            summaryView.setHint("")
            animateSummaryViewHeightIfNecessary(height: summaryViewHeightWithoutHint)
        }
    }
    
    /**
     * Animates sliding the summary view in or out based on the value of `show`.
     *
     * If the summary view is already believed to be in the correct state based
     * on the value of `summaryViewHidden`, it will not be animated.
     */
    func animateSummaryViewFrameIfNecessary(show: Bool) {
        let offsetYMultiplier: CGFloat = show ? 1 : -1
        let hiddenValueIndicatingSummaryViewPositionIsCorrect = show ? false : true
        if summaryViewHidden != hiddenValueIndicatingSummaryViewPositionIsCorrect {
            // Need to call layoutIfNeeded outside the animation block and
            // before changing the summary view frame, otherwise we could end
            // up animating subviews we don't mean to that haven't been
            // placed yet.
            self.view.layoutIfNeeded()
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.summaryView.frame = self.summaryView.frame.offsetBy(
                        dx: 0,
                        dy: self.summaryView.frame.height * offsetYMultiplier
                    )
                    self.view.layoutIfNeeded()
                }
            )
        }
    }
    
    /**
     * Animates changing the summary view to a certain height, if it isn't
     * already set to that height.
     */
    func animateSummaryViewHeightIfNecessary(height: CGFloat) {
        if summaryView.frame.size.height != height {
            self.view.layoutIfNeeded()
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    var frame = self.summaryView.frame
                    frame.size.height = height
                    self.summaryView.frame = frame
                    self.view.layoutIfNeeded()
                }
            )
        }
    }
    
    /**
     * Updates the tint color of the navigation bar to the color specified
     * by the app delegate.
     */
    @objc func updateBarTintColor() {
        let newColor = self.appDelegate.spendIndicationColor
        if self.summaryView.backgroundColor != newColor {
            UIView.animate(withDuration: 0.2) {
                self.summaryView.backgroundColor = newColor
            }
        }
    }
}


extension TodayViewController : UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        let transition = ReverseNavigationAnimator()
        transition.forward = (operation == .push)
        return transition
    }
    
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        if viewController == self {
            goalPicker.delegate = self
            goalPicker.makeTitleView(
                view: navigationController.view,
                item: navigationItem,
                bar: navigationController.navigationBar,
                present: present,
                detailViewLanguage: false,
                buttonWidth: 50 // TODO: Make this a real number based on the button width
            )
            self.goalChanged(newGoal: goalPicker.currentGoal)
        }
    }
}
