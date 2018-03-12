//
//  InitialSpendViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/23/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class InitialAdjustmentViewController: UIViewController {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    @IBOutlet weak var monthlyField: UITextField!
    @IBOutlet weak var dailyField: UITextField!
    
    var amount: Decimal = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let bbi = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
        self.navigationItem.rightBarButtonItem = bbi
        self.navigationItem.title = "DailySpend"
    }

    @IBAction func valueChanged(_ sender: UITextField) {
        amount = sender.text!.parseValidAmount()
        sender.text = String.formatAsCurrency(amount: amount)
    }
    
    
    @objc func save(_ sender: UIBarButtonItem) {
        UserDefaults.standard.set(amount, forKey: "initialMonthAdjustment")
        self.dismiss(animated: true, completion: nil)
    }
}
