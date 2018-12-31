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
    let balanceBarViewHeight: CGFloat = 40

    var balanceBar: UIView
    
    init(delegate: BalanceBarControllerDelegate, view: UIView, topY: NSLayoutYAxisAnchor) {
        self.balanceBar = UIView()
        NotificationCenter.default.addObserver(
            forName: .init("ChangedSpendIndicationColor"),
            object: nil,
            queue: nil,
            using: updateBarTintColor
        )
        
        let balanceBarFrame = CGRect(
            x: 0,
            y: 0,
            width: view.frame.size.width,
            height: balanceBarViewHeight
        )
        
        self.balanceBar = UIView(frame: balanceBarFrame)
        self.balanceBar.translatesAutoresizingMaskIntoConstraints = false
        self.balanceBar.tintColor = view.tintColor

        let button = UIButton(frame: balanceBarFrame)
        button.setTitle("carry over", for: .normal)
        button.setTitleColor(view.tintColor, for: .normal) // TODO: Figure out how to inherit this.
        button.add(for: .touchUpInside) {
            delegate.requestedReloadOfCarryOverAdjustments()
        }
        button.backgroundColor = .clear

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
        balanceBar.heightAnchor.constraint(equalToConstant: balanceBarViewHeight).isActive = true

        balanceBar.addSubview(button)

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
