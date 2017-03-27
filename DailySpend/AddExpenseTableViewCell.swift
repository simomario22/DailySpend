//
//  AddExpenseTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class AddExpenseTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    weak var delegate:AddExpenseTableViewCellDelegate?
    var currentlyEditing = false
    var selectedDate: Date?
    var notes: String?
    var keyboardHeight: CGFloat?
    
    let datePicker = UIDatePicker()
    let dismissButton = UIButton()
    let notesTextView = UITextView()

    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var addExpenseLabel: UILabel!
    
    override func prepareForReuse() {
        currentlyEditing = false
        super.prepareForReuse()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 1 {
            // The user is typing in the amount field
            textField.resignFirstResponder()
            descriptionField.becomeFirstResponder()
        } else if textField.tag == 2 {
            // The user is typing in the description field.
            textField.resignFirstResponder()
        }
        return true
    }
    
    @IBAction func editNotes(_ sender: UIButton) {
        checkForFirstEdit()
        
        notesTextView.text = notes ?? ""
        notesTextView.isEditable = true
        notesTextView.frame = CGRect(x: 0,
                                     y: bounds.size.height,
                                     width: bounds.size.width,
                                     height: bounds.size.height - (keyboardHeight ?? 216) )
        self.addSubview(notesTextView)
        
        // Animate slide up.
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.5)
        UIView.setAnimationCurve(.easeInOut)
        notesTextView.frame = notesTextView.frame.offsetBy(dx: 0, dy: -bounds.size.height)
        UIView.commitAnimations()
        
        delegate?.didOpenNotes(sender: self)
    }
    
    @IBAction func editDate(_ sender: UIButton?) {
        checkForFirstEdit()
        
        // Find earliest day.
        let earliestDayFetchReq: NSFetchRequest<Day> = Day.fetchRequest()
        let earliestDaySortDesc = NSSortDescriptor(key: "date_", ascending: true)
        earliestDayFetchReq.sortDescriptors?.append(earliestDaySortDesc)
        earliestDayFetchReq.fetchLimit = 1
        let earliestDayResults = try! context.fetch(earliestDayFetchReq)
        
        
        // Set up date picker.
        let earliestDate = earliestDayResults[0].date
        datePicker.minimumDate = earliestDate
        datePicker.maximumDate = Date()
        datePicker.setDate(selectedDate ?? Date(), animated: false)
        datePicker.datePickerMode = .date
        datePicker.frame = CGRect(x: 0, y: bounds.size.height,
                                  width: bounds.size.width, height: datePicker.intrinsicContentSize.height)

        
        dismissButton.backgroundColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.2)
        dismissButton.frame = self.bounds
        dismissButton.addTarget(self, action: #selector(dismissDatePicker), for: UIControlEvents.touchUpInside)
        
        self.addSubview(dismissButton)

        self.addSubview(datePicker)
        
        // Animate slide up.
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.5)
        UIView.setAnimationCurve(.easeInOut)
        datePicker.frame = datePicker.frame.offsetBy(dx: 0, dy: -datePicker.frame.height)
        UIView.commitAnimations()
    }
    
    func dismissDatePicker() {
        selectedDate = datePicker.date
        
        // Set label
        if selectedDate?.beginningOfDay == Date().beginningOfDay {
            dateButton.setTitle("Today", for: .normal)
        } else if selectedDate?.beginningOfDay == Date().subtract(days: 1).beginningOfDay {
            dateButton.setTitle("Yesterday", for: .normal)

        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            dateButton.setTitle(dateFormatter.string(from: selectedDate!), for: .normal)
        }
        
        // Animate slide down.
        UIView.animate(withDuration: 0.5, animations: {
            self.datePicker.frame = self.datePicker.frame.offsetBy(dx: 0, dy: self.datePicker.frame.height)
        }, completion:  { (finished: Bool) in
            self.datePicker.removeFromSuperview()
        })
        
        dismissButton.removeFromSuperview()
    }
    
    @IBAction func editedAmount(_ sender: UITextField) {
        print("editedAmount")
        checkForFirstEdit()
        let amount = sender.text!.parseValidAmount(maxLength: 8)
        sender.text = String.formatAsCurrency(amount: amount)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("textFieldShouldBeginEditing")
        checkForFirstEdit()
        return true
    }

    @IBAction func checkForFirstEdit() {
        print("checkForFirstEdit")
        if currentlyEditing == false {
            delegate?.didBeginEditing(sender: self)
            
            UIView.animate(withDuration: 0.5, animations: {
                // Set date label to today.
                self.selectedDate = Date()
                self.dateButton.setTitleColor(self.tintColor, for: .normal)
                self.dateButton.setTitle("Today", for: .normal)
                
                // Change color of "Add Expense" to black.
                self.addExpenseLabel.textColor = UIColor.black
            })
            currentlyEditing = true
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
        if keyboardHeight == nil {
            let info = notification.userInfo!
            let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            keyboardHeight = keyboardFrame.size.height
            
//            // Animate height change.
//            UIView.beginAnimations(nil, context: nil)
//            UIView.setAnimationDuration(0.5)
//            UIView.setAnimationCurve(.easeInOut)
//            notesTextView.frame.size.height = bounds.height - keyboardHeight!
//            UIView.commitAnimations()
        }
    }
    
    func dismissNotes() {
        notes = notesTextView.text
        let tenCharIndex = notes!.index(notes!.startIndex, offsetBy: 11)
        notesButton.setTitleColor(self.tintColor, for: .normal)
        notesButton.setTitle(notes!.substring(to: tenCharIndex) + "...", for: .normal)
        
        // Animate slide down.
        UIView.animate(withDuration: 0.5, animations: {
            self.notesTextView.frame = self.notesTextView.frame.offsetBy(dx: 0, dy: self.bounds.height)
        }, completion:  { (finished: Bool) in
            self.notesTextView.removeFromSuperview()
        })
    }
    
    func processAndSend() {
        let amount = amountField.text!.parseValidAmount(maxLength: 8)
        let shortDescription = descriptionField.text!
        if amount == 0 ||
            description.characters.count == 0 ||
            selectedDate == nil {
            delegate?.invalidFields(sender: self)
        } else {
        let expense = Expense(context: context)
            expense.amount = Decimal(amountField.text!.parseValidAmount(maxLength: 8))
            expense.shortDescription = shortDescription
            expense.date = selectedDate!.beginningOfDay
            expense.notes = notes
            expense.recordedDate = Date()
            expense.day = Day.get(context: context, date: selectedDate!)
            delegate?.completedExpense(sender: self, expense: expense)
            self.resetView()
            currentlyEditing = false
        }
    }
    
    func resetView() {
        let greyColor = UIColor.init(colorLiteralRed: 192.0 / 255.0,
                                     green: 192.0 / 255.0,
                                     blue: 198.0 / 255.0,
                                     alpha: 1)
        UIView.animate(withDuration: 0.5, animations: {
            self.addExpenseLabel.textColor = greyColor
            
            self.amountField.text = ""
            
            self.descriptionField.text = ""
        
            self.dateButton.setTitle("Date", for: .normal)
            self.dateButton.setTitleColor(greyColor, for: .normal)
            
            self.notesButton.setTitle("Notes", for: .normal)
            self.notesButton.setTitleColor(greyColor, for: .normal)
        })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        amountField.delegate = self
        descriptionField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(dismissNotes), name: NSNotification.Name.init(rawValue: "PressedDoneButton"), object: UIApplication.shared)
        NotificationCenter.default.addObserver(self, selector: #selector(processAndSend), name: NSNotification.Name.init(rawValue: "PressedSaveButton"), object: UIApplication.shared)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

protocol AddExpenseTableViewCellDelegate: class {
    func didBeginEditing(sender: AddExpenseTableViewCell)
    func didOpenNotes(sender: AddExpenseTableViewCell)
    func completedExpense(sender: AddExpenseTableViewCell, expense: Expense)
    func invalidFields(sender: AddExpenseTableViewCell)
}
