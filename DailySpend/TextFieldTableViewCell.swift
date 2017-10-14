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
    
    private var changedCallback: ((UITextField) -> ())?
    private var editingCallback: ((UITextField) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if textField != nil {
            var insetBounds = bounds.insetBy(dx: margin, dy: margin)
            insetBounds.origin.x += (inset - margin)
            textField.frame = insetBounds
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
        editingCallback?(textField)
    }
    
    @objc func textFieldChanged(field: UITextField!) {
        changedCallback?(field)
    }
    
    func setEditingCallback(_ cb: @escaping ((UITextField) -> ())) {
        editingCallback = cb
    }
    
    func setChangedCallback(_ cb: @escaping ((UITextField) -> ())) {
        changedCallback = cb
    }
}
