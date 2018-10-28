//
//  TodaySummaryView.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/5/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

class PeriodBrowserView: BorderedView {
    private let margin: CGFloat = 4
    private let currentButton = UIButton(type: .custom)
    private let previousButton = UIButton(type: .custom)
    private let nextButton = UIButton(type: .custom)
    private var colorNegative: Bool? = nil
    
    var delegate: PeriodSelectorViewDelegate?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        previousButton.frame = CGRect(
            x: margin,
            y: margin,
            width: bounds.size.height - margin,
            height: bounds.size.height - margin
        )
        
        nextButton.frame = CGRect(
            x: bounds.size.width - bounds.size.height - margin,
            y: margin,
            width: bounds.size.height - margin,
            height: bounds.size.height - margin
        )

        currentButton.frame = CGRect(
            x: nextButton.frame.rightEdge + margin,
            y: margin,
            width: nextButton.frame.leftEdge - previousButton.frame.rightEdge - (margin * 2),
            height: bounds.size.height - margin
        )
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        let lightTint = tintColor.withAlphaComponent(0.2)
        currentButton.titleLabel?.textAlignment = .center
        currentButton.setTitleColor(tintColor, for: .normal)
        currentButton.setTitleColor(lightTint, for: .highlighted)
        
        previousButton.setTitle("◀", for: .normal)
        previousButton.setTitleColor(tintColor, for: .normal)
        previousButton.setTitleColor(lightTint, for: .highlighted)
        previousButton.titleLabel?.textAlignment = .center
        previousButton.contentVerticalAlignment = .center
        previousButton.add(for: .touchUpInside) {
            self.delegate?.tappedPrevious()
        }
        
        nextButton.setTitle("▶", for: .normal)
        nextButton.setTitleColor(tintColor, for: .normal)
        nextButton.setTitleColor(lightTint, for: .highlighted)
        nextButton.titleLabel?.textAlignment = .center
        nextButton.contentVerticalAlignment = .center
        nextButton.add(for: .touchUpInside) {
            self.delegate?.tappedNext()
        }
        
        self.addSubviews([previousButton, nextButton, currentButton])
        
        self.addOutsideBottomBorder(color: UIColor.black.withAlphaComponent(0.3), width: 0.5)
    }
    
    var labelText: String? = nil {
        didSet {
            currentButton.setTitle(labelText, for: .normal)
        }
    }
    
    var previousButtonEnabled: Bool = true {
        didSet {
            previousButton.isEnabled = previousButtonEnabled
        }
    }
    
    var nextButtonEnabled: Bool = true {
        didSet {
            nextButton.isEnabled = nextButtonEnabled
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


protocol PeriodSelectorViewDelegate {
    func tappedNext()
    func tappedPrevious()
}
