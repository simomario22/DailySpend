//
//  ExpenseView.swift
//  DailySpend
//
//  Created by Josh Sherick on 6/29/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ExpenseView: UIView {
    var scrollView: UIScrollView = UIScrollView()

    var amountLabel = UIButton(type: .custom)
    var descriptionLabel = UIButton(type: .custom)
    var dateLabel = UIButton(type: .custom)
    var notesLabel = UIButton(type: .custom)
    var imageLabel = UIButton(type: .custom)
    
    var amountField = BorderedTextField()
    var descriptionField = BorderedTextField()
    var dateField = BorderedTextField()
    var notesField = BorderedTextField()
    var imageSelector: ImageSelectorView = ImageSelectorView()
    
    var delegate: ExpenseViewDelegate!
    var dataSource: ExpenseViewDataSource!
    
    var keyboardHeight: CGFloat?
    
    var editing = false
    
    var dismissButton: UIButton?

    override func layoutSubviews() {
        super.layoutSubviews()
        updateSubviewFrames()
    }
    
    init(optionalCoder: NSCoder? = nil, optionalFrame: CGRect? = nil) {
        if let coder = optionalCoder {
            super.init(coder: coder)!
        } else if let frame = optionalFrame {
            super.init(frame: frame)
        } else {
            super.init()
        }
        
        // Scroll view is only for scrolling when the keyboard is on screen.
        scrollView.bounces = false
        
        let lightFont = UIFont(name: "HelveticaNeue-Light", size: 24.0)
        let normalFont = UIFont(name: "HelveticaNeue", size: 24.0)
        let borderColor = UIColor(red:0.71, green:0.73, blue:0.76, alpha:1.00)
        let borderWidth: CGFloat = 1.0
        
        func setup(button: UIButton, _ text: String, touchUpInside: (() -> ())? = nil) {
            button.setTitle(text, for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.titleLabel?.font = normalFont
            if touchUpInside != nil {
                button.add(for: .touchUpInside, touchUpInside!)
            }
        }
        
        func setup(field: BorderedTextField, _ tag: Int,
                        text: String? = nil,
                        placeholder: String? = nil) {
            field.tag = tag
            field.text = text
            if text != nil {
                field.textColor = self.tintColor
            }
            field.textAlignment = .right
            field.placeholder = placeholder
            field.font = lightFont
            field.clipsToBounds = false
            //field.addBottomBorder(color: borderColor, width: borderWidth)
            field.delegate = self
        }
        
        // Set up visuals of all fields and labels.
        setup(button: amountLabel, "Amount") {
            self.uiElementInteraction()
            self.amountField.becomeFirstResponder()
        }
        setup(field: amountField, 1, placeholder: "$0.00")
        amountField.keyboardType = .numberPad
        amountField.addTarget(self, action: #selector(amountChanged(_:)),
                              for: .editingChanged)
        
        setup(button: descriptionLabel, "Description") {
            self.uiElementInteraction()
            self.descriptionField.becomeFirstResponder()
        }
        setup(field: descriptionField, 2,  placeholder: "Description")
        descriptionField.addTarget(self, action: #selector(descriptionChanged(_:)),
                              for: .editingChanged)
        
        setup(button: dateLabel, "Date") {
            self.uiElementInteraction()
            self.showDatePicker()
        }
        setup(field: dateField, 3, text: "Today")
        
        setup(button: notesLabel, "Notes") {
            self.uiElementInteraction()
            self.showNotes()
        }
        setup(field: notesField, 4, text: "View/Edit")
       
        setup(button: imageLabel, "Receipt")
        imageSelector.selectorDelegate = self

        // Add all subviews to scroll view.
        scrollView.addSubviews([amountLabel, descriptionLabel, dateLabel,
                                notesLabel, imageLabel, amountField,
                                descriptionField, dateField, notesField,
                                imageSelector])
        self.addSubview(scrollView)
        
        updateSubviewFrames()
        
        NotificationCenter.default.addObserver(self,
           selector: #selector(keyboardWillChangeFrame),
           name:NSNotification.Name.UIKeyboardWillChangeFrame,
           object: nil)
    }
    
    required convenience init(coder: NSCoder) {
        self.init(optionalCoder: coder)
    }
    
    override convenience init(frame: CGRect) {
        self.init(optionalFrame: frame)
    }
    
    func updateSubviewFrames() {
        let sideMargin: CGFloat = 16.0
        let innerHorizontalMargin: CGFloat = 10.0
        let innerVerticalMargin: CGFloat = 26.0
        
        let newWidth = bounds.size.width
        
        func setFrameForButton(_ button: UIButton, previousButton: UIButton?) {
            let attr = [NSFontAttributeName: button.titleLabel!.font!]
            let size = button.titleLabel!.text!.size(attributes: attr)
        
            button.frame = CGRect(
                x: sideMargin,
                y: previousButton == nil ? sideMargin :
                    previousButton!.frame.bottomEdge + innerVerticalMargin,
                width: size.width,
                height: button.intrinsicContentSize.height
            )
        }
        
        func setFramesForPair(button: UIButton,
                              field: UITextField,
                              previousButton: UIButton?) {
            setFrameForButton(button, previousButton: previousButton)
            
            field.frame = CGRect(
                x: button.frame.rightEdge + innerHorizontalMargin,
                y: button.frame.topEdge,
                width: newWidth - button.frame.rightEdge -
                    sideMargin - innerHorizontalMargin,
                height: button.frame.size.height
            )
        }
        
        scrollView.frame = bounds
        
        setFramesForPair(button: amountLabel,
                         field: amountField,
                         previousButton: nil)
        
        setFramesForPair(button: descriptionLabel,
                         field: descriptionField,
                         previousButton: amountLabel)
        
        setFramesForPair(button: dateLabel,
                         field: dateField,
                         previousButton: descriptionLabel)
        
        setFramesForPair(button: notesLabel,
                         field: notesField,
                         previousButton: dateLabel)
        
        setFrameForButton(imageLabel, previousButton: notesLabel)
        
        let imageSelectorHeight: CGFloat = 94.0
        let oldFrame = imageSelector.frame
        let newFrame = CGRect(
            x: imageLabel.frame.rightEdge + innerHorizontalMargin,
            y: imageLabel.center.y - (imageSelectorHeight / 2),
            width: newWidth - imageLabel.frame.rightEdge -
                sideMargin - innerHorizontalMargin,
            height: imageSelectorHeight
        )
        if oldFrame != newFrame {
            imageSelector.frame = newFrame
            if oldFrame.size.width != newFrame.size.width {
                imageSelector.recreateButtons()
            }
        }
        
        scrollView.contentSize = CGSize(width: newWidth,
                                        height: imageSelector.frame.bottomEdge)
    }
    
    func updateFieldValues() {
        // Populate text fields with expense data from dataSource
        if let amount = dataSource.amount {
            let amt = String.formatAsCurrency(amount: amount.doubleValue)
            self.amountField.text = amt
        } else {
            self.amountField.text = nil
        }
        
        descriptionField.text = dataSource.shortDescription
        self.descriptionChanged(descriptionField)
        
        dateField.text = humanReadableDate(dataSource.calDay)

        self.imageSelector.removeAllImages()
        if let containers = dataSource.imageContainers {
            // Add all images to image selector.
            for imageContainer in containers {
                self.imageSelector.addImage(image: imageContainer.image,
                                            imageName: imageContainer.imageName,
                                            imageType: imageContainer.imageType)
            }
        }
        
        // Scroll imageSelector to far right
        let selectorContentWidth = self.imageSelector.contentSize.width
        let selectorFrameWidth = self.imageSelector.frame.size.width
        self.imageSelector.contentOffset =
            CGPoint(x: selectorContentWidth - selectorFrameWidth,
                    y: 0)

    }
    
    func save() {
        if dataSource.amount == nil ||
            dataSource.amount!.doubleValue <= 0 ||
            dataSource.shortDescription!.characters.count == 0 {
            let message = "Please enter values for amount and description."
            let alert = UIAlertController(title: "Invalid Fields",
                                          message: message,
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay",
                                          style: UIAlertActionStyle.default,
                                          handler: nil))
            
            delegate.present(alert, animated: true, completion: nil, sender: self)
            return
        }
        
        if let expense = dataSource.save() {
            editing = false
            resignTextFieldsAsFirstResponder()
            delegate.popRightBBI(sender: self)
            delegate.popLeftBBI(sender: self)
            delegate.didEndEditing(sender: self, expense: expense)
            return
        }
        // There was an error.
        let message = "There was an error saving your expense. " +
        "If this occurs again, please contact support explaining what happened."
        let alert = UIAlertController(title: "Error Adding Expense",
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        delegate?.present(alert, animated: true, completion: nil, sender: self)
    }
    
    func cancel() {
        resignTextFieldsAsFirstResponder()
        dismissButton?.removeFromSuperview()
        delegate.popRightBBI(sender: self)
        delegate.popLeftBBI(sender: self)
        delegate.didEndEditing(sender: self, expense: nil)
        editing = false
    }

    func uiElementInteraction() {
        if !editing {
            editing = true
            delegate.didBeginEditing(sender: self)
            
            // Add save and cancel bar button items.
            let saveButton = UIBarButtonItem(barButtonSystemItem: .save,
                                             target: self,
                                             action: #selector(save))
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                               target: self,
                                               action: #selector(cancel))
            delegate.pushRightBBI(saveButton, sender: self)
            delegate.pushLeftBBI(cancelButton, sender: self)
        }
    }
    
    func humanReadableDate(_ day: CalendarDay) -> String {
        if day == CalendarDay() {
            return "Today"
        } else if day == CalendarDay().subtract(days: 1) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            return day.string(formatter: dateFormatter)
        }
    }
    
    // Possibly need @escaping here and not making the function an optional 
    // if there are issues?
    func insertDismissButton(removeOnPress: Bool = true,
                             under: UIView? = nil,
                             dismiss handler: (() -> Void)?) {
        dismissButton?.removeFromSuperview()
        dismissButton = UIButton(frame: scrollView.bounds)
        dismissButton!.backgroundColor = UIColor.clear
        dismissButton!.add(for: .touchUpInside) {
            if removeOnPress == true {
                self.dismissButton!.removeFromSuperview()
            }
            handler?()
        }
        scrollView.insertSubview(dismissButton!, belowSubview: under ?? amountField)
    }
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        let key = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]
        if let frame = (key as? NSValue)?.cgRectValue {
            keyboardHeight = frame.size.height
        }
    }
}

extension ExpenseView: ImageSelectorDelegate {
    func present(_ vc: UIViewController, animated: Bool,
                 completion: (() -> Void)?, sender: Any?) {
        delegate.present(vc, animated: true, completion: completion, sender: sender)
    }
    
    func addedImage(_ image: UIImage, imageName: String, imageType: String?) {
        let container = ImageContainer(image: image, imageName: imageName,
                                       imageType: imageType, saved: false)
        dataSource.addImage(container: container)
    }
    
    func removedImage(index: Int) {
        dataSource.removeImage(index: index)
    }
    
    func tappedButton() {
        uiElementInteraction()
    }
}

extension ExpenseView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        uiElementInteraction()

        switch textField.tag {
        case 1...2:
            // amountField or descriptionField
            insertDismissButton {
                textField.resignFirstResponder()
            }
            return true
        case 3:
            // dateField
            resignTextFieldsAsFirstResponder()
            showDatePicker()
            return false
        case 4:
            // notesField
            resignTextFieldsAsFirstResponder()
            showNotes()
            return false
        default:
            return true
        }
    }
    
    func resignTextFieldsAsFirstResponder() {
        amountField.resignFirstResponder()
        descriptionField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func showDatePicker() {
        let datePicker = UIDatePicker()
        datePicker.timeZone = CalendarDay.gmtTimeZone
        datePicker.backgroundColor = UIColor.white
        datePicker.minimumDate = nil
        datePicker.maximumDate = Date()
        datePicker.setDate(dataSource.calDay.gmtDate, animated: false)
        datePicker.datePickerMode = .date
        datePicker.frame = CGRect(x: 0,
                                  y: bounds.size.height,
                                  width: bounds.size.width,
                                  height: datePicker.intrinsicContentSize.height)
        datePicker.add(for: .valueChanged) {
            // Grab the selected date from the date picker.
            self.dataSource.calDay = CalendarDay(dateInGMTDay: datePicker.date)
            self.dateField.text = self.humanReadableDate(self.dataSource.calDay)
        }
                
        addSubview(datePicker)
        
        func animateDismiss() {
            // Animate slide down.
            UIView.animate(withDuration: 0.2, animations: {
                let pickerHeight = datePicker.frame.height
                datePicker.frame = datePicker.frame.offsetBy(dx: 0, dy: pickerHeight)
                
                self.dismissButton!.frame = self.bounds
                self.dismissButton!.backgroundColor = UIColor.clear
            }, completion:  { (finished: Bool) in
                datePicker.removeFromSuperview()
                self.dismissButton?.removeFromSuperview()
                self.delegate.enableRightBBI(sender: self)
                self.delegate.popLeftBBI(sender: self)
            })
        }
        
        insertDismissButton(removeOnPress: false, under: datePicker, dismiss: animateDismiss)
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel) {
            self.delegate.popLeftBBI(sender: self)
            animateDismiss()
            self.cancel()
        }
        
        delegate.pushLeftBBI(cancelButton, sender: self)
        
        // Animate slide up.
        UIView.animate(withDuration: 0.2) {
            let pickerHeight = datePicker.frame.height
            datePicker.frame = datePicker.frame.offsetBy(dx: 0, dy: -pickerHeight)
            
            let h = self.bounds.size.height - datePicker.frame.size.height
            let w = self.bounds.width
            let bgColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
            self.dismissButton!.backgroundColor = bgColor
            self.dismissButton!.frame = CGRect(x: 0, y: 0, width: w, height: h)

        }
    }

    func showNotes() {
        let notesView = UITextView()
        notesView.text = dataSource.notes
        notesView.isEditable = true
        notesView.font = UIFont.systemFont(ofSize: 24)
        let grey = UIColor(colorLiteralRed: 245.0/255.0,
                           green: 245.0/255.0,
                           blue: 245.0/255.0,
                           alpha: 1)
        notesView.backgroundColor = grey
        notesView.frame = CGRect(x: 0,
                             y: bounds.size.height,
                             width: bounds.size.width,
                             height: bounds.size.height)
        
        scrollView.addSubview(notesView)
        
        func animateDismiss() {
            UIView.animate(withDuration: 0.25, animations: {
                let f = notesView.frame.offsetBy(dx: 0,
                                                 dy: self.bounds.size.height)
                notesView.frame = f
            }, completion: { (completed: Bool) in
                notesView.removeFromSuperview()
                self.delegate.popLeftBBI(sender: self)
                self.delegate.popRightBBI(sender: self)
            })
        }
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel) {
            notesView.resignFirstResponder()
            animateDismiss()
        }
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done) {
            self.dataSource.notes = notesView.text
            notesView.resignFirstResponder()
            animateDismiss()
        }
        delegate.pushLeftBBI(cancelButton, sender: self)
        delegate.pushRightBBI(doneButton, sender: self)
        

        UIView.animate(withDuration: 0.25, animations: {
            let h = self.bounds.size.height - (self.keyboardHeight ?? 216)
            notesView.frame = CGRect(x: 0,
                                     y: 0,
                                     width: self.bounds.size.width,
                                     height: h)
        })
        notesView.becomeFirstResponder()

    }

    
    func amountChanged(_ sender: UITextField) {
        let amount = sender.text!.parseValidAmount(maxLength: 8)
        self.dataSource.amount = Decimal(amount)
        
        sender.text = String.formatAsCurrency(amount: amount)
    }
    
    func descriptionChanged(_ sender: UITextField) {
        self.dataSource.shortDescription = sender.text!
        
        // Determine max font size that can fit in the space available.
        let maxWidth = self.descriptionField.frame.size.width
        
        var fontSize: CGFloat = 24
        let minFontSize: CGFloat = 17
        
        let font = UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightLight)
        var attr = [NSFontAttributeName: font]
        
        var width = descriptionField.text!.size(attributes: attr).width
        
        while width > maxWidth && fontSize > minFontSize {
            fontSize -= 1
            attr = [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize,
                                                           weight: UIFontWeightLight)]
            width = descriptionField.text!.size(attributes: attr).width
        }
        descriptionField.font = UIFont.systemFont(ofSize: fontSize,
                                                  weight: UIFontWeightLight)
    }
}


protocol ExpenseViewDelegate: class {
    /*
     * Called after editing has begun.
     * e.g. the user interacted with an element within the ExpenseView.
     */
    func didBeginEditing(sender: ExpenseView)
    /*
     * Called after editing has finished.
     * e.g. the user pressed the save or cancel button.
     * shouldDismiss is true if the parent view should dimiss, false otherwise.
     */
    func didEndEditing(sender: ExpenseView, expense: Expense?)
    
    /*
     * Asks the delegate to present a view controller.
     */
    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?, sender: Any?)
    
    /*
     * Asks the delegate to set the right bar button item of the navigation
     * item.
     * The delgate is responsible for maintaining a stack of bar button items
     * to swap out when push and pop are called.
     */
    func pushRightBBI(_ bbi: UIBarButtonItem, sender: Any?)
    func popRightBBI(sender: Any?)

    /*
     * Asks the delegate to set the left bar button item of the navigation
     * item.
     * The delgate is responsible for maintaining a stack of bar button items
     * to swap out when push and pop are called.
     */
    func pushLeftBBI(_ bbi: UIBarButtonItem, sender: Any?)
    func popLeftBBI(sender: Any?)
    
    /*
     * Asks the delegate to disable or enable the right bar button item.
     */
    func disableRightBBI(sender: Any?)
    func enableRightBBI(sender: Any?)
    
    /*
     * Asks the delegate to disable or enable the left bar button item.
     */
    func disableLeftBBI(sender: Any?)
    func enableLeftBBI(sender: Any?)
}

protocol ExpenseViewDataSource: class {
    var calDay: CalendarDay! { get set }
    var amount: Decimal? { get set }
    var shortDescription: String? { get set }
    var notes: String? { get set }
    var imageContainers: [ImageContainer]? { get }
    
    
    func addImage(container: ImageContainer)
    func removeImage(index: Int)
    func save() -> Expense?
}
