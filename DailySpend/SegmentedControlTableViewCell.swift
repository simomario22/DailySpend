//
//  DatePickerTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class SegmentedControlTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    let margin: CGFloat = 8
    let inset: CGFloat = 15
    
    var segmentedControl: UISegmentedControl!
    
    var hasTitle = false
    
    private var changedCallback: ((UISegmentedControl) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if segmentedControl != nil {
            var frame = bounds.insetBy(dx: margin, dy: margin)
            if hasTitle {
                frame.size.width = segmentedControl.intrinsicContentSize.width
                frame.origin.x = bounds.size.width - frame.size.width - inset
                
            } else {
                frame.origin.x += (inset - margin)
            }
            segmentedControl.frame = frame
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
