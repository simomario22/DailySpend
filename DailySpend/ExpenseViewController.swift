//
//  ExpenseViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/30/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class ExpenseViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var notesTextView: UITextView!
    
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let datePicker = UIDatePicker()
    let dismissButton = UIButton()
    
    var expense: Expense?
    var keyboardHeight: CGFloat?
    var selectedDate: Date?
    var originalNotesFrame: CGRect?
    var amountConstraint: NSLayoutConstraint?
    var descriptionConstraint: NSLayoutConstraint?


    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(keyboardWillChangeFrame),
                       name:NSNotification.Name.UIKeyboardWillChangeFrame,
                       object: nil)

        // Set right bar button item
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save,
                                         target: self,
                                         action: #selector(save))
        navigationItem.rightBarButtonItem = saveButton
        
        // Set expense data if someone set it on this object
        if let expense = expense {
            amountField.text = String.formatAsCurrency(amount: expense.amount!.doubleValue)
            descriptionField.text = expense.shortDescription!
            selectedDate = expense.day!.date!
            setDateLabel(date: selectedDate!)
            notesTextView.text = expense.notes
        }
        originalNotesFrame = self.notesTextView.frame
        notesTextView.removeConstraints(notesTextView.constraints)

        let resignAllButton = UIButton()
        resignAllButton.backgroundColor = UIColor.clear
        resignAllButton.frame = view.bounds
        resignAllButton.addTarget(self,
                                  action: #selector(resignResponders),
                                  for: UIControlEvents.touchUpInside)
        
        self.view.insertSubview(resignAllButton, at: 0)
    }
    
    func resignResponders() {
        self.amountField.resignFirstResponder()
        self.descriptionField.resignFirstResponder()
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
        var width = descriptionField.text!.size(attributes: attr).width
        
        while width > maxWidth && fontSize > minFontSize {
            fontSize -= 1
            attr = [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize,
                                                           weight: UIFontWeightLight)]
            width = descriptionField.text!.size(attributes: attr).width
        }
        descriptionField.font = UIFont.systemFont(ofSize: fontSize,
                                                  weight: UIFontWeightLight)
        
        // Update widths of text fields (with constraints).
        if descriptionConstraint == nil {
            descriptionConstraint = NSLayoutConstraint(item: descriptionField,
                                                       attribute: .width,
                                                       relatedBy: .equal,
                                                       toItem: nil,
                                                       attribute: .notAnAttribute,
                                                       multiplier: 1,
                                                       constant: maxWidth)
            self.view.addConstraint(descriptionConstraint!)
        }
    }
    
    @IBAction func amountChanged(_ sender: UITextField) {
        let amount = sender.text!.parseValidAmount(maxLength: 8)
        sender.text = String.formatAsCurrency(amount: amount)
        fixFrames()
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.descriptionField.resignFirstResponder()
        self.amountField.resignFirstResponder()
        perform(#selector(editNotes), with: self, afterDelay: 0.1)
    }

    @IBAction func editNotes() {
        let topHeight = UIApplication.shared.statusBarFrame.height +
                        self.navigationController!.navigationBar.frame.height
        
        // Set right bar button item
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self,
                                         action: #selector(dismissNotes))
        navigationItem.rightBarButtonItem = doneButton
        
        // Animate slide up.
        UIView.animate(withDuration: 0.1, animations: {
            let width = self.view.bounds.size.width
            let height = self.view.bounds.size.height - (self.keyboardHeight ?? 216)
            let newFrame = CGRect(x: 0,
                                  y: topHeight,
                                  width: width,
                                  height:  height)
            self.notesTextView.frame = newFrame
        }, completion: { (completed: Bool) in
            self.notesTextView.becomeFirstResponder()
        })

    }
    
    func dismissNotes() {
        // Animate slide up.
        UIView.animate(withDuration: 0.1, animations: {
            // We aren't resetting the original frame!!
            self.notesTextView.frame = self.originalNotesFrame!
        }, completion: { (completed: Bool) in
            self.notesTextView.resignFirstResponder()
            
            // Set right bar button item
            let saveButton = UIBarButtonItem(barButtonSystemItem: .save,
                                             target: self,
                                             action: #selector(self.save))
            self.navigationItem.rightBarButtonItem = saveButton
        })
    }
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        let key = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]
        if let frame = (key as? NSValue)?.cgRectValue {
            keyboardHeight = frame.size.height
            
            // Animate height change.
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.5)
            UIView.setAnimationCurve(.easeInOut)
            notesTextView.frame.size.height = view.bounds.height -
                                                self.keyboardHeight!
            UIView.commitAnimations()
        }
    }
    
    @IBAction func editDate(_ sender: UIButton?) {
        // Find earliest day.
//        let earliestDayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
//        let earliestDaySortDesc = NSSortDescriptor(key: "date_", ascending: true)
//        earliestDayFetchReq.sortDescriptors = [earliestDaySortDesc]
//        earliestDayFetchReq.fetchLimit = 1
//        let earliestDayResults = try! context.fetch(earliestDayFetchReq)
        
        
        // Set up date picker.
//        let earliestDate = earliestDayResults[0].date
        datePicker.minimumDate = nil
        datePicker.maximumDate = Date()
        datePicker.setDate(selectedDate ?? Date(), animated: false)
        datePicker.datePickerMode = .date
        datePicker.removeTarget(self,
                                action: #selector(datePickerChanged(sender:)),
                                for: .valueChanged)
        datePicker.addTarget(self,
                             action: #selector(datePickerChanged(sender:)),
                             for: .valueChanged)
        datePicker.frame = CGRect(x: 0,
                                  y: view.bounds.size.height,
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
        self.descriptionField.resignFirstResponder()
        
        // Animate slide up.
        UIView.animate(withDuration: 0.5, animations: {
            let dpHeight = self.datePicker.frame.height
            let dPFrame = self.datePicker.frame.offsetBy(dx: 0, dy: -dpHeight)
            let dBFrame = self.dismissButton.frame.offsetBy(dx: 0, dy: -dpHeight)
            self.datePicker.frame = dPFrame
            self.dismissButton.frame = dBFrame
            let bgColor = UIColor.init(colorLiteralRed: 0,
                                       green: 0,
                                       blue: 0,
                                       alpha: 0.1)
            self.dismissButton.backgroundColor = bgColor
        })
    }
    
    func datePickerChanged(sender: UIDatePicker) {
        selectedDate = datePicker.date
    }
    
    func dismissDatePicker() {
        selectedDate = datePicker.date
        
        setDateLabel(date: selectedDate!)
        
        // Animate slide down.
        UIView.animate(withDuration: 0.5, animations: {
            let dPHeight = self.datePicker.frame.height
            let dPFrame = self.datePicker.frame.offsetBy(dx: 0, dy: dPHeight)
            let dBFrame = self.dismissButton.frame.offsetBy(dx: 0, dy: dPHeight)
            self.datePicker.frame = dPFrame
            self.dismissButton.frame = dBFrame
            self.dismissButton.backgroundColor = UIColor.clear
        }, completion:  { (finished: Bool) in
            self.datePicker.removeFromSuperview()
            self.dismissButton.removeFromSuperview()
        })
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
        let amount = amountField.text!.parseValidAmount(maxLength: 8)
        let shortDescription = descriptionField.text!
        if amount == 0 ||
            shortDescription.characters.count == 0 ||
            selectedDate == nil {
            let message = "Please enter valid values for amount, description, and date."
            let alert = UIAlertController(title: "Invalid Fields",
                                          message: message,
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay",
                                          style: UIAlertActionStyle.default,
                                          handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            let navVCCount = navigationController!.viewControllers.count
            let prevVC = navigationController!.viewControllers[navVCCount - 2]
            let shouldChangePopVC =
                prevVC is ReviewTableViewController &&
                expense != nil &&
                selectedDate!.beginningOfDay != expense!.day!.date!.beginningOfDay
            
            // Create days up to today.
            let earliestDayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
            let earliestDaySortDesc = NSSortDescriptor(key: "date_", ascending: true)
            earliestDayFetchReq.sortDescriptors = [earliestDaySortDesc]
            earliestDayFetchReq.fetchLimit = 1
            let earliestDayResults = try! context.fetch(earliestDayFetchReq)
            let earliestDay = earliestDayResults[0].date!
            let needsNewDays = selectedDate!.beginningOfDay < earliestDay.beginningOfDay
            if needsNewDays {
                // Create from the selectedDate to the begininng of the day on
                let from = selectedDate!
                let to = earliestDayResults[0].date!
                Day.createDays(context: context, from: from, to: to)
                appDelegate.saveContext()
            }
            
            if (expense == nil) {
                expense = Expense(context: context)
            }
            expense!.amount = Decimal(amountField.text!.parseValidAmount(maxLength: 8))
            expense!.shortDescription = shortDescription
            expense!.notes = notesTextView.text
            expense!.day = Day.get(context: context, date: selectedDate!)
            appDelegate.saveContext()
            
            if shouldChangePopVC {
                if let day = Day.get(context: context, date: selectedDate!) {
                    var vcs = navigationController!.viewControllers
                    
                    let vc = storyboard!.instantiateViewController(withIdentifier: "Review")
                    let vc2 = storyboard!.instantiateViewController(withIdentifier: "Review")
                    let reviewDayVC = vc as! ReviewTableViewController
                    reviewDayVC.day = day
                    reviewDayVC.mode = .Days
                    
                    let adjustments = day.sortedAdjustments!
                    let reviewAdjustmentsVC = vc2 as! ReviewTableViewController
                    reviewAdjustmentsVC.day = day
                    reviewAdjustmentsVC.dayAdjustments = adjustments
                    reviewAdjustmentsVC.monthAdjustments = day.relevantMonthAdjustments
                    
                    reviewAdjustmentsVC.mode = .DayAdjustments
                    
                    vcs[vcs.count - 2] = reviewDayVC
                    if vcs[vcs.count - 3] is ReviewTableViewController {
                        // The user has three levels of VCs in this nav controller.
                        let vc3 = storyboard!.instantiateViewController(withIdentifier: "Review")
                        let reviewMonthVC = vc3 as! ReviewTableViewController
                        reviewMonthVC.month = day.month!
                        reviewMonthVC.mode = .Months
                        vcs[vcs.count - 3] = reviewMonthVC
                    }
                    navigationController!.viewControllers = vcs
                }
            }
            _ = navigationController?.popViewController(animated: true)
        }

    }

}
