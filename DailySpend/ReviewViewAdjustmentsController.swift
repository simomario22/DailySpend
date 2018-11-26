//
//  ReviewViewAdjustmentsController.swift
//  DailySpend
//
//  Created by Josh Sherick on 11/2/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation

class ReviewViewAdjustmentsController: NSObject, AddAdjustmentDelegate, ReviewEntityDataProvider {
    
    var delegate: ReviewEntityControllerDelegate
    
    struct AdjustmentCellDatum {
        var shortDescription: String?
        var amountDescription: String
        var datesDescription: String
        init(_ shortDescription: String, _ amountDescription: String, _ datesDescription: String) {
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
        return AdjustmentCellDatum(
            adjustment.shortDescription!,
            String.formatAsCurrency(amount: adjustment.amountPerDay ?? 0)!,
            adjustment.humanReadableInterval()!
        )
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
        
        adjustments = goal.getAdjustments(interval: interval)
        for adjustment in adjustments {
            adjustmentCellData.append(makeAdjustmentCellDatum(adjustment))
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
            detailButton: true
        )
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        self.tableView(tableView, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if adjustmentCellData.count == 0 {
            return
        }
        
        let addAdjustmentVC = AddAdjustmentViewController()
        addAdjustmentVC.delegate = self
        addAdjustmentVC.adjustment = adjustments[indexPath.row]
        let navCtrl = UINavigationController(rootViewController: addAdjustmentVC)
        self.present(navCtrl, true, nil)

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return adjustmentCellData.count > 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        let row = indexPath.row
        let adjustment = adjustments[row]
        context.delete(adjustment)
        appDelegate.saveContext()
        
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
