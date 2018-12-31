//
//  ExpenseSuggestionsViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/25/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

class AddQuickEntryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var tableView: UITableView!
    private var cellCreator: TableViewCellHelper!

    var value: String?
    var saved: ((String?) -> ())?

    private var initialLoad = true

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = value  == nil ? "New Option" : "Edit Option"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, {
                self.saved?(self.value)
                self.navigationController?.popViewController(animated: true)
        })

        self.tableView = UITableView(frame: self.view.bounds, style: .grouped)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.cellCreator = TableViewCellHelper(tableView: self.tableView)

        self.view.addSubview(self.tableView)

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cellCreator.textFieldDisplayCell(
            placeholder: "Quick Entry Option Text",
            text: self.value,
            changedToText: { (newValue, _) in
                self.value = newValue
        })

        if initialLoad {
            (cell as? TextFieldTableViewCell)?.textField.becomeFirstResponder()
            initialLoad = false
        }
        return cell
    }

}
