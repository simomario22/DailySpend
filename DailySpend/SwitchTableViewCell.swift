//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class SwitchTableViewCell: ExplanatoryTextTableViewCell, UITextFieldDelegate {
    var switchControl: UISwitch!
    
    var hasTitle = false
    
    private var changedCallback: ((UISwitch) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if switchControl != nil {
            var frame = controlAreaBounds.insetBy(dx: margin, dy: margin)
            if hasTitle {
                frame.size.width = switchControl.intrinsicContentSize.width
                frame.origin.x = controlAreaBounds.size.width - frame.size.width - inset
                if let titleFrame = textLabel?.frame {
                    let newTitleFrame = CGRect(x: titleFrame.origin.x,
                                               y: controlAreaBounds.topEdge + margin,
                                               width: titleFrame.size.width,
                                               height: controlAreaBounds.size.height - (margin * 2))
                    textLabel!.frame = newTitleFrame
                }
            } else {
                frame.origin.x += (inset - margin)
            }
            switchControl.frame = frame
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        switchControl = UISwitch()
        self.addSubview(switchControl)
        switchControl.addTarget(self, action: #selector(switchChanged(control:)), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func switchChanged(control: UISwitch!) {
        changedCallback?(control)
    }
    
    func setChangedCallback(_ cb: @escaping ((UISwitch) -> ())) {
        changedCallback = cb
    }
    
    func setSwitchValue(_ value: Bool) {
        switchControl.isOn = true
    }
    
    func setHasTitle(_ newValue: Bool) {
        if newValue != hasTitle {
            hasTitle = newValue
            setNeedsLayout()
        }
    }
}
