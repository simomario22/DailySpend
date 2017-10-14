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
    @IBOutlet weak var overUnderAmountButton: UIButton!
    
    let redColor = UIColor(red: 179.0/255.0,
                           green: 0.0/255.0,
                           blue: 0.0/255.0,
                           alpha: 1)
    let greenColor = UIColor(red: 0.0/255.0,
                             green: 179.0/255.0,
                             blue: 0.0/255.0,
                             alpha: 1)
    
    // Necessary since we can't have closures for button press events :(
    var currencyFormatter: NumberFormatter!
    var yesterdayCarry: Decimal!
    var overUnder: Decimal!
    var todayCarry: Decimal!
    var alreadyHighlighted = false
    
    var overUnderAbsNS: NSNumber {
        return abs(overUnder) as NSNumber
    }
    var yesterdayNS: NSNumber {
        return yesterdayCarry as NSNumber
    }
    var todayNS: NSNumber {
        return todayCarry as NSNumber
    }
    
    /*
     * Sets and format currency labels and message based on currency labels.
     */
    func setAndFormatLabels(spentAmount spent: Decimal,
                            goalAmount goal: Decimal,
                            carryFromYesterday _yesterdayCarry: Decimal? = nil,
                            lastDayOfMonth lastDay: Bool = false) {
        yesterdayCarry = _yesterdayCarry
        currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency

        overUnder = goal - spent

        goalAmountLabel.text = currencyFormatter.string(from: goal as NSNumber)
        spentAmountLabel.text = currencyFormatter.string(from: spent as NSNumber)

        
        if yesterdayCarry != nil {
            todayCarry = (yesterdayCarry! + overUnder)
            
            let color = todayCarry < 0 ? redColor : greenColor
            overUnderAmountButton.setTitleColor(color, for: .normal)
            
            overUnderLabel.text = lastDay ?
                                 "Left over this month" : "Carried To Tomorrow"
            
            let formattedString = currencyFormatter.string(from: todayCarry as NSNumber)!
            overUnderAmountButton.setTitle(formattedString, for: .normal)
            
            overUnderAmountButton.removeTarget(self,
                                               action: #selector(setCarryLabel),
                                               for: .touchUpInside)
            overUnderAmountButton.addTarget(self,
                                            action: #selector(setCarryLabel),
                                            for: .touchUpInside)
            overUnderAmountButton.isUserInteractionEnabled = true
            if !alreadyHighlighted {
                // Animate to show that this is a button
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    UIView.transition(with: self.overUnderAmountButton,
                      duration: 0.25,
                      options: .transitionCrossDissolve,
                      animations: {
                        self.overUnderAmountButton.isHighlighted = true
                    }, completion: {(completed) in
                        UIView.transition(with: self.overUnderAmountButton,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.overUnderAmountButton.isHighlighted = false
                        })
                    })
                }
                alreadyHighlighted = true
            }
        } else {
            let formattedString = currencyFormatter.string(from: overUnderAbsNS)!
            overUnderAmountButton.setTitle(formattedString, for: .normal)
            if overUnder < 0 {
                overUnderLabel.text = "Over goal"
                overUnderAmountButton.setTitleColor(redColor, for: .normal)
            } else {
                overUnderLabel.text = "Under goal"
                overUnderAmountButton.setTitleColor(greenColor, for: .normal)
            }
            overUnderAmountButton.isUserInteractionEnabled = false
        }
    }
    
    @objc func setCarryLabel() {
        // Create strings.
        let yesterdayCarryString = currencyFormatter.string(from: yesterdayNS)!
        let overUnderString = currencyFormatter.string(from: overUnderAbsNS)!
        let todayCarryString = currencyFormatter.string(from: todayNS)!
        
        let plusOrMinus = overUnder! < 0 ? " - " : " + "
        let equationString = yesterdayCarryString +
                             plusOrMinus +
                             overUnderString +
                             " = " +
                             todayCarryString
        let attributedText = NSMutableAttributedString(string: equationString)
        
        let addAttribute = {(color: UIColor, start: Int, len: Int) in
            attributedText.addAttribute(NSAttributedStringKey.foregroundColor,
                                        value: color,
                                        range: NSMakeRange(start, len))
        }
        
        // Add colors to all the strings.
        var start = 0
        var len = yesterdayCarryString.characters.count
        var color = yesterdayCarry < 0 ? redColor : greenColor
        addAttribute(color, start, len)
        
        addAttribute(UIColor.black, start + len, 3)
        
        start = len + 3
        len = overUnderString.characters.count
        color = overUnder < 0 ? redColor : greenColor
        addAttribute(color, start, len)

        addAttribute(UIColor.black, start + len, 3)
        
        start = start + len + 3
        len = todayCarryString.characters.count
        color = todayCarry < 0 ? redColor : greenColor
        addAttribute(color, start, len)

        overUnderAmountButton.setAttributedTitle(attributedText, for: .normal)
        overUnderAmountButton.isUserInteractionEnabled = false
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let font = UIFont.systemFont(ofSize: 22,
                                     weight: UIFont.Weight.light)
        spentAmountLabel.font = font
        goalAmountLabel.font = font
        overUnderAmountButton.titleLabel!.font = font
        self.selectionStyle = .none
    }
}
