//
//  DayAdjustmentViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/1/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData 

class DayAdjustmentViewController: UIViewController {
    @IBOutlet weak var addDeductControl: UISegmentedControl!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var reasonField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var additionalAmountLabel: UILabel!
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let datePicker = UIDatePicker()
    let dismissButton = UIButton()
    
    var amountConstraint: NSLayoutConstraint?
    var reasonConstraint: NSLayoutConstraint?
    
    var selectedDate: Date?
    var dayAdjustment: DayAdjustment?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if dayAdjustment != nil {
            setAddDeductSegment(negOrPos: dayAdjustment!.amount!)
            amountField.text = String.formatAsCurrency(amount: abs(dayAdjustment!.amount!.doubleValue))
            reasonField.text = dayAdjustment!.reason
            selectedDate = dayAdjustment!.dateAffected
            setDateLabel(date: selectedDate!)
            additionalAmountLabel.isHidden = true
            fixFrames()
        } else {
            addDeductControl.selectedSegmentIndex = 1
            selectedDate = Date()
            setDateLabel(date: selectedDate!)
        }
                
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        if let tabBarCtrl = tabBarController {
            // Set right bar button item
            tabBarCtrl.navigationItem.rightBarButtonItem = saveButton
            
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            navigationItem.rightBarButtonItem = saveButton
            tabBarCtrl.navigationItem.leftBarButtonItem = cancelButton
        } else {
            navigationItem.rightBarButtonItem = saveButton
        }
        let resignAllButton = UIButton()
        resignAllButton.backgroundColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0)
        resignAllButton.frame = view.bounds
        resignAllButton.addTarget(self, action: #selector(resignResponders), for: UIControlEvents.touchUpInside)
        
        self.view.insertSubview(resignAllButton, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        
        if let tabBarCtrl = tabBarController {
            // Set right bar button item
            tabBarCtrl.navigationItem.rightBarButtonItem = saveButton
            
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            navigationItem.rightBarButtonItem = saveButton
            tabBarCtrl.navigationItem.leftBarButtonItem = cancelButton
        } else {
            navigationItem.rightBarButtonItem = saveButton
        }
    }
    
    func resignResponders() {
        self.amountField.resignFirstResponder()
        self.reasonField.resignFirstResponder()
    }
    
    func cancel() {
        self.tabBarController?.dismiss(animated: true, completion: nil)
    }
    
    func save() {
        let posNeg: Decimal = addDeductControl.selectedSegmentIndex == 1 ? 1 : -1
        let amount = Decimal(amountField.text!.parseValidAmount(maxLength: 8)) * posNeg
        let reason = reasonField.text!
        if amount == 0 ||
            reason.characters.count == 0 ||
            selectedDate == nil {
            let alert = UIAlertController(title: "Invalid Fields", message: "Please enter valid values for amount, reaons, and date received.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            if (dayAdjustment == nil) {
                dayAdjustment = DayAdjustment(context: context)
            }
            dayAdjustment!.amount = amount
            dayAdjustment!.reason = reason
            dayAdjustment!.dateCreated = dayAdjustment!.dateCreated ?? Date()
            dayAdjustment!.dateAffected = selectedDate
            dayAdjustment!.day = Day.get(context: context, date: selectedDate!)
            
            appDelegate.saveContext()
            
            tabBarController?.navigationController?.dismiss(animated: true, completion: nil)
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func fixFrames() {
        let maxWidth = self.view.bounds.width - 20
        
        // Update widths of text fields (with constraints).
        if amountConstraint == nil {
            amountConstraint = NSLayoutConstraint(item: amountField,
                                                  attribute: .width,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: maxWidth)
            self.view.addConstraint(amountConstraint!)
        }
        
        
        // Determine max font size that can fit in the space available.
        var fontSize: CGFloat = 28
        let minFontSize: CGFloat = 17
        
        let font = UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightLight)
        var attr = [NSFontAttributeName: font]
        
        //var attr = [NSFontAttributeName: descriptionField.font!.withSize(fontSize)]
        var width = reasonField.text!.size(attributes: attr).width
        
        while width > maxWidth && fontSize > minFontSize {
            fontSize -= 1
            attr = [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightLight)]
            width = reasonField.text!.size(attributes: attr).width
        }
        reasonField.font = UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightLight)
        
        // Update widths of text fields (with constraints).
        if reasonConstraint == nil {
            reasonConstraint = NSLayoutConstraint(item: reasonField,
                                                  attribute: .width,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: maxWidth)
            self.view.addConstraint(reasonConstraint!)
        }
    }
    
    @IBAction func amountChanged(_ sender: UITextField) {
        let amount = sender.text!.parseValidAmount(maxLength: 8)
        sender.text = String.formatAsCurrency(amount: amount)
        fixFrames()
    }
    
    func setAddDeductSegment(negOrPos: Decimal) {
        if negOrPos < 0 {
            addDeductControl.setEnabled(true, forSegmentAt: 1)
        } else {
            addDeductControl.setEnabled(true, forSegmentAt: 0)
        }
    }
    
    func setDateLabel(date: Date) {
        // Set label
        if date.beginningOfDay == Date().beginningOfDay {
            dateButton.setTitle("Today", for: .normal)
        } else if date.beginningOfDay == Date().subtract(days: 1).beginningOfDay {
            dateButton.setTitle("Yesterday", for: .normal)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            dateButton.setTitle(dateFormatter.string(from: date), for: .normal)
        }
    }
    
    @IBAction func editDate(_ sender: UIButton?) {
        // Find earliest day.
        let earliestDayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let earliestDaySortDesc = NSSortDescriptor(key: "date_", ascending: true)
        earliestDayFetchReq.sortDescriptors = [earliestDaySortDesc]
        earliestDayFetchReq.fetchLimit = 1
        let earliestDayResults = try! context.fetch(earliestDayFetchReq)
        
        
        // Set up date picker.
        let earliestDate = earliestDayResults[0].date
        datePicker.minimumDate = earliestDate
        datePicker.maximumDate = Date()
        datePicker.setDate(selectedDate ?? Date(), animated: false)
        datePicker.datePickerMode = .date
        datePicker.frame = CGRect(x: 0, y: view.bounds.size.height,
                                  width: view.bounds.size.width,
                                  height: datePicker.intrinsicContentSize.height)
        
        
        dismissButton.backgroundColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0)
        dismissButton.frame = view.bounds
        dismissButton.addTarget(self, action: #selector(dismissDatePicker), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(dismissButton)
        self.view.addSubview(datePicker)
        
        self.amountField.resignFirstResponder()
        self.reasonField.resignFirstResponder()
        
        // Animate slide up.
        UIView.animate(withDuration: 0.5, animations: {
            self.datePicker.frame = self.datePicker.frame.offsetBy(dx: 0, dy: -self.datePicker.frame.height)
            self.dismissButton.frame = self.dismissButton.frame.offsetBy(dx: 0, dy: -self.datePicker.frame.height)
            self.dismissButton.backgroundColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.1)
        })
    }
    
    func dismissDatePicker() {
        selectedDate = datePicker.date
        
        setDateLabel(date: selectedDate!)
        
        // Animate slide down.
        UIView.animate(withDuration: 0.5, animations: {
            self.datePicker.frame = self.datePicker.frame.offsetBy(dx: 0, dy: self.datePicker.frame.height)
            self.dismissButton.frame = self.dismissButton.frame.offsetBy(dx: 0, dy: self.datePicker.frame.height)
            self.dismissButton.backgroundColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0)
        }, completion:  { (finished: Bool) in
            self.datePicker.removeFromSuperview()
            self.dismissButton.removeFromSuperview()
        })
        
    }

}
