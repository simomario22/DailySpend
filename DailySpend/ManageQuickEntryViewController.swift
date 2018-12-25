//
//  ExpenseSuggestionsViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 12/25/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import UIKit

class ManageQuickEntryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var tableView: UITableView!
    private var toolbar: UIToolbar!
    private var values = [String]() {
        didSet {
            dataProvider.setQuickSuggestStrings(strings: values)
        }
    }
    private let dataProvider = ExpenseSuggestionDataProvider()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Quick Entry Options"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, {
                let vc = AddQuickEntryViewController()
                vc.saved = { value in
                    if let value = value {
                        self.values.append(value)
                    }
                }
                self.navigationController?.pushViewController(vc, animated: true)
        })

        self.toolbar = UIToolbar()
        self.toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .edit, toggleEditing)
        ]
        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.keyboardDismissMode = .interactive

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

    override func viewWillAppear(_ animated: Bool) {
        self.values = dataProvider.quickSuggestStrings()
        self.tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "quickSuggestCell"
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell.accessoryType = .disclosureIndicator
        }

        cell.textLabel!.text = values[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedValue = self.values[sourceIndexPath.row]
        self.values.remove(at: sourceIndexPath.row)
        self.values.insert(movedValue, at: destinationIndexPath.row)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.values.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = AddQuickEntryViewController()
        vc.value = self.values[indexPath.row]
        vc.saved = { value in
            if let value = value {
                self.values[indexPath.row] = value
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

}
