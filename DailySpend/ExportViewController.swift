//
//  ExportViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/4/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import ZipArchive

class ExportViewController: UITableViewController {
    
    enum ExportableItem {
        case Photos
        case Data
    }
    
    var itemsToExport = [ExportableItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Export"
        let exportButton = UIBarButtonItem(title: "Export",
                                           style: .plain,
                                           target: self,
                                           action: #selector(exportPressed))
        self.navigationItem.rightBarButtonItem = exportButton
        
        itemsToExport.append(.Data)
        itemsToExport.append(.Photos)
    }
    
    func export(_ containsPhotos: Bool, _ containsData: Bool) {
        func failure(_ location: String? = nil, message: String? = nil) {
            let title = "Failed"
            let message = message != nil ? message! :
                    "Export failed due to an issue while \(location!). " +
                    "Sorry, try again later or contact support."
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
            alert.addAction(okay)
            self.present(alert, animated: true, completion: nil)
        }
        
        var shareURL: URL! = nil
        var directoryURL: URL! = nil
        var fileURL: URL? = nil
        
        if containsData {
            fileURL = Exporter.exportData()
            directoryURL = fileURL?.deletingLastPathComponent()
            guard directoryURL != nil else {
                failure("exporting data")
                return
            }
        }
        
        if containsPhotos {
            directoryURL = Exporter.exportPhotos()
            guard directoryURL != nil else {
                // Export failed.
                failure("exporting photos")
                return
            }
        }
        
        if containsData && containsPhotos {
            let fm = FileManager.default
            let newFileURL = directoryURL.appendingPathComponent(fileURL!.lastPathComponent)
            do {
                try fm.moveItem(at: fileURL!, to: newFileURL)
            } catch {
                failure("creating the directory to zip")
                return
            }
        }
        
        
        if containsData && !containsPhotos {
            shareURL = fileURL
        } else {
            let fm = FileManager.default
            if let count = try? fm.contentsOfDirectory(atPath: directoryURL.path).count {
                if count == 0 {
                    failure(message: "There's nothing to export with the selected options.")
                    return
                }
                    
            }
            
            let zipURL = directoryURL.appendingPathExtension("zip")
            if !SSZipArchive.createZipFile(atPath: zipURL.path,
                                           withContentsOfDirectory: directoryURL.path,
                                           keepParentDirectory: true) {
                failure("zipping files")
                return
            }
            
            shareURL = zipURL
        }
        
        let activityView = UIActivityViewController(activityItems: [shareURL],
                                                    applicationActivities: nil)

        activityView.completionWithItemsHandler = { (_, completed: Bool, _, _) in
            // Attempt to delete shared files.
            let fm = FileManager.default
            try? fm.removeItem(at: shareURL)
            try? fm.removeItem(at: directoryURL)
        }

        self.present(activityView, animated: true, completion: nil)
    }

    @objc func exportPressed() {
        let containsPhotos = itemsToExport.contains(.Photos)
        let containsData = itemsToExport.contains(.Data)
        guard containsData || containsPhotos else {
            return
        }

        let exportButton = self.navigationItem.rightBarButtonItem

        // Initialize spinner and frame and add to nav bar.
        let spinner = UIActivityIndicatorView(style: .gray)
        let bbi = UIBarButtonItem(customView: spinner)
        spinner.startAnimating()

        self.navigationItem.rightBarButtonItem = bbi

        // Run asyncronously in order to let view update with spinner.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            self.export(containsPhotos, containsData)
            self.navigationItem.rightBarButtonItem = exportButton
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let containsPhotos = itemsToExport.contains(.Photos)
        let containsData = itemsToExport.contains(.Data)
        
        if containsData && containsPhotos {
            // Both data and photos are selected.
            return "Photos and data will be zipped. Data is in a JSON format."
        } else if containsPhotos {
            // Only photos is selected.
            return "Photos will be zipped."
        } else if containsData {
            // Only data is selected.
            return "Data will be in JSON format."
        } else {
            // Nothing is selected.
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        let row = indexPath.row
        let containsPhotos = itemsToExport.contains(.Photos)
        let containsData = itemsToExport.contains(.Data)
        
        switch row {
        case 0:
            cell.textLabel!.text! = "Photos"
            cell.accessoryType = containsPhotos ? .checkmark : .none
        case 1:
            cell.textLabel!.text! = "Data"
            cell.accessoryType = containsData ? .checkmark : .none
        default: break
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        if row == 0 {
            if let index = itemsToExport.index(of: .Photos) {
                // This was already selected, deselect it.
                itemsToExport.remove(at: index)
            } else {
                itemsToExport.append(.Photos)
            }
        } else if row == 1 {
            if let index = itemsToExport.index(of: .Data) {
                // This was already selected, deselect it.
                itemsToExport.remove(at: index)
            } else {
                itemsToExport.append(.Data)
            }
        }
        
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationItem.rightBarButtonItem!.isEnabled = !itemsToExport.isEmpty
    }

}
