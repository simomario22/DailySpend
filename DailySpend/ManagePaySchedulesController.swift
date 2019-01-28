//
//  ManagePaySchedulesController.swift
//  DailySpend
//
//  Created by Josh Sherick on 1/27/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import UIKit

class ManagePaySchedulesController: UIViewController {
    var delegate: ManagedPaySchedulesControllerDelegate?
    var paySchedules: [StagedPaySchedule]!

    private var tableView: UITableView!
    private var toolbar: UIToolbar!
    private var paySchedulesWithGaps: [StagedPaySchedule?]!
    private var cellCreator: TableViewCellHelper!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Pay Schedules"
        self.navigationController?.delegate = self

        let sortedSchedules = sortPaySchedules(schedules: paySchedules)
        self.paySchedulesWithGaps = createGapSchedules(schedules: sortedSchedules)

        self.toolbar = UIToolbar()
        self.toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .edit, toggleEditing)
        ]
        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.keyboardDismissMode = .interactive
        self.cellCreator = TableViewCellHelper(tableView: self.tableView)

        self.view.addSubviews([self.tableView, self.toolbar])

        self.toolbar.translatesAutoresizingMaskIntoConstraints = false
        let toolbarConstraints = [
            self.toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            self.toolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            self.toolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ]
        NSLayoutConstraint.activate(toolbarConstraints)

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        let tableViewConstraints = [
            self.tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.toolbar.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ]
        NSLayoutConstraint.activate(tableViewConstraints)
    }

    func toggleEditing() {
        if self.tableView.isEditing {
            self.tableView.setEditing(false, animated: true)
            self.toolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .edit, toggleEditing)
            ]
        } else {
            self.tableView.setEditing(true, animated: true)
            self.toolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .done, toggleEditing)
            ]
        }
    }

    /**
     * Sorts schedules by start date.
     */
    func sortPaySchedules(schedules: [StagedPaySchedule]) -> [StagedPaySchedule] {
        return schedules.sorted(by: { $0.start!.gmtDate < $1.start!.gmtDate })
    }

    /**
     * Adds `nil` elements where there should be pay schedules.
     */
    func createGapSchedules(schedules: [StagedPaySchedule]) -> [StagedPaySchedule?] {
        var gapSchedules = [StagedPaySchedule?]()
        for (i, schedule) in schedules.enumerated() {
            if i != schedules.count - 1 && schedule.end != nil && schedule.end!.gmtDate < schedules[i + 1].start!.gmtDate {
                gapSchedules.append(nil)
            }
            gapSchedules.append(schedule)
        }
        return gapSchedules
    }

    func shortHumanScheduleDescription(schedule: StagedPaySchedule) -> String {
        let realSchedule = PaySchedule()
        realSchedule.amount = schedule.amount!
        realSchedule.period = schedule.period!
        realSchedule.payFrequency = schedule.payFrequency!
        return realSchedule.string()!
    }
}

extension ManagePaySchedulesController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paySchedulesWithGaps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return paySchedulesWithGaps[indexPath.row] != nil
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            paySchedulesWithGaps.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ManagePaySchedulesController: UINavigationControllerDelegate {

}

protocol ManagedPaySchedulesControllerDelegate {
    func updatedPaySchedules(schedules: [StagedPaySchedule]!, initial: StagedPaySchedule, valid: Bool)
}
