//
//  BalanceBarView.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/31/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

class BalanceBarView: UIView {
    private let balanceTextLabel: UILabel
    private let balanceAmountLabel: UILabel
    private let balanceActivityIndicator: UIActivityIndicatorView

    static let collapsedHeight: CGFloat = 44

    private let margin: CGFloat = 8
    override func layoutSubviews() {
        let textLabelWidth = balanceTextLabel.text?.calculatedSize(font: balanceTextLabel.font).width ?? 0
        let amountLabelWidth = balanceAmountLabel.text?.calculatedSize(font: balanceTextLabel.font).width ?? 0
        let activityIndicatorWidth = balanceActivityIndicator.intrinsicContentSize.width

        if balanceActivityIndicator.isAnimating {
            let fullWidth = textLabelWidth + margin + activityIndicatorWidth
            let start = (self.bounds.size.width / 2) - (fullWidth / 2)
            balanceTextLabel.frame = CGRect(
                x: start,
                y: 0,
                width: textLabelWidth,
                height: self.bounds.size.height
            )

            balanceActivityIndicator.frame = CGRect(
                x: balanceTextLabel.frame.rightEdge + margin,
                y: 0,
                width: activityIndicatorWidth,
                height: self.bounds.size.height
            )
        } else {
            let fullWidth = textLabelWidth + margin + amountLabelWidth
            let start = (self.bounds.size.width / 2) - (fullWidth / 2)
            balanceTextLabel.frame = CGRect(
                x: start,
                y: 0,
                width: textLabelWidth,
                height: self.bounds.size.height
            )

            balanceAmountLabel.frame = CGRect(
                x: balanceTextLabel.frame.rightEdge + margin,
                y: 0,
                width: amountLabelWidth,
                height: self.bounds.size.height
            )
        }
    }

    override init(frame: CGRect) {
        balanceTextLabel = UILabel()
        balanceAmountLabel = UILabel()
        balanceActivityIndicator = UIActivityIndicatorView(style: .gray)
        balanceActivityIndicator.startAnimating()
        super.init(frame: frame)

        self.addSubviews([balanceTextLabel, balanceAmountLabel, balanceActivityIndicator])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTextLabel(_ text: String) {
        self.balanceTextLabel.text = text
        self.setNeedsLayout()
    }

    func setAmountLabel(_ text: String) {
        self.balanceAmountLabel.text = text
        self.setNeedsLayout()
    }

    func setIsAnimating(_ animating: Bool) {
        if animating {
            self.balanceActivityIndicator.startAnimating()
            self.balanceActivityIndicator.isHidden = false
            self.balanceTextLabel.isHidden = true
        } else {
            self.balanceActivityIndicator.stopAnimating()
            self.balanceActivityIndicator.isHidden = true
            self.balanceTextLabel.isHidden = false
        }
        self.setNeedsLayout()
    }
}
