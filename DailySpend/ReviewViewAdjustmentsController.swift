//
//  ReviewViewAdjustmentsController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/2/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class ReviewViewAdjustmentsController: NSObject, AddAdjustmentDelegate, ReviewEntityDataProvider {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var delegate: ReviewEntityControllerDelegate
    
    struct AdjustmentCellDatum {
        var shortDescription: String?
        var amountDescription: String
        var datesDescription: String
        init(_ shortDescription: String?, _ amountDescription: String, _ datesDescription: String) {
            self.shortDescription = shortDescription
            self.amountDescription = amountDescription
            self.datesDescription = datesDescription
        }
    }
    private var goal: Goal?
    private var interval: CalendarIntervalProvider?
    private var adjustments: [Adjustment]
    private var adjustmentCellData: [AdjustmentCellDatum]
    private var section: Int
    private var cellCreator: TableViewCellHelper
    private var present: (UIViewController, Bool, (() -> Void)?) -> ()

    init(
        section: Int,
        cellCreator: TableViewCellHelper,
        delegate: ReviewEntityControllerDelegate,
        present: @escaping (UIViewController, Bool, (() -> Void)?) -> ()
    ) {
        self.goal = nil
        self.adjustments = []
        self.adjustmentCellData = []
        self.section = section
        self.cellCreator = cellCreator
        self.delegate = delegate
        self.present = present
    }
    
    private func makeAdjustmentCellDatum(_ adjustment: Adjustment) -> AdjustmentCellDatum {
        var description = adjustment.shortDescription
        if adjustment.isValidCarryOverAdjustmentType && interval != nil {
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .short
            let endOfPreviousPeriod = CalendarDay(dateInDay: interval!.start).subtract(days: 1).string(formatter: formatter)
            description = "Carry over from \(endOfPreviousPeriod)"
        }
        return AdjustmentCellDatum(
            description,
            String.formatAsCurrency(amount: adjustment.amountPerDay ?? 0)!,
            adjustment.humanReadableInterval()!
        )
    }

    func getLabelMessage() -> String {
        return "Adjustments"
    }

    func getCreateActions() -> [UIAlertAction] {
        var actions = [
            UIAlertAction(title: "New Adjustment", style: .default, handler: { _ in self.presentCreateModal() })
        ]
        if (goal?.isRecurring ?? false) && !self.adjustments.contains(where: { $0.type == .CarryOver }) {
            let carryOverAction = UIAlertAction(title: "Carry Over Balance", style: .default) { _ in
                guard let goal = self.goal,
                      let interval = self.interval else {
                    return
                }
                let manager = CarryOverAdjustmentManager(persistentContainer: self.appDelegate.persistentContainer)
                manager.enableCarryOverAdjustment(for: goal, on: CalendarDay(dateInDay: interval.start))  { (updatedAmount, deleted, inserted) in
                    guard let inserted = inserted,
                        let adjustment = Adjustment.inContext(inserted.first) as? Adjustment else {
                        return
                    }
                    let datum = self.makeAdjustmentCellDatum(adjustment)
                    self.adjustmentCellData.append(datum)
                    self.adjustments.append(adjustment)

                    self.delegate.addedEntity(
                        with: adjustment.effectiveInterval!,
                        within: adjustment.goal!,
                        at: IndexPath(row: self.adjustmentCellData.count - 1, section: self.section),
                        use: .automatic,
                        isOnlyEntity: self.adjustmentCellData.count == 1
                    )
                }
            }
            actions.append(carryOverAction)
        }
        return actions
    }
    
    func presentCreateModal() {
        guard let goal = goal else {
            return
        }
        let addAdjustmentVC = AddAdjustmentViewController()
        
        // Start by assuming today.
        var defaultTransactionDay = CalendarDay()
        if interval != nil && !interval!.contains(interval: defaultTransactionDay) {
            defaultTransactionDay = CalendarDay(dateInDay: interval!.start)
        }
        addAdjustmentVC.setupAdjustment(
            goal: goal,
            firstDayEffective: defaultTransactionDay,
            lastDayEffective: defaultTransactionDay
        )
        addAdjustmentVC.delegate = self
        let navCtrl = UINavigationController(rootViewController: addAdjustmentVC)
        self.present(navCtrl, true, nil)
    }
    
    private func remakeAdjustments() {
        adjustmentCellData = []
        adjustments = []
        guard let goal = self.goal,
              let interval = self.interval else {
            return
        }
        
        adjustments = goal.getAdjustments(context: appDelegate.persistentContainer.viewContext, interval: interval)
        for adjustment in adjustments {
            adjustmentCellData.append(makeAdjustmentCellDatum(adjustment))
        }

        let manager = CarryOverAdjustmentManager(persistentContainer: appDelegate.persistentContainer)
        manager.ensureProperAdjustmentsCreated(for: goal) {
            (updated, deleted, inserted) in
            guard updated != nil else {
                return
            }
            let viewContext = self.appDelegate.persistentContainer.viewContext
            var numDeleted = 0
            for (i, adjustment) in self.adjustments.enumerated() {
                let adjustmentId = adjustment.objectID
                if updated!.contains(adjustmentId) {
                    viewContext.refresh(adjustment, mergeChanges: true)
                    self.adjustmentCellData[i - numDeleted] = self.makeAdjustmentCellDatum(adjustment)

                    self.delegate.editedEntity(
                        with: adjustment.effectiveInterval!,
                        within: adjustment.goal!,
                        at: IndexPath(row: i - numDeleted, section: self.section),
                        movedTo: nil,
                        use: .automatic
                    )
                } else if deleted!.contains(adjustmentId) {
                    self.adjustmentCellData.remove(at: i - numDeleted)
                    self.adjustments.remove(at: i - numDeleted)
                    self.delegate.deletedEntity(
                        at: IndexPath(row: i - numDeleted, section: self.section),
                        use: .automatic,
                        isOnlyEntity: self.adjustmentCellData.isEmpty
                    )
                    numDeleted += 1
                }
            }
            for adjustmentId in inserted! {
                let adjustment = Adjustment.inContext(adjustmentId) as! Adjustment
                if adjustment.type == .CarryOverDeleted ||
                   !interval.contains(date: adjustment.firstDayEffective!.start) {
                    continue
                }
                let datum = self.makeAdjustmentCellDatum(adjustment)
                self.adjustmentCellData.append(datum)
                self.adjustments.append(adjustment)

                self.delegate.addedEntity(
                    with: adjustment.effectiveInterval!,
                    within: adjustment.goal!,
                    at: IndexPath(row: self.adjustmentCellData.count - 1, section: self.section),
                    use: .automatic,
                    isOnlyEntity: self.adjustmentCellData.count == 1
                )
            }
        }
    }
    
    func setGoal(_ newGoal: Goal?, interval: CalendarIntervalProvider) {
        self.goal = newGoal
        self.interval = interval
        remakeAdjustments()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(adjustmentCellData.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if adjustmentCellData.isEmpty {
            return cellCreator.centeredLabelCell(labelText: "No Adjustments", disabled: true)
        }
        
        let row = indexPath.row
        let description = adjustmentCellData[row].shortDescription ?? "No Description"
        let value = adjustmentCellData[row].amountDescription
        return cellCreator.optionalDescriptorValueCell(
            description: description,
            undescribed: adjustmentCellData[row].shortDescription == nil,
            value: value,
            detailButton: !adjustments[row].isValidCarryOverAdjustmentType
        )
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        self.tableView(tableView, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if adjustmentCellData.count == 0 || adjustments[indexPath.row].isValidCarryOverAdjustmentType {
            return
        }
        
        let addAdjustmentVC = AddAdjustmentViewController()
        addAdjustmentVC.delegate = self
        addAdjustmentVC.adjustmentId = adjustments[indexPath.row].objectID
        let navCtrl = UINavigationController(rootViewController: addAdjustmentVC)
        self.present(navCtrl, true, nil)

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return adjustmentCellData.count > 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        let row = indexPath.row
        let context = appDelegate.persistentContainer.newBackgroundContext()
        let adjustment = Adjustment.inContext(adjustments[row], context: context)!

        if adjustment.isValidCarryOverAdjustmentType {
            adjustment.type = .CarryOverDeleted
        } else {
            context.delete(adjustment)
        }
        try! context.save()
        
        adjustments.remove(at: row)
        adjustmentCellData.remove(at: row)
        delegate.deletedEntity(at: indexPath, use: .automatic, isOnlyEntity: adjustments.count == 0)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func createdAdjustmentFromModal(_ adjustment: Adjustment) {
        remakeAdjustments()
        let row = adjustments.firstIndex(of: adjustment)
        let path = IndexPath(row: row ?? 0, section: section)
        delegate.addedEntity(
            with: adjustment.effectiveInterval!,
            within: adjustment.goal!,
            at: path,
            use: .automatic,
            isOnlyEntity: adjustmentCellData.count == 1
        )
    }
    
    func editedAdjustmentFromModal(_ adjustment: Adjustment) {
        guard let origRow = adjustments.firstIndex(of: adjustment) else {
            return
        }
        
        remakeAdjustments()
        if let newRow = adjustments.firstIndex(of: adjustment) {
            // This adjustment is still in this view, but did not necesarily
            // switch rows.
            adjustmentCellData[newRow] = makeAdjustmentCellDatum(adjustment)
            delegate.editedEntity(
                with: adjustment.effectiveInterval!,
                within: adjustment.goal!,
                at: IndexPath(row: origRow, section: section),
                movedTo: origRow != newRow ? IndexPath(row: newRow, section: section) : nil,
                use: .automatic
            )
        } else {
            // This adjustment switched goals or intervals and is no longer in
            // this view.
            delegate.editedEntity(
                with: adjustment.effectiveInterval!,
                within: adjustment.goal!,
                at: IndexPath(row: origRow, section: section),
                movedTo: nil,
                use: .automatic
            )
        }
    }
}
