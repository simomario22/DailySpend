//
//  ExpenseViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 7/22/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ExpenseViewController: UIViewController, ExpenseViewDelegate {
    var expenseView: ExpenseView!

    var expense: Expense?
    var rightBBIStack = [UIBarButtonItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        self.navigationItem.title = "Expense"
        
        expenseView = ExpenseView(frame: view.bounds)
        expenseView.delegate = self
        expenseView.dataSource = ExpenseProvider(expense: expense)
        expenseView.updateFieldValues()
        expenseView.updateSubviewFrames()
        
        view.addSubview(expenseView)
    }

    func didBeginEditing(sender: ExpenseView) {
        
    }

    func didEndEditing(sender: ExpenseView, expense: Expense?) {
        navigationController?.popViewController(animated: true)
    }
    
    func present(_ vc: UIViewController, animated: Bool,
                 completion: (() -> Void)?, sender: Any?) {
        self.present(vc, animated: animated, completion: completion)
    }
    
    func pushRightBBI(_ bbi: UIBarButtonItem, sender: Any?) {
        rightBBIStack.append(bbi)
        self.navigationItem.rightBarButtonItem = rightBBIStack.last!
    }
    
    func popRightBBI(sender: Any?) {
        _ = rightBBIStack.popLast()
        if let bbi = rightBBIStack.last {
            self.navigationItem.rightBarButtonItem = bbi
        }
    }
    
    func pushLeftBBI(_ bbi: UIBarButtonItem, sender: Any?) { }
    
    func popLeftBBI(sender: Any?) { }
    
    func disableRightBBI(sender: Any?) {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func enableRightBBI(sender: Any?) {
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func disableLeftBBI(sender: Any?) { }
    
    func enableLeftBBI(sender: Any?) { }


}
