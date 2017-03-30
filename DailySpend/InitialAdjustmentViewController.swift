//
//  InitialSpendViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/23/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class InitialAdjustmentViewController: UIViewController {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    @IBOutlet weak var monthlyField: UITextField!
    @IBOutlet weak var dailyField: UITextField!
    
    var amount: Double = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let bbi = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
        self.navigationItem.rightBarButtonItem = bbi
        self.navigationItem.title = "DailySpend"
    }

    @IBAction func valueChanged(_ sender: UITextField) {
        amount = sender.text!.parseValidAmount(maxLength: 8)
        sender.text = String.formatAsCurrency(amount: amount)
    }
    
    
    func save(_ sender: UIBarButtonItem) {
        UserDefaults.standard.set(amount, forKey: "initialMonthAdjustment")
        self.dismiss(animated: true, completion: nil)
    }
}
