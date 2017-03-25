//
//  InitialSpendViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/23/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class InitialSpendViewController: UIViewController {

    @IBOutlet weak var monthlyField: UITextField!
    @IBOutlet weak var dailyField: UITextField!
    
    
    var dayConstraint: NSLayoutConstraint?
    var monthConstraint: NSLayoutConstraint?
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func fixFrames() {
        // Calculate the maximum width the text fields can have without overlap.
        let midMonthX = (monthlyField.frame.origin.x * 2 + monthlyField.frame.width) / 2
        let midDayX = (dailyField.frame.origin.x * 2 + dailyField.frame.width) / 2
        let center = (midMonthX + midDayX) / 2
        let maxWidth = (center - 5 - midMonthX) * 2

        // Determine max font size that can fit in the space available.
        var fontSize: CGFloat = 28
        let minFontSize: CGFloat = 8
        
        var attr = [NSFontAttributeName: monthlyField.font!.withSize(fontSize)]
        var width = monthlyField.text!.size(attributes: attr).width
        
        while width > maxWidth && fontSize > minFontSize {
            fontSize -= 1
            attr = [NSFontAttributeName: monthlyField.font!.withSize(fontSize)]
            width = monthlyField.text!.size(attributes: attr).width
        }
        monthlyField.font = monthlyField.font!.withSize(fontSize)
        dailyField.font = dailyField.font!.withSize(fontSize)

        // Update widths of text fields (with constraints).
        if dayConstraint != nil {
            self.view.removeConstraint(dayConstraint!)
        }
        if monthConstraint != nil {
            self.view.removeConstraint(monthConstraint!)
        }

        dayConstraint = NSLayoutConstraint(item: dailyField,
                                          attribute: .width,
                                          relatedBy: .equal,
                                          toItem: nil,
                                          attribute: .notAnAttribute,
                                          multiplier: 1,
                                          constant: maxWidth)
        
        monthConstraint = NSLayoutConstraint(item: monthlyField,
                                            attribute: .width,
                                            relatedBy: .equal,
                                            toItem: nil,
                                            attribute: .notAnAttribute,
                                            multiplier: 1,
                                            constant: maxWidth)
        
        self.view.addConstraints([dayConstraint!, monthConstraint!])
    }
    
    func parseValidAmount(currencyString: String, maxSize: Int) -> Double {
        let nonNumbers = CharacterSet(charactersIn: "0123456789").inverted
        var s = currencyString.removeCharactersWhichAreActuallyUnicodeScalarsSoBeCareful(in: nonNumbers)
        let length = s.lengthOfBytes(using: .ascii)
        if length == 0 {
            s = "0"
        } else if length > maxSize {
            s = s.substring(to: s.index(s.endIndex, offsetBy: maxSize - length))
        }
        
        return Double(s)! / 100
    }
    
    func formatAsCurrency(amount: Double) -> String? {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        return currencyFormatter.string(from: amount as NSNumber)
    }

    @IBAction func valueChanged(_ sender: UITextField) {
        let amount = parseValidAmount(currencyString: sender.text!, maxSize: 8)
        
        let dailyAmount = sender.tag == 2 ? amount : amount / 30
        let monthlyAmount = sender.tag == 1 ? amount : amount * 30
        
        dailyField.text = formatAsCurrency(amount: dailyAmount)
        monthlyField.text = formatAsCurrency(amount: monthlyAmount)
        fixFrames()
    }
    
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let dailyAmount = parseValidAmount(currencyString: dailyField.text!, maxSize: 8)
        if dailyAmount == 0 {
            let alert = UIAlertController(title: "Can't have 0 spend", message: "You need to pick a spend greater than 0.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            UserDefaults.standard.set(dailyAmount, forKey: "dailyTargetSpend")
        }
    }
}
