//
//  ReviewMonthViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ReviewMonthViewController: UIViewController {

    @IBOutlet weak var spentAmount: UILabel!
    @IBOutlet weak var goalAmount: UILabel!
    @IBOutlet weak var underOverAmount: UILabel!
    @IBOutlet weak var underOverLabel: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    
    /*
     * Sets and format currency labels and message based on currency labels.
     */
    func setAndFormatLabels(spentAmount spent: Decimal,
                            goalAmount goal: Decimal,
                            underOverAmount underOver: Decimal,
                            dayInMonth day: Date) {
        let dateFormatter = DateFormatter()
        monthLabel.text = dateFormatter.monthSymbols[day.month - 1] + " \(day.year)"
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        
        goalAmount.text = currencyFormatter.string(from: goal as NSNumber)
        spentAmount.text = currencyFormatter.string(from: spent as NSNumber)
        underOverAmount.text = currencyFormatter.string(from: Decimal.abs(underOver) as NSNumber)
        
        if underOver < 0 {
            underOverLabel.text = "Over goal"
            underOverAmount.textColor = UIColor(colorLiteralRed: 0, green: 179, blue: 0, alpha: 1)
            message.text = "You went over your goal (with adjustments) by \(underOverAmount.text). Try to focus on not exceeding your daily spend goal next month to save more money."

        } else {
            underOverLabel.text = "Under goal"
            underOverAmount.textColor = UIColor(colorLiteralRed: 179, green: 0, blue: 0, alpha: 1)
            message.text = "Great job, you were under your spend goal (with adjustments) by \(underOverAmount.text)!"
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
