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
    func updatePeriodBrowser(goal: Goal!, recurringGoalPeriod: CalendarPeriod?) {
        if goal == nil {
            periodBrowser.previousButtonEnabled = false
            periodBrowser.nextButtonEnabled = false
            periodBrowser.labelText = "None"
            return
        }
        let df = DateFormatter()
        df.dateFormat = "M/d/yy"
        
        var start, end: String
        periodBrowser.previousButtonEnabled = false
        periodBrowser.nextButtonEnabled = false
        
        if let period = recurringGoalPeriod {
            // This is a recurring goal.
            periodBrowser.previousButtonEnabled = true
            periodBrowser.nextButtonEnabled = true
            start = period.start.string(formatter: df)
            let inclusiveDay = CalendarDay(dateInDay: period.end!).subtract(days: 1)
            end = inclusiveDay.string(formatter: df, friendly: true)
            
            // Check for no previous period.
            if period.previousCalendarPeriod().start.gmtDate < goal.start!.gmtDate {
                periodBrowser.previousButtonEnabled = false
            }

            // Check for no next period.
            let nextPeriodDate = period.nextCalendarPeriod()
            if nextPeriodDate == nil || nextPeriodDate!.start.gmtDate > CalendarDay().start.gmtDate {
                periodBrowser.nextButtonEnabled = false
            }
        } else {
            let interval = goal.periodInterval(for: goal.start!)!
            start = interval.start.string(formatter: df)
            if let intervalEnd = interval.end {
                end = intervalEnd.string(formatter: df, friendly: true)
            } else {
                end = "Today"
            }
        }

        periodBrowser.labelText = "\(start) - \(end)"
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
