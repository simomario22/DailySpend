//
//  PeriodBrowserController.swift
//  DailySpend
//
//  Created by Josh Sherick on 10/28/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class BalanceBarController {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var balanceBar: BalanceBarView

    private let todayAmountLabel = "Today's Balance:"
    private let otherAmountLabel = "Ending Balance:"
    
    init(delegate: BalanceBarControllerDelegate, view: UIView, topY: NSLayoutYAxisAnchor) {
        self.balanceBar = BalanceBarView(frame: CGRect.zero)

        NotificationCenter.default.addObserver(
            forName: .init("ChangedSpendIndicationColor"),
            object: nil,
            queue: nil,
            using: updateBarTintColor
        )

        self.balanceBar.translatesAutoresizingMaskIntoConstraints = false
        self.balanceBar.tintColor = view.tintColor
        self.balanceBar.setTextLabel(otherAmountLabel)

        if appDelegate.spendIndicationColor == .underspent || appDelegate.spendIndicationColor == .overspent {
            self.balanceBar.backgroundColor = appDelegate.spendIndicationColor
        } else {
            let neutralColor = UIColor(red255: 254, green: 254, blue: 254)
            self.balanceBar.backgroundColor = neutralColor
        }

        view.addSubview(balanceBar)
        balanceBar.topAnchor.constraint(equalTo: topY).isActive = true
        balanceBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        balanceBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        balanceBar.heightAnchor.constraint(equalToConstant: BalanceBarView.collapsedHeight).isActive = true
    }

    func updateWithBalanceFor(goal: Goal, day: CalendarDay) {
        let balanceCalculator = GoalBalanceCalculator(persistentContainer: appDelegate.persistentContainer)
        self.balanceBar.setIsAnimating(true)
        balanceCalculator.calculateBalance(for: goal, on: day) {
            (amount: Decimal?, _, _) in
            let textLabel = day == CalendarDay() ? self.todayAmountLabel : self.otherAmountLabel
            let amountLabel = amount != nil ? String.formatAsCurrency(amount: amount!) ?? "" : "Unknown"
            self.balanceBar.setTextLabel(textLabel)
            self.balanceBar.setAmountLabel(amountLabel)
            self.balanceBar.setIsAnimating(false)

            guard let amount = amount else {
                return
            }

            self.appDelegate.spendIndicationColor = amount < 0 ? .overspent : .underspent

            if day == CalendarDay() {
                // Store this balance as the most recently displayed, since we do that for today.
                GoalBalanceCache.setMostRecentlyDisplayedBalance(goal: goal, amount: amount.doubleValue)
            }
        }
    }

    /**
     * Updates the tint color of the navigation bar to the color specified
     * by the app delegate.
     */
    func updateBarTintColor(_: Notification) {
        let newColor = self.appDelegate.spendIndicationColor
        if self.balanceBar.backgroundColor != newColor {
            UIView.animate(withDuration: 0.2) {
                self.balanceBar.backgroundColor = newColor
            }
        }
    }
}

protocol BalanceBarControllerDelegate {
    func requestedReloadOfCarryOverAdjustments()
}
