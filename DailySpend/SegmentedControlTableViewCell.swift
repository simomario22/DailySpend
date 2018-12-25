//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class SegmentedControlTableViewCell: ExplanatoryTextTableViewCell, UITextFieldDelegate {
    var segmentedControl: UISegmentedControl!
    
    var hasTitle = false
    
    private var changedCallback: ((UISegmentedControl) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if segmentedControl != nil {
            var frame = controlAreaBounds.insetBy(dx: margin, dy: margin)
            if hasTitle {
                frame.size.width = segmentedControl.intrinsicContentSize.width
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
            segmentedControl.frame = frame
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        segmentedControl = UISegmentedControl()
        self.addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(control:)), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func segmentedControlChanged(control: UISegmentedControl!) {
        changedCallback?(control)
    }
    
    func setChangedCallback(_ cb: @escaping ((UISegmentedControl) -> ())) {
        changedCallback = cb
    }
    
    func setSegmentTitles(_ titles:[String]) {
        segmentedControl.removeAllSegments()
        for title in titles {
            let lastIndex = segmentedControl.numberOfSegments
            segmentedControl.insertSegment(withTitle: title, at: lastIndex, animated: false)
        }
    }
    
    func setHasTitle(_ newValue: Bool) {
        if newValue != hasTitle {
            hasTitle = newValue
            setNeedsLayout()
        }
    }
}
