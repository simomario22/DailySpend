//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    let margin: CGFloat = 8
    let inset: CGFloat = 15
    
    var textField: UITextField!
    
    var hasTitle = false
    
    private var changedCallback: ((UITextField) -> ())?
    private var beginEditingCallback: ((UITextField) -> ())?
    private var endEditingCallback: ((UITextField) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if textField != nil {
            var frame = bounds.insetBy(dx: margin, dy: margin)
            if hasTitle {
                frame.size.width = (bounds.size.width / 2) - inset
                frame.origin.x = bounds.size.width - frame.size.width - inset
            } else {
                frame.origin.x += (inset - margin)
            }
            textField.frame = frame

        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textField = UITextField()
        textField.borderStyle = .none
        textField.delegate = self
        self.addSubview(textField)
        textField.addTarget(self, action: #selector(textFieldChanged(field:)), for: .editingChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        beginEditingCallback?(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        endEditingCallback?(textField)
    }
    
    @objc func textFieldChanged(field: UITextField!) {
        changedCallback?(field)
    }
    
    func setBeginEditingCallback(_ cb: ((UITextField) -> ())?) {
        beginEditingCallback = cb
    }
    
    func setEndEditingCallback(_ cb: ((UITextField) -> ())?) {
        endEditingCallback = cb
    }
    
    func setChangedCallback(_ cb: ((UITextField) -> ())?) {
        changedCallback = cb
    }
    
    func setHasTitle(_ newValue: Bool) {
        if newValue != hasTitle {
            hasTitle = newValue
            textField.textAlignment = hasTitle ? .right : .left
            self.setNeedsLayout()
        }
    }
}
