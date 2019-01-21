//
//  PeriodBrowserController.swift
//  DailySpend
//
//  Created by Josh Sherick on 10/28/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class PeriodBrowserController {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let periodBrowserViewHeight: CGFloat = 40

    var periodBrowser: PeriodBrowserView
    
    init(delegate: PeriodSelectorViewDelegate, view: UIView) {
        self.periodBrowser = PeriodBrowserView()
        self.periodBrowser.translatesAutoresizingMaskIntoConstraints = false

        NotificationCenter.default.addObserver(
            forName: .init("ChangedSpendIndicationColor"),
            object: nil,
            queue: nil,
            using: updateBarTintColor
        )
        
        let periodBrowserFrame = CGRect(
            x: 0,
            y: 0,
            width: view.frame.size.width,
            height: periodBrowserViewHeight
        )
        
        periodBrowser = PeriodBrowserView(frame: periodBrowserFrame)
        periodBrowser.delegate = delegate
        if appDelegate.spendIndicationColor == .underspent || appDelegate.spendIndicationColor == .overspent {
            periodBrowser.backgroundColor = appDelegate.spendIndicationColor
        } else {
            periodBrowser.backgroundColor = UIColor(red255: 254, green: 254, blue: 254)
        }

        view.addSubview(periodBrowser)

        periodBrowser.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        periodBrowser.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        periodBrowser.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        periodBrowser.heightAnchor.constraint(equalToConstant: periodBrowserViewHeight).isActive = true
    }
    
    /**
     * Updates period browser with information based on selected goal and
     * period.
     *
     * - Parameters:
     *      - goal: The goal to use to determine if buttons should be enabled,
     *        or `nil` if there is no selected goal.
     *      - recurringGoalPeriod: The period whose range should be displayed on
     *        the period browser, or `nil` if the goal is not a recurring goal.
     */
    func updatePeriodBrowser(period: GoalPeriod?) {
        guard let period = period else {
            periodBrowser.previousButtonEnabled = false
            periodBrowser.nextButtonEnabled = false
            periodBrowser.labelText = "None"
            return
        }
        
        periodBrowser.previousButtonEnabled = period.previousGoalPeriod() != nil
        periodBrowser.nextButtonEnabled = period.nextGoalPeriod() != nil

        periodBrowser.labelText = period.string(friendly: true, relative: true)
    }
    
    /**
     * Updates the tint color of the navigation bar to the color specified
     * by the app delegate.
     */
    func updateBarTintColor(_: Notification) {
        let newColor = self.appDelegate.spendIndicationColor
        if self.periodBrowser.backgroundColor != newColor {
            UIView.animate(withDuration: 0.2) {
                self.periodBrowser.backgroundColor = newColor
            }
        }
    }
}
