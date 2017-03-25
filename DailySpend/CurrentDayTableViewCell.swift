//
//  CurrentDayTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/23/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class CurrentDayTableViewCell: UITableViewCell {

    @IBOutlet weak var spendLeftLabel: UILabel!
    @IBOutlet weak var monthlySpendLeftLabel: UILabel!
    @IBOutlet weak var todaysSpendingLabel: UILabel!
    
    func setAndFormatLabels(dailySpendLeft: Decimal,
                            monthlySpendLeft: Decimal,
                            expensesToday: Bool) {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        
        spendLeftLabel.text = currencyFormatter.string(from: dailySpendLeft as NSNumber)
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
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
