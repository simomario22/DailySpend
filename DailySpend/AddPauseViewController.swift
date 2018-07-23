//
//  PauseViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 9/9/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

class AddPauseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    var cellCreator: TableViewCellHelper!
    
    var delegate: AddPauseDelegate?
    
    var tableView: UITableView!
    
    var editingFirstDate = false
    var editingLastDate = false
    
    var pause: Pause?
    
    var shortDescription: String! = ""
    var firstDayEffective: CalendarDay!
    var lastDayEffective: CalendarDay!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up table view.
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        cellCreator = TableViewCellHelper(tableView: tableView)
        
        if let pause = self.pause {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, save)
            self.navigationItem.title = "Edit Pause"
            
            shortDescription = pause.shortDescription
            firstDayEffective = pause.firstDayEffective
            lastDayEffective = pause.lastDayEffective
        } else {
            firstDayEffective = CalendarDay()
            lastDayEffective = CalendarDay()
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, save)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) {
                self.view.endEditing(false)
                self.dismiss(animated: true, completion: nil)
            }
            self.navigationItem.title = "New Pause"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func save() {
        var justCreated = false
        if pause == nil {
            justCreated = true
            pause = Pause(context: context)
            pause!.dateCreated = Date()
        }
        
        let validation = pause!.propose(shortDescription: shortDescription,
                                         firstDayEffective: firstDayEffective,
                                         lastDayEffective: lastDayEffective)
        if validation.valid {
            appDelegate.saveContext()
            self.view.endEditing(false)
            delegate?.addedOrChangedPause(pause!)
            if self.navigationController!.viewControllers[0] == self {
                self.navigationController!.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController!.popViewController(animated: true)
            }
        } else {
            if justCreated {
                context.delete(pause!)
                pause = nil
                appDelegate.saveContext()
            }
            let alert = UIAlertController(title: "Couldn't Save",
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if firstDayEffective == lastDayEffective {
            let formattedDate = firstDayEffective.string(formatter: dateFormatter)
            return "Any expenses and money accrued on \(formattedDate) will be " +
                    "ignored when calculating the daily balance and any monthly " +
                    "goals."
        } else {
            let formattedFirstDate = firstDayEffective.string(formatter: dateFormatter)
            let formattedLastDate = lastDayEffective.string(formatter: dateFormatter)
            return "Any expenses and money accrued from \(formattedFirstDate) to " +
                    "\(formattedLastDate) will be ignored when calculating the " +
                    "daily balance and any monthly goals."
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellCreator == nil {
            return UITableViewCell()
        }
        
        switch cellTypeForIndexPath(indexPath: indexPath) {
        case .DescriptionCell:
            return cellCreator.textFieldDisplayCell(
                placeholder: "Description (e.g. \"Vacation in Hawaii\")",
                text: shortDescription,
                changedToText: { (text: String, _) in
                    self.shortDescription = text
                },
                didBeginEditing: { _ in
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
            })
            
        case .FirstDayEffectiveDisplayCell:
            return cellCreator.dateDisplayCell(
                label: "Start",
                day: firstDayEffective,
                tintColor: editingFirstDate ? view.tintColor : nil
            )
            
        case .FirstDayEffectiveDatePickerCell:
            return cellCreator.datePickerCell(day: firstDayEffective)
            { (day: CalendarDay) in
                self.firstDayEffective = day
                if self.firstDayEffective! > self.lastDayEffective! {
                    self.lastDayEffective = self.firstDayEffective
                }
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
            
        case .LastDayEffectiveDisplayCell:
            return cellCreator.dateDisplayCell(
                label: "End",
                day: lastDayEffective,
                tintColor: editingLastDate ? view.tintColor : nil,
                strikeText: firstDayEffective! > lastDayEffective!
            )

        case .LastDayEffectiveDatePickerCell:
            return cellCreator.datePickerCell(day: lastDayEffective)
            { (day: CalendarDay) in
                self.lastDayEffective = day
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

protocol AddPauseDelegate {
    func addedOrChangedPause(_ pause: Pause)
}
