//
//  MonthAdjustmentViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/1/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class MonthAdjustmentViewController: UIViewController {
    
    @IBOutlet weak var addDeductControl: UISegmentedControl!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var reasonField: UITextField!
    @IBOutlet weak var dateReceivedButton: UIButton!
    @IBOutlet weak var additionalAmountLabel: UILabel!
    
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let datePicker = UIDatePicker()
    let dismissButton = UIButton()
    
    var amountConstraint: NSLayoutConstraint?
    var reasonConstraint: NSLayoutConstraint?
    
    var selectedDate: Date?
    var monthAdjustment: MonthAdjustment?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if monthAdjustment != nil {
            setAddDeductSegment(negOrPos: monthAdjustment!.amount!)
            let absAmount = abs(monthAdjustment!.amount!.doubleValue)
            amountField.text = String.formatAsCurrency(amount: absAmount)
            reasonField.text = monthAdjustment!.reason
            selectedDate = monthAdjustment!.dateEffective
            setDateLabel(date: selectedDate!)
            //additionalAmountLabel.isHidden = true
            fixFrames()
        } else {
            addDeductControl.selectedSegmentIndex = 1
            selectedDate = Date()
            setDateLabel(date: selectedDate!)
        }

        
        let resignAllButton = UIButton()
        resignAllButton.backgroundColor = UIColor.clear
        resignAllButton.frame = view.bounds
        resignAllButton.addTarget(self,
                                  action: #selector(resignResponders),
                                  for: UIControlEvents.touchUpInside)
        
        self.view.insertSubview(resignAllButton, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save,
                                         target: self,
                                         action: #selector(save))
        
        if let tabBarCtrl = tabBarController {
            // Set right bar button item
            tabBarCtrl.navigationItem.rightBarButtonItem = saveButton
            
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                               target: self,
                                               action: #selector(cancel))
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
            let message = "Please enter valid values for amount, reaons, and date received."
            let alert = UIAlertController(title: "Invalid Fields",
                                          message: message,
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay",
                                          style: UIAlertActionStyle.default,
                                          handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            
            let oldDate: Date? = monthAdjustment?.dateEffective
            if (monthAdjustment == nil) {
                monthAdjustment = MonthAdjustment(context: context)
            }
            
            monthAdjustment!.amount = amount
            monthAdjustment!.reason = reason
            monthAdjustment!.dateCreated = monthAdjustment!.dateCreated ?? Date()
            monthAdjustment!.dateEffective = selectedDate
            monthAdjustment!.month = Month.get(context: context, dateInMonth: selectedDate!)

            appDelegate.saveContext()
            
            tabBarController?.navigationController?.dismiss(animated: true, completion: nil)
            
            func fromDayAdjustmentsReview() -> Bool {
                let navCtrlCount = self.navigationController!.viewControllers.count
                let vc = self.navigationController!.viewControllers[navCtrlCount - 2]
                let reviewController = vc as! ReviewTableViewController
                return reviewController.mode == .DayAdjustments
            }
            
            
            shouldChangeNavVCs:
            if tabBarController == nil &&
               oldDate != nil &&
               fromDayAdjustmentsReview() &&
               oldDate!.beginningOfDay < monthAdjustment!.dateEffective!.beginningOfDay {
                // This is an edit from a day adjustments review controlller, and
                // the old date is no longer affected by this adjustment. Change
                // to the first date that is.
                let dayTry = Day.get(context: context, date: selectedDate!)
                if dayTry == nil {
                    break shouldChangeNavVCs
                }
                var vcs = navigationController!.viewControllers
                let day = dayTry!
                let vc = storyboard!.instantiateViewController(withIdentifier: "Review")
                let reviewDayVC = vc as! ReviewTableViewController
                reviewDayVC.day = day
                reviewDayVC.mode = .Days
                
                let adjustments = day.sortedAdjustments!
                let vc2 = storyboard!.instantiateViewController(withIdentifier: "Review")
                let reviewAdjustmentsVC = vc2 as! ReviewTableViewController
                reviewAdjustmentsVC.day = day
                reviewAdjustmentsVC.dayAdjustments = adjustments
                reviewAdjustmentsVC.monthAdjustments = day.relevantMonthAdjustments
                
                reviewAdjustmentsVC.mode = .DayAdjustments
                
                vcs[vcs.count - 2] = reviewAdjustmentsVC
                vcs[vcs.count - 3] = reviewDayVC
                if vcs[vcs.count - 4] is ReviewTableViewController {
                    // The user has three levels of VCs in this nav controller.
                    let vc3 = storyboard!.instantiateViewController(withIdentifier: "Review")
                    let reviewMonthVC = vc3 as! ReviewTableViewController
                    reviewMonthVC.month = day.month!
                    reviewMonthVC.mode = .Months
                    vcs[vcs.count - 4] = reviewMonthVC
                }
                navigationController!.viewControllers = vcs
            }
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
            attr = [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize,
                                                           weight: UIFontWeightLight)]
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
            addDeductControl.selectedSegmentIndex = 0
        } else {
            addDeductControl.selectedSegmentIndex = 1
        }
    }
    
    func setDateLabel(date: Date) {
        // Set label
        if date.beginningOfDay == Date().beginningOfDay {
            dateReceivedButton.setTitle("Today", for: .normal)
        } else if date.beginningOfDay == Date().subtract(days: 1).beginningOfDay {
            dateReceivedButton.setTitle("Yesterday", for: .normal)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            dateReceivedButton.setTitle(dateFormatter.string(from: date), for: .normal)
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
        datePicker.removeTarget(self,
                                action: #selector(datePickerChanged(sender:)),
                                for: .valueChanged)
        datePicker.addTarget(self,
                             action: #selector(datePickerChanged(sender:)),
                             for: .valueChanged)
        datePicker.frame = CGRect(x: 0, y: view.bounds.size.height,
                                  width: view.bounds.size.width,
                                  height: datePicker.intrinsicContentSize.height)
        
        
        dismissButton.backgroundColor = UIColor.clear
        dismissButton.frame = view.bounds
        dismissButton.addTarget(self,
                                action: #selector(dismissDatePicker),
                                for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(dismissButton)
        self.view.addSubview(datePicker)
        
        self.amountField.resignFirstResponder()
        self.reasonField.resignFirstResponder()
        
        // Animate slide up.
        UIView.animate(withDuration: 0.2, animations: {
            var tabBarHeight: CGFloat = 0
            if let tabCtrl = self.tabBarController {
                tabBarHeight = tabCtrl.tabBar.bounds.size.height
            }
            let offset = -self.datePicker.frame.height - tabBarHeight
            let dPFrame = self.datePicker.frame.offsetBy(dx: 0, dy: offset)
            let dBFrame = self.dismissButton.frame.offsetBy(dx: 0, dy: offset)
            self.datePicker.frame = dPFrame
            self.dismissButton.frame = dBFrame
            self.dismissButton.backgroundColor = UIColor.init(colorLiteralRed: 0,
                                                              green: 0,
                                                              blue: 0,
                                                              alpha: 0.1)
        })
    }
    
    func datePickerChanged(sender: UIDatePicker) {
        selectedDate = datePicker.date
    }
    
    func dismissDatePicker() {
        setDateLabel(date: selectedDate!)
        
        // Animate slide down.
        UIView.animate(withDuration: 0.2, animations: {
            let dpHeight = self.datePicker.frame.height
            self.datePicker.frame = self.datePicker.frame.offsetBy(dx: 0, dy: dpHeight)
            self.dismissButton.frame = self.dismissButton.frame.offsetBy(dx: 0, dy: dpHeight)
            self.dismissButton.backgroundColor = UIColor.clear
        }, completion:  { (finished: Bool) in
            self.datePicker.removeFromSuperview()
            self.dismissButton.removeFromSuperview()
        })
        
    }

}
