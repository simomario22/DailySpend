//
//  CurrentDayTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/23/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class CurrentDayTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var spendLeftLabel: UICountingLabel!
    @IBOutlet weak var todaysSpendingLabel: UILabel!
    
    let currencyFormatter = NumberFormatter()
    
    func setAndFormatLabels(dailySpendLeft: Decimal,
                            previousDailySpendLeft: Decimal,
                            expensesToday: Bool) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, M/d"
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        
        let formattedDate = dateFormatter.string(from: Date())
        self.dateLabel.text = "\(formattedDate)"
        spendLeftLabel.count(from: CGFloat(previousDailySpendLeft.doubleValue),
                             to: CGFloat(dailySpendLeft.doubleValue))
    
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
                self.spendLeftLabel.textColor = UIColor.overspent
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
