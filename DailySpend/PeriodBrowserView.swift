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
    private let currentLabel = UILabel()
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

        currentLabel.frame = CGRect(
            x: nextButton.frame.rightEdge + margin,
            y: margin,
            width: nextButton.frame.leftEdge - previousButton.frame.rightEdge - (margin * 2),
            height: bounds.size.height - margin
        )
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        currentLabel.textAlignment = .center
        
        previousButton.titleLabel?.text = "◀"
        previousButton.titleLabel?.textAlignment = .center
        previousButton.contentVerticalAlignment = .center
        previousButton.add(for: .touchUpInside) {
            self.delegate?.tappedPrevious()
        }
        
        nextButton.titleLabel?.text = "▶"
        nextButton.titleLabel?.textAlignment = .center
        nextButton.contentVerticalAlignment = .center
        nextButton.add(for: .touchUpInside) {
            self.delegate?.tappedNext()
        }
        
        self.addSubviews([previousButton, nextButton, currentLabel])
        
        self.addOutsideBottomBorder(color: UIColor.black.withAlphaComponent(0.3), width: 0.5)
    }
    
    var labelText: String? = nil {
        didSet {
            currentLabel.text = labelText
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
    
    private func updateColor(value: CGFloat) {
        if ( (value < 0) != colorNegative ) {
            appDelegate.spendIndicationColor = value < 0 ? .overspent : .underspent
            colorNegative = value < 0
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
