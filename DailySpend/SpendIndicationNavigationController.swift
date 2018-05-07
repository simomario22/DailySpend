//
//  SpendIndicationNavigationController.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/6/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

class SpendIndicationNavigationController: UINavigationController {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .tint
        navigationBar.tintColor = .tint
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = appDelegate.spendIndicationColor
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBarTintColor),
            name: NSNotification.Name.init("ChangedSpendIndicationColor"),
            object: nil
        )
    }
    
    @objc func updateBarTintColor() {
        let newColor = self.appDelegate.spendIndicationColor
        if navigationBar.barTintColor != newColor {
            UIView.animate(withDuration: 0.2) {
                self.navigationBar.barTintColor = newColor
                self.navigationBar.layoutIfNeeded()
            }
        }
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
