//
//  PauseViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class PauseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    var editingFirstDate = false
    var editingLastDate = false
    
    var pause: Pause!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if pause == nil {
            pause = Pause(context: context)
            pause.firstDayEffective = CalendarDay()
            pause.lastDayEffective = CalendarDay()
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, save)
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, save)
        }
        
        self.navigationItem.title = "New Pause"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Roll back any uncommitted changes
        context.rollback()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
        pause.dateCreated = Date()
        let validation = pause.validate(context: context)
        if validation.valid {
            appDelegate.saveContext()
            self.navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController(title: "Validation Error",
                                          message: validation.problem!,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay",
                                          style: .default,
                                          handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    enum PauseViewCellType {
        case DescriptionCell
        case FirstDayEffectiveDisplayCell
        case FirstDayEffectiveDatePickerCell
        case LastDayEffectiveDisplayCell
        case LastDayEffectiveDatePickerCell
    }
    
    func cellTypeForIndexPath(indexPath: IndexPath) -> PauseViewCellType {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 1 {
            if row == 0 {
                return .FirstDayEffectiveDisplayCell
            }
            
            if !editingFirstDate && !editingLastDate {
                return .LastDayEffectiveDisplayCell
            }
            
            if editingFirstDate {
                if row == 1 {
                    return .FirstDayEffectiveDatePickerCell
                }
                if row == 2 {
                    return .LastDayEffectiveDisplayCell
                }
            }
            
            if editingLastDate {
                if row == 1 {
                    return .LastDayEffectiveDisplayCell
                }
                if row == 2 {
                    return .LastDayEffectiveDatePickerCell
                }
            }
        }
        
        return .DescriptionCell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section != 1 {
            return nil
        }
        
        guard let firstDayEffective = pause.firstDayEffective,
              let lastDayEffective = pause.lastDayEffective else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if firstDayEffective == lastDayEffective {
            let formattedDate = firstDayEffective.string(formatter: dateFormatter)
            return "Any expenses and money accrued on \(formattedDate) will be " +
                    "ignored when calculating the daily amount left to spend and " +
                    "any monthly goals."
        } else {
            let formattedFirstDate = firstDayEffective.string(formatter: dateFormatter)
            let formattedLastDate = lastDayEffective.string(formatter: dateFormatter)
            return "Any expenses and money accrued from \(formattedFirstDate) to " +
                    "\(formattedLastDate) will be ignored when calculating the " +
                    "daily amount left to spend and any monthly goals."
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let firstDayEffective = pause.firstDayEffective!
        let lastDayEffective = pause.lastDayEffective!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, yyyy"
        
        func dateDisplayCell(label: String, day: CalendarDay, shouldTintDetailText: () -> Bool) -> UITableViewCell {
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "dateDisplay")
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "dateDisplay")
            }
            
            cell.textLabel!.text = label
            cell.detailTextLabel!.text = day.string(formatter: dateFormatter)
            if (shouldTintDetailText()) {
                cell.detailTextLabel!.textColor = view.tintColor
            } else {
                cell.detailTextLabel!.textColor = UIColor.black
            }
            return cell
        }

        func textFieldDisplayCell(placeholder: String, text: String?,
                                  didBeginEditing: @escaping (UITextField) -> (),
                                  changedToText: @escaping (String) -> ()) -> UITableViewCell {
            var cell: TextFieldTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "textFieldDisplay") as? TextFieldTableViewCell
            if cell == nil {
                cell = TextFieldTableViewCell(style: .default, reuseIdentifier: "textFieldDisplay")
            }
            
            cell.textField.placeholder = placeholder
            cell.textField.text = text == "" ? nil : text
            cell.setEditingCallback(didBeginEditing)
            cell.setChangedCallback { (textField: UITextField) in
                let text = textField.text
                changedToText(text!)
            }
            
            return cell
        }

        func datePickerCell(day: CalendarDay, changedToDay: @escaping (CalendarDay) -> ()) -> UITableViewCell {
            var cell: DatePickerTableViewCell! = tableView.dequeueReusableCell(withIdentifier: "datePicker") as? DatePickerTableViewCell
            if cell == nil {
                cell = DatePickerTableViewCell(style: .default, reuseIdentifier: "datePicker")
            }
            
            cell.datePicker.datePickerMode = .date
            cell.datePicker.timeZone = CalendarDay.gmtTimeZone
            cell.datePicker.setDate(day.gmtDate, animated: false)
            cell.setCallback { (datePicker: UIDatePicker) in
                let day = CalendarDay(dateInGMTDay: datePicker.date)
                changedToDay(day)
            }
            
            return cell
        }
        
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .DescriptionCell:
            return textFieldDisplayCell(placeholder: "Description (e.g. \"Vacation in Hawaii\")",
                                        text: pause.shortDescription, didBeginEditing: { _ in
                if self.editingFirstDate {
                    self.editingFirstDate = false
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
                    tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
                    tableView.endUpdates()
                } else if self.editingLastDate {
                    self.editingLastDate = false
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
                    tableView.deleteRows(at: [IndexPath(row: 2, section: 1)], with: .fade)
                    tableView.endUpdates()
                }
            }, changedToText: { (text: String) in
                self.pause.shortDescription = text
            })
            
        case .FirstDayEffectiveDisplayCell:
            return dateDisplayCell(label: "Start", day: firstDayEffective) { self.editingFirstDate }
            
        case .FirstDayEffectiveDatePickerCell:
            return datePickerCell(day: firstDayEffective) { (day: CalendarDay) in
                self.pause.firstDayEffective = day
                if self.pause.firstDayEffective! > self.pause.lastDayEffective! {
                    self.pause.lastDayEffective = self.pause.firstDayEffective
                }
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
            
        case .LastDayEffectiveDisplayCell:
            return dateDisplayCell(label: "End", day: lastDayEffective) { self.editingLastDate }
            
        case .LastDayEffectiveDatePickerCell:
            return datePickerCell(day: lastDayEffective) { (day: CalendarDay) in
                self.pause.lastDayEffective = day
                if self.pause.firstDayEffective! > self.pause.lastDayEffective! {
                    self.pause.firstDayEffective = self.pause.lastDayEffective
                }
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return editingFirstDate || editingLastDate ? 3 : 2
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .FirstDayEffectiveDisplayCell, .LastDayEffectiveDisplayCell:
            return indexPath
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .FirstDayEffectiveDisplayCell:
            tableView.beginUpdates()
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
            if editingFirstDate {
                editingFirstDate = false
                tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
            } else {
                editingFirstDate = true
                tableView.insertRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
                if editingLastDate {
                    editingLastDate = false
                    tableView.deleteRows(at: [IndexPath(row: 2, section: 1)], with: .fade)
                    tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.endUpdates()
            self.view.endEditing(false)
        case .LastDayEffectiveDisplayCell:
            tableView.beginUpdates()
            tableView.reloadRows(at: [IndexPath(row: editingFirstDate ? 2 : 1, section: 1)], with: .fade)
            if editingLastDate {
                editingLastDate = false
                tableView.deleteRows(at: [IndexPath(row: 2, section: 1)], with: .fade)
            } else {
                editingLastDate = true
                tableView.insertRows(at: [IndexPath(row: 2, section: 1)], with: .fade)
                if editingFirstDate {
                    editingFirstDate = false
                    tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.endUpdates()
            self.view.endEditing(false)
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .FirstDayEffectiveDatePickerCell:
            return editingFirstDate ? 216 : 0
        case .LastDayEffectiveDatePickerCell:
            return editingLastDate ? 216 : 0
        default:
            return 44
        }
    }
}
