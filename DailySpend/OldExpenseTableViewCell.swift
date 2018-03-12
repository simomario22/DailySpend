//
//  AddExpenseTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class OldExpenseTableViewCell: UITableViewCell, ExpenseViewDelegate {
    var delegate: AddExpenseTableViewCellDelegate?
    var expenseView: ExpenseView!
    @IBOutlet weak var addExpenseLabel: UILabel!
    
    var leftBBIStack = [UIBarButtonItem]()
    var rightBBIStack = [UIBarButtonItem]()
    
    let topMargin: CGFloat = 8

    override func layoutSubviews() {
        if expenseView != nil {
            expenseView.frame = CGRect(x: 0, y: addExpenseLabel.frame.bottomEdge,
                                       width: bounds.width, height: bounds.height)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        expenseView = ExpenseView()
        expenseView.delegate = self
        insertSubview(expenseView, belowSubview: addExpenseLabel)
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetView),
                                               name: NSNotification.Name.init("CancelAddingExpense"),
                                               object: UIApplication.shared)
        resetView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    @objc func resetView() {
        expenseView.dataSource = ExpenseProvider(expense: nil)
        expenseView.updateFieldValues()
        
        UIView.animate(withDuration: 0.2, animations: {
            let top = self.topMargin + self.addExpenseLabel.frame.size.height
            self.expenseView.frame = CGRect(x: 0,
                                            y: top,
                                            width: self.bounds.width,
                                            height: self.bounds.height)
        })
        
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseInOut,
        animations: {
            let frame = self.addExpenseLabel.frame
            self.addExpenseLabel.frame = CGRect(origin:
                                            CGPoint(x: frame.origin.x,
                                                    y: self.topMargin),
                                                size: frame.size)
        }, completion: nil)
    }

    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?, sender: Any?) {
        delegate?.present(vc, animated: animated, completion: completion, sender: sender)
    }

    func didBeginEditing(sender: ExpenseView) {
        UIView.animate(withDuration: 0.2, animations: {
            self.expenseView.frame = CGRect(x: 0,
                                            y: 0,
                                            width: self.bounds.width,
                                            height: self.bounds.height)
        })
        
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseInOut,
        animations: {
            let bottom = self.addExpenseLabel.frame.size.height + self.topMargin
            let newFrame = self.addExpenseLabel.frame.offsetBy(dx: 0, dy: -bottom)
            self.addExpenseLabel.frame = newFrame
        }, completion: nil)
        
        let rightBBI = (delegate as? TodayViewController)?.navigationItem.rightBarButtonItem
        let leftBBI = (delegate as? TodayViewController)?.navigationItem.leftBarButtonItem
        if rightBBI != nil {
            rightBBIStack.append(rightBBI!)
        }
        
        if leftBBI != nil {
            leftBBIStack.append(leftBBI!)
        }
        
        delegate?.expandCell(sender: self)
    }

    func didEndEditing(sender: ExpenseView, expense: Expense?) {
        if let expense = expense {
            delegate?.addedExpense(expense: expense)
        }
        delegate?.collapseCell(sender: self)
        resetView()
    }
    
    func pushRightBBI(_ bbi: UIBarButtonItem, sender: Any?) {
        rightBBIStack.append(bbi)
        delegate?.setRightBBI(rightBBIStack.last!)
    }
    
    func popRightBBI(sender: Any?) {
        _ = rightBBIStack.popLast()
        delegate?.setRightBBI(rightBBIStack.last)
    }
    
    func pushLeftBBI(_ bbi: UIBarButtonItem, sender: Any?) {
        leftBBIStack.append(bbi)
        delegate?.setLeftBBI(leftBBIStack.last!)
    }
    
    func popLeftBBI(sender: Any?) {
        _ = leftBBIStack.popLast()
        delegate?.setLeftBBI(leftBBIStack.last)
    }
    
    func disableRightBBI(sender: Any?) {
        if let bbi = rightBBIStack.last {
            bbi.isEnabled = false
            delegate?.setRightBBI(bbi)
        }
    }
    
    func enableRightBBI(sender: Any?) {
        if let bbi = rightBBIStack.last {
            bbi.isEnabled = true
            delegate?.setRightBBI(bbi)
        }
    }

    func disableLeftBBI(sender: Any?) {
        if let bbi = leftBBIStack.last {
            bbi.isEnabled = false
            delegate?.setLeftBBI(bbi)
        }
    }
    
    func enableLeftBBI(sender: Any?) {
        if let bbi = leftBBIStack.last {
            bbi.isEnabled = true
            delegate?.setLeftBBI(bbi)
        }
    }
}

protocol AddExpenseTableViewCellDelegate: class {
    func expandCell(sender: ExpenseTableViewCell)
    func collapseCell(sender: ExpenseTableViewCell)
    func addedExpense(expense: Expense)
    func setRightBBI(_ bbi: UIBarButtonItem?)
    func setLeftBBI(_ bbi: UIBarButtonItem?)
    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?, sender: Any?)
    var visibleHeight: CGFloat { get }
}
