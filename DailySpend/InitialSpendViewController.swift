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

    @IBAction func dailyChanged(_ sender: UITextField) {
        let nonNumbers = CharacterSet(charactersIn: "01234567890").inverted
        var s = sender.text!.trimmingCharacters(in: nonNumbers)
        let length = s.lengthOfBytes(using: .ascii)
        if length == 0 {
            s = "0"
        } else if length > 8 {
            s = s.substring(to: s.index(s.endIndex, offsetBy: -(8 - length)))
        }
        
        
        let dailyAmount = Double(s)! / 100
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        sender.text = currencyFormatter.string(from: dailyAmount as NSNumber)
        monthlyField.text = currencyFormatter.string(from: (dailyAmount * 30) as NSNumber)
    }
    
    @IBAction func monthlyChanged(_ sender: UITextField) {
        let nonNumbers = CharacterSet(charactersIn: "01234567890").inverted
        var s = sender.text!.trimmingCharacters(in: nonNumbers)
        let length = s.lengthOfBytes(using: .ascii)
        if length == 0 {
            s = "0"
        } else if length > 8 {
            s = s.substring(to: s.index(s.endIndex, offsetBy: -(8 - length)))
        }
        
        
        let dailyAmount = Double(s)! / 100
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        sender.text = currencyFormatter.string(from: dailyAmount as NSNumber)
        dailyField.text = currencyFormatter.string(from: (dailyAmount / 30) as NSNumber)
    }

    @IBAction func save(_ sender: UIBarButtonItem) {
        let nonNumbers = CharacterSet(charactersIn: "01234567890").inverted
        var s = dailyField.text!.trimmingCharacters(in: nonNumbers)
        let length = s.lengthOfBytes(using: .ascii)
        if length == 0 {
            s = "0"
        } else if length > 8 {
            s = s.substring(to: s.index(s.endIndex, offsetBy: -(8 - length)))
        }
        
        
        let dailyAmount = Double(s)! / 100
        if dailyAmount == 0 {
            let alert = UIAlertController(title: "Can't have 0 spend", message: "You need to pick a spend greater than 0.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            UserDefaults.standard.set(dailyAmount, forKey: "dailyTargetSpend")
        }
    }
}
