//
//  ReviewTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/30/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ReviewTableViewCell: UITableViewCell {

    @IBOutlet weak var spentAmountLabel: UILabel!
    @IBOutlet weak var goalAmountLabel: UILabel!
    @IBOutlet weak var overUnderLabel: UILabel!
    @IBOutlet weak var overUnderAmountLabel: UILabel!
    
    /*
     * Sets and format currency labels and message based on currency labels.
     */
    func setAndFormatLabels(spentAmount spent: Decimal,
                            goalAmount goal: Decimal) {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency

        let overUnder = goal - spent

        goalAmountLabel.text = currencyFormatter.string(from: goal as NSNumber)
        spentAmountLabel.text = currencyFormatter.string(from: spent as NSNumber)
        overUnderAmountLabel.text = currencyFormatter.string(from: Decimal.abs(overUnder) as NSNumber)
        
        if overUnder < 0 {
            overUnderLabel.text = "Over goal"
            overUnderAmountLabel.textColor = UIColor(colorLiteralRed: 179.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1)
            
        } else {
            overUnderLabel.text = "Under goal"
            overUnderAmountLabel.textColor = UIColor(colorLiteralRed: 0.0/255.0, green: 179.0/255.0, blue: 0.0/255.0, alpha: 1)
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
