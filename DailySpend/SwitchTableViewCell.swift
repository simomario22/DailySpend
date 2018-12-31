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
                                               height: switchControl.intrinsicContentSize.height)
                    textLabel!.frame = newTitleFrame
                }
            } else {
                frame.origin.x += (inset - margin)
            }
            switchControl.frame = frame
            setExclusionFrame(frame.insetBy(dx: -margin, dy: -margin))
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
        switchControl.isOn = value
    }
    
    func setHasTitle(_ newValue: Bool) {
        if newValue != hasTitle {
            hasTitle = newValue
            setNeedsLayout()
        }
    }
    
    static func desiredHeight(_ explanatoryText: String,
                font: UIFont = defaultExplanatoryTextFont,
                width: CGFloat = UIScreen.main.bounds.size.width) -> CGFloat {
        let switchSize = UISwitch().intrinsicContentSize
        let exclusionFrame = CGRect(x: width - switchSize.width - inset - margin,
                                    y: margin,
                                    width: switchSize.width + margin,
                                    height: switchSize.height + margin)
        return super.desiredHeight(explanatoryText, font: font, width: width, exclusionFrame: exclusionFrame)
    }
}
