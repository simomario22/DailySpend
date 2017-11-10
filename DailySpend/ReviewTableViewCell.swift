//
//  ReviewTableViewCell.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ReviewTableViewCell: UITableViewCell {
    var descriptionLabels = [UILabel]()
    var valueLabels = [UILabel]()
    var signLabels = [UILabel?]()
    var pausedNoteLabel: UILabel!
    var equalsLineView: UIView!
    
    var paused = false
    
    let xMargin: CGFloat = 15
    let yMargin: CGFloat = 15
    let innerYMargin: CGFloat = 15
    
    let signMargin: CGFloat = 5
    let equalsLineMargin: CGFloat = 5
    
    let signLabelsYOffset: CGFloat = -5
    
    let desiredFontSize: CGFloat = 17
    let signLabelsDesiredFontSize: CGFloat = 23
    
    private var layedOut = false

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !layedOut {
            layoutLabels(multiplier: findMultiplier())
        }
    }
    
    /**
     * Find the number needed to multiply fontSizes and horizontal margins by
     * to have all lines fit within bounds.width
     */
    func findMultiplier() -> CGFloat {
        let numLabels = descriptionLabels.count
        
        var multiplier: CGFloat = 1
        
        var greatestWidthIndex = 0
        var greatestWidth: CGFloat = 0
        
        for i in 0..<numLabels {
            let totalWidth = totalWidthForIndex(i, multiplier: multiplier)
            if totalWidth > greatestWidth {
                greatestWidth = totalWidth
                greatestWidthIndex = i
            }
        }
        
        if greatestWidth > bounds.size.width {
            // We need to resize the font to make everything fit side by side.
            
            // We have found the index with the greatest width, so if we find a
            // font size that makes that one fit, we know all of the rest of
            // the label groups at that font size will fit.
            
            let i = greatestWidthIndex
            
            // Come up with an initial estimate for the multiplier.
            multiplier = (greatestWidth / bounds.size.width)
            multiplier = round(100.0 * multiplier) / 100.0 // Round to nearest 0.01
            var width = totalWidthForIndex(i, multiplier: multiplier)
            
            var candidateMultiplier = multiplier + (width < bounds.size.width ? 0.01 : -0.01)
            var candidateWidth = totalWidthForIndex(i, multiplier: candidateMultiplier)
            
            while (candidateWidth < bounds.size.width) == (width < bounds.size.width) &&
                    multiplier > 0.01 &&
                    candidateMultiplier > 0.01 {
                multiplier = candidateMultiplier
                width = candidateWidth
                candidateMultiplier = multiplier + (width < bounds.size.width ? 0.01 : -0.01)
                candidateWidth = totalWidthForIndex(i, multiplier: candidateMultiplier)
            }
            
            // We want the one that is under with a minimum of 0.01 so things
            // don't crash (although if it's 0.01, something has gone wrong).
            multiplier = min(min(candidateMultiplier, multiplier), 0.01)
        }
        
        return multiplier
    }
    
    
    func totalWidthForIndex(_ index: Int, multiplier: CGFloat) -> CGFloat {
        let dlText = descriptionLabels[index].text!
        let dlFontSize = descriptionLabels[index].font!.pointSize * multiplier
        let dlFont = descriptionLabels[index].font!.withSize(dlFontSize)

        let signLabelText = signLabels[index]?.text!
        let signLabelFontSize = (signLabels[index]?.font!.pointSize ?? 1) * multiplier
        let signLabelFont = signLabels[index]?.font!.withSize(signLabelFontSize) ?? UIFont.systemFont(ofSize: signLabelFontSize)
        
        let valueLabelText = valueLabels[index].text!
        let valueLabelFontSize = valueLabels[index].font!.pointSize * multiplier
        let valueLabelFont = valueLabels[index].font!.withSize(valueLabelFontSize)
        
        let combinedWidth = dlText.size(withAttributes: [.font: dlFont]).width +
                            valueLabelText.size(withAttributes: [.font: valueLabelFont]).width +
                            (signLabelText?.size(withAttributes: [.font: signLabelFont]).width ?? 0)
        
        return combinedWidth + (multiplier * 2 * xMargin) + (multiplier * signMargin)
    }
    
    func layoutLabels(multiplier: CGFloat) {
        if descriptionLabels.count != valueLabels.count ||
            descriptionLabels.count != signLabels.count ||
            descriptionLabels.count == 0 {
            return
        }
        
        func setIntrinsicFrame(_ label: UILabel, _ x: CGFloat, _ y: CGFloat) {
            let w = label.textIntrinsicSize.width
            let h = label.textIntrinsicSize.height
            label.frame = CGRect(x: x, y: y, width: w, height: h)
        }
        
        let numLabels = descriptionLabels.count

        var y: CGFloat = yMargin
        
        for i in 0..<numLabels {
            let descriptionLabel = descriptionLabels[i]
            let signLabel = signLabels[i]
            let valueLabel = valueLabels[i]
            
            // Set adjusted font sizes for labels.
            let dlFontSize = descriptionLabel.font!.pointSize * multiplier
            descriptionLabel.font = descriptionLabel.font!.withSize(dlFontSize)
            
            let signLabelFontSize = (signLabel?.font!.pointSize ?? 1) * multiplier
            signLabel?.font = signLabel?.font!.withSize(signLabelFontSize)
            
            let valueLabelFontSize = valueLabel.font!.pointSize * multiplier
            valueLabel.font = valueLabel.font!.withSize(valueLabelFontSize)
            
            // Set description frame.
            setIntrinsicFrame(descriptionLabel, xMargin * multiplier, y)

            // Set valueLabel frame.
            var x = bounds.size.width - (xMargin * multiplier) - valueLabel.textIntrinsicSize.width
            setIntrinsicFrame(valueLabel, x, y)
            
            // Set signLabel frame if it exists.
            if let signLabel = signLabel {
                x = valueLabel.frame.leftEdge - (signMargin * multiplier) - signLabel.textIntrinsicSize.width
                setIntrinsicFrame(signLabel, x, y + signLabelsYOffset)
            }
            
            // Set up for next round.
            y = descriptionLabel.frame.bottomEdge + yMargin
        }

        if numLabels >= 2 {
            // Set frame for equalsLineView.
            let under = numLabels - 2
            
            let signFontSize = signLabelsDesiredFontSize * multiplier
            let signFont = UIFont.systemFont(ofSize: signFontSize)
            let signWidth = "+".size(withAttributes: [.font: signFont]).width
            let signMargin = (self.signMargin * multiplier)
            
            let x = valueLabels[under].frame.leftEdge - signMargin - signWidth
            let y = valueLabels[under].frame.bottomEdge + equalsLineMargin
            let w = valueLabels[under].frame.rightEdge - x
            
            equalsLineView.frame = CGRect(x: x, y: y, width: w, height: 1.0)
        }
        
        if paused {
            let x = xMargin * multiplier
            let y = valueLabels.last!.frame.bottomEdge + yMargin
            let w = bounds.size.width - (xMargin * multiplier * 2)
            pausedNoteLabel.frame = CGRect(x: x, y: y, width: w, height: 0)
            pausedNoteLabel.sizeToFit()
        }
        
        layedOut = true
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        equalsLineView = UILabel()
        equalsLineView.backgroundColor = UIColor.black
        
        let size: CGFloat = 17
        let pausedNoteText = "Because this day is paused, its balance is " +
                             "equal to the previous day's balance."
        let attributedText = NSMutableAttributedString(string: pausedNoteText)
        let pausedAttrs: [NSAttributedStringKey : Any] = [
            .foregroundColor: UIColor.paused,
            .font: UIFont.boldSystemFont(ofSize: size)
        ]
        attributedText.addAttributes(pausedAttrs, range: NSMakeRange(20, 6))
        
        pausedNoteLabel = UILabel()
        pausedNoteLabel.font = UIFont.systemFont(ofSize: size)
        pausedNoteLabel.attributedText = attributedText
        pausedNoteLabel.numberOfLines = 0
        pausedNoteLabel.lineBreakMode = .byWordWrapping

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func showPausedNote(_ showPausedMessage: Bool) {
        layedOut = false
        paused = showPausedMessage
        
        if paused {
            if pausedNoteLabel.superview != nil {
                self.addSubview(pausedNoteLabel)
            }
        } else {
            pausedNoteLabel.removeFromSuperview()
        }
    }
    
    
    
    func setLabelData(_ data:[ReviewCellDatum]) {
        layedOut = false
        func makeLabel(_ text: String,
                       color: UIColor = UIColor.black,
                       weight: UIFont.Weight = .regular,
                       // There is a compiler bug that prevents us from using
                       // desiredFontSize as a default here.
                       size: CGFloat,
                       align: NSTextAlignment = .left) -> UILabel {
            let label = UILabel()
            label.text = text
            label.textColor = color
            label.font = UIFont.systemFont(ofSize: size, weight: weight)
            label.textAlignment = align
            return label
        }

        
        // Remove all labels.
        while let label = descriptionLabels.popLast() { label.removeFromSuperview() }
        while let label = valueLabels.popLast() { label.removeFromSuperview() }
        while let label = signLabels.popLast() { label?.removeFromSuperview() }
        equalsLineView.removeFromSuperview()
        
        for datum in data {
            descriptionLabels.append(makeLabel(datum.description, weight: .bold, size: desiredFontSize))
            addSubview(descriptionLabels.last!)
            
            valueLabels.append(makeLabel(datum.value, color: datum.color, size: desiredFontSize, align: .right))
            addSubview(valueLabels.last!)

            switch datum.sign {
            case .Plus:
                self.signLabels.append(makeLabel("+",  weight: .light, size: signLabelsDesiredFontSize))
                self.addSubview(signLabels.last!!)
            case .Minus:
                self.signLabels.append(makeLabel("−", weight: .light, size: signLabelsDesiredFontSize))
                self.addSubview(signLabels.last!!)
            case .None:
                self.signLabels.append(nil)
            }
        }
        
        if data.count > 2 {
            self.addSubview(equalsLineView)
        }
        
        self.setNeedsLayout()
    }
    
    func desiredHeightForCurrentState() -> CGFloat {
        if !layedOut {
            layoutLabels(multiplier: findMultiplier())
        }
        if paused {
            return pausedNoteLabel.frame.bottomEdge + yMargin
        } else if descriptionLabels.count == valueLabels.count ||
                  descriptionLabels.count == signLabels.count ||
                  descriptionLabels.count != 0 {
            return descriptionLabels.last!.frame.bottomEdge + yMargin
        } else {
            return 0
        }
    }
}

struct ReviewCellDatum {
    enum ValueSign {
        case Plus
        case Minus
        case None
    }
    
    var description: String
    var value: String
    var color: UIColor
    var sign: ValueSign
}
