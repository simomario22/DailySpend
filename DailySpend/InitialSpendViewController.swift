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
    
    @IBOutlet weak var effectLabel: UILabel!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let resignAllButton = UIButton()
        resignAllButton.backgroundColor = UIColor.clear
        resignAllButton.frame = view.bounds
        resignAllButton.addTarget(self,
                                  action: #selector(resignResponders),
                                  for: UIControlEvents.touchUpInside)
        
        self.view.insertSubview(resignAllButton, at: 0)
        
        let dailyTargetSpend = UserDefaults.standard.double(forKey: "dailyTargetSpend")
        if dailyTargetSpend == 0 {
            effectLabel.isHidden = true
        } else {
            self.dailyField.text = String.formatAsCurrency(amount: dailyTargetSpend)
            self.monthlyField.text = String.formatAsCurrency(amount: dailyTargetSpend * 30)
            fixFrames()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save,
                                         target: self,
                                         action: #selector(save(_:)))
        self.tabBarController?.navigationItem.rightBarButtonItem = saveButton
    }
    
    @objc func resignResponders() {
        self.monthlyField.resignFirstResponder()
        self.dailyField.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    /*
     * Fix the frames of the money fields so that everything is visible, and
     * possibly make the font smaller.
     */
    func fixFrames() {
        // Calculate the maximum width the text fields can have without overlap.
        let midMonthX = (monthlyField.frame.origin.x * 2 + monthlyField.frame.width) / 2
        let midDayX = (dailyField.frame.origin.x * 2 + dailyField.frame.width) / 2
        let center = (midMonthX + midDayX) / 2
        let maxWidth = (center - 5 - midMonthX) * 2
        let maxHeight: CGFloat = 33
        
        dailyField.frame.size.width = maxWidth
        monthlyField.frame.size.width = maxWidth
        dailyField.frame.size.height = maxHeight
        monthlyField.frame.size.height = maxHeight
        
        monthlyField.resizeFontToFit(desiredFontSize: 28, minFontSize: 8)
        dailyField.font = monthlyField.font
    }


    @IBAction func valueChanged(_ sender: UITextField) {
        let amount = sender.text!.parseValidAmount(maxLength: 8)
        
        let dailyAmount = sender.tag == 2 ? amount : amount / 30
        let monthlyAmount = sender.tag == 1 ? amount : amount * 30
        
        dailyField.text = String.formatAsCurrency(amount: dailyAmount)
        monthlyField.text = String.formatAsCurrency(amount: monthlyAmount)
        fixFrames()
    }
    
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let dailyAmount = dailyField.text!.parseValidAmount(maxLength: 8)
        if dailyAmount <= 0 {
            let message = "You need to pick a spend greater than $0."
            let alert = UIAlertController(title: "Couldn't Save",
                                          message: message,
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            UserDefaults.standard.set(dailyAmount, forKey: "dailyTargetSpend")
            monthlyField.resignFirstResponder()
            dailyField.resignFirstResponder()
            self.dismiss(animated: true, completion: nil)
            self.tabBarController?.navigationController?.popViewController(animated: true)
        }
    }
}
