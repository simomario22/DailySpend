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
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    let maxFontSize: CGFloat = 28
    
    func fixFrames() {
        dailyField.invalidateIntrinsicContentSize()
        monthlyField.invalidateIntrinsicContentSize()
        monthlyField.font = monthlyField.font!.withSize(maxFontSize)
        dailyField.font = monthlyField.font!.withSize(maxFontSize)

        var endMonthX = monthlyField.frame.origin.x + monthlyField.frame.width
        var begDayX = dailyField.frame.origin.x
        let meetingPoint = begDayX - endMonthX
        
        while(endMonthX > begDayX - 10) {
            // We're within the 10pt margin, make font sizes smaller
            let currentFontSize = monthlyField.font!.pointSize
            monthlyField.font = monthlyField.font!.withSize(currentFontSize * 0.9)
            dailyField.font = monthlyField.font!.withSize(currentFontSize * 0.9)
            dailyField.invalidateIntrinsicContentSize()
            monthlyField.invalidateIntrinsicContentSize()

            print("New font size: \(currentFontSize * 0.9)")
            
            endMonthX = monthlyField.frame.origin.x + monthlyField.frame.width
            begDayX = dailyField.frame.origin.x

        }
    }
    
    func parseValidAmount(currencyString: String, maxSize: Int) -> Double {
        let nonNumbers = CharacterSet(charactersIn: "01234567890").inverted
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
