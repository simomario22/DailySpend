//
//  GoalNavigationTitleView.swift
//  DailySpend
//
//  Created by Josh Sherick on 2/10/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import UIKit

class GoalNavigationTitleView: UIView {
    private let titleLabel = UILabel(frame: .zero)
    private let explainerLabel = UILabel(frame: .zero)
    private let button = UIButton(type: .custom)

    var didTap: (() -> ())?

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    private var isHighlighted: Bool = false {
        didSet {
            explainerLabel.attributedText = isCollapsed ? collapsedText : uncollapsedText
        }
    }

    var isCollapsed: Bool = false {
        didSet {
            explainerLabel.attributedText = isCollapsed ? collapsedText : uncollapsedText
        }
    }

    override func layoutSubviews() {
        let height = frame.size.height
        let width = frame.size.width

        let explainerHeight: CGFloat = 15
        let titleHeight = height - explainerHeight
        titleLabel.frame = CGRect(x: 0, y: 0, width: width, height: titleHeight)
        explainerLabel.frame = CGRect(x: 0, y: titleHeight - 5, width: width, height: explainerHeight)
        button.frame = bounds
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center

        explainerLabel.attributedText = collapsedText
        explainerLabel.textAlignment = .center

        button.backgroundColor = UIColor.clear

        button.add(for: [.touchDown, .touchDragEnter]) {
            self.isHighlighted = true
        }

        button.add(for: .touchDragExit) {
            self.isHighlighted = false
        }
        button.add(for: .touchUpInside) {
            self.isHighlighted = false
            self.didTap?()
        }

        self.addSubviews([titleLabel, explainerLabel, button])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var collapsedText: NSAttributedString {
        let text = NSMutableAttributedString(string: "▼ Change Goal ▼")
        text.addAttributes(caretAttributes, range: NSMakeRange(0, 1))
        text.addAttributes(explainerAttributes, range: NSMakeRange(1, 13))
        text.addAttributes(caretAttributes, range: NSMakeRange(14, 1))
        return text
    }

    private var uncollapsedText: NSAttributedString {
        let text = NSMutableAttributedString(string: "▲ Collapse ▲")
        text.addAttributes(caretAttributes, range: NSMakeRange(0, 1))
        text.addAttributes(explainerAttributes, range: NSMakeRange(1, 10))
        text.addAttributes(caretAttributes, range: NSMakeRange(11, 1))
        return text
    }

    private var caretAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: isHighlighted ? tintColor.withAlphaComponent(0.2) : tintColor
        ]
    }

    private var explainerAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: isHighlighted ? tintColor.withAlphaComponent(0.2) : tintColor
        ]
    }
}
