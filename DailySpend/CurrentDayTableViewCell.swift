//
//  CurrentDayTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/23/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class CurrentDayTableViewCell: UITableViewCell {
    
    let redColor = UIColor(colorLiteralRed: 179.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1)

    @IBOutlet weak var spendLeftLabel: UICountingLabel!
    @IBOutlet weak var monthlySpendLeftLabel: UILabel!
    @IBOutlet weak var todaysSpendingLabel: UILabel!
    
    let currencyFormatter = NumberFormatter()
    
    func setAndFormatLabels(dailySpendLeft: Decimal,
                            previousDailySpendLeft: Decimal,
                            monthlySpendLeft: Decimal,
                            expensesToday: Bool) {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        
        spendLeftLabel.count(from: CGFloat(previousDailySpendLeft.doubleValue),
                             to: CGFloat(dailySpendLeft.doubleValue))
        let monthFormat = currencyFormatter.string(from: monthlySpendLeft as NSNumber)
        monthlySpendLeftLabel.text = "\(monthFormat!) left to spend this month"
        
        if expensesToday {
            todaysSpendingLabel.isHidden = false
            self.separatorInset = UIEdgeInsetsMake(0, 0, 0, self.bounds.size.width);
        } else {
            todaysSpendingLabel.isHidden = true
            self.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
        }
    }
    
    override func awakeFromNib() {
        currencyFormatter.numberStyle = .currency

        spendLeftLabel.formatBlock = { (value: CGFloat) -> String? in
            if (value < 0) {
                self.spendLeftLabel.textColor = self.redColor
            } else {
                self.spendLeftLabel.textColor = UIColor.black
            }
            return self.currencyFormatter.string(from: value as NSNumber)
        }
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
