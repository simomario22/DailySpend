//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension UITextView {
    func intrinsicHeightForWidth(_ width: CGFloat) -> CGFloat {
        return sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
}

class UITextViewWithoutMargins: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var fits = super.sizeThatFits(size)
        if size.height == .greatestFiniteMagnitude {
            // Since there is 8px padding on top/bottom in a normal text view.
            fits.height -= 16
            return fits
        }
        return fits
    }
}
