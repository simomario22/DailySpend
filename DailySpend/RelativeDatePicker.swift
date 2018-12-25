//
//  RelativeDatePicker.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/24/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class RelativeDatePicker: UIView {
    private var buttonPickerView: ButtonPickerView!
    private var calendarIconView: UIImageView!

    private let margin: CGFloat = 8

    override func layoutSubviews() {
        if calendarIconView != nil {
            let sideWidth: CGFloat = 20
            calendarIconView.frame = CGRect(
                x: margin,
                y: margin,
                width: sideWidth,
                height: sideWidth
            )
        }

        if buttonPickerView != nil {
            let x = calendarIconView.frame.rightEdge + margin / 2
            buttonPickerView.frame = CGRect(
                x: x,
                y: 0,
                width: bounds.size.width - x,
                height: bounds.size.height
            )
        }
    }

    var delegate: RelativeDatePickerDelegate?

    var selectedDay: CalendarDay? {
        get {
            return getSelectedDay()
        }
        set {
            setSelectedDay(newValue)
        }
    }

    private func setSelectedDay(_ day: CalendarDay?) {
        let today = CalendarDay()
        if day == today {
            buttonPickerView.selectedButtonIndex = 1
        } else if day == today.subtract(days: 1) {
            buttonPickerView.selectedButtonIndex = 0
        } else {
            buttonPickerView.selectedButtonIndex = 2
        }
    }

    private func getSelectedDay() -> CalendarDay? {
        switch buttonPickerView.selectedButtonIndex {
        case 0:
            return CalendarDay()
        case 1:
            return CalendarDay().subtract(days: 1)
        default:
            return nil
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        buttonPickerView = ButtonPickerView()
        calendarIconView = UIImageView()

        buttonPickerView.pickerDelegate = self
        buttonPickerView.customButtonTitle = nil
        buttonPickerView.buttonTitles = ["Yesterday", "Today", "⋯"]
        buttonPickerView.selectedButtonIndex = 1

        calendarIconView.image = UIImage(named: "calendar")?.withRenderingMode(.alwaysTemplate)
        calendarIconView.tintColor = .lightGray

        self.addSubviews([buttonPickerView, calendarIconView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RelativeDatePicker : ButtonPickerViewDelegate {
    func tappedButton(in picker: ButtonPickerView, at index: Int, with _: String) {
        let today = CalendarDay()
        switch index {
        case 0:
            picker.selectedButtonIndex = index
            let yesterday = today.subtract(days: 1)
            delegate?.selectedDay(yesterday)
        case 1:
            picker.selectedButtonIndex = index
            delegate?.selectedDay(today)
        case 2:
            delegate?.selectedExpandedDateSelection()
        default:
            return
        }
    }

    func tappedCustomButton(in _: ButtonPickerView) {
        return
    }


}


protocol RelativeDatePickerDelegate {
    func selectedDay(_ day: CalendarDay)
    func selectedExpandedDateSelection()
}
