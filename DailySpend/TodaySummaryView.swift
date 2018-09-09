//
//  TodaySummaryView.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/5/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

class TodaySummaryView: UIView {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    private let margin: CGFloat = 8
    private let amountLabel = UICountingLabel()
    private let toSpendLabel = UILabel()
    private let hintLabel = UILabel()
    private let currencyFormatter = NumberFormatter()
    private var colorNegative: Bool? = nil
    
    override func layoutSubviews() {
        super.layoutSubviews()
        amountLabel.frame = CGRect(
            x: margin,
            y: margin,
            width: frame.size.width - margin * 2,
            height: 50
        )
        
        toSpendLabel.frame = CGRect(
            x: margin,
            y: amountLabel.frame.bottomEdge + margin / 2,
            width: frame.size.width - margin * 2,
            height: 15
        )
        
        hintLabel.frame = CGRect(
            x: margin,
            y: toSpendLabel.frame.bottomEdge + margin,
            width: frame.size.width - margin * 2,
            height: 15
        )
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        amountLabel.textAlignment = .center
        amountLabel.font = UIFont(name: "HelveticaNeue-Light", size: 42.0)
        
        currencyFormatter.numberStyle = .currency
        amountLabel.formatBlock = { (value: CGFloat) -> String? in
            self.updateColor(value: value)
            return self.currencyFormatter.string(from: value as NSNumber)
        }
        
        toSpendLabel.textAlignment = .center
        toSpendLabel.font = UIFont.systemFont(ofSize: 14.0)
        toSpendLabel.text = "to spend"
        
        hintLabel.textAlignment = .center
        hintLabel.font = UIFont.systemFont(ofSize: 14.0)
        
        self.addSubviews([amountLabel, toSpendLabel, hintLabel])
    }
    
    func countFrom(_ from: CGFloat, to: CGFloat) {
        amountLabel.count(from: from, to: to)
    }
    
    func setAmount(value: CGFloat) {
        amountLabel.text = self.currencyFormatter.string(from: value as NSNumber)
        self.updateColor(value: value)
    }
    
    func setHint(_ hint: String) {
        hintLabel.text = hint
    }

    private func updateColor(value: CGFloat) {
        if ( (value < 0) != colorNegative ) {
            appDelegate.spendIndicationColor = value < 0 ? .overspent : .underspent
            colorNegative = value < 0
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
