//
//  ExportViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/4/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit

class ExportViewController: UITableViewController {
    
    enum ExportableItem {
        case Photos
        case Data
    }
    
    @IBOutlet weak var photosCell: UITableViewCell!
    @IBOutlet weak var dataCell: UITableViewCell!
    
    var itemsToExport = [ExportableItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Export"
        let exportButton = UIBarButtonItem(title: "Export",
                                           style: .plain,
                                           target: self,
                                           action: #selector(export))
        self.navigationItem.rightBarButtonItem = exportButton
        
        itemsToExport.append(.Data)
        //itemsToExport.append(.Photos)
        photosCell.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    func export() {
        let containsPhotos = itemsToExport.contains(.Photos)
        let containsData = itemsToExport.contains(.Data)
        guard containsData || containsPhotos else {
            return
        }
        
        func failure(_ location: String) {
            let title = "Failed"
            let message = "Export failed due to an issue while \(location). " +
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
        
        shareURL = directoryURL
        
        if !(containsData && !containsPhotos) {
            let zipURL = directoryURL.appendingPathExtension("zip")
            
            if !SSZipArchive.createZipFile(atPath: zipURL.absoluteString,
                                           withContentsOfDirectory: directoryURL.absoluteString) {
                failure("zipping files")
                return
            }
            
            shareURL = zipURL
        } else {
            shareURL = fileURL
        }
        
        let activityView = UIActivityViewController(activityItems: [shareURL],
                                                    applicationActivities: nil)
        self.present(activityView, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changedSelection() {
        let containsPhotos = itemsToExport.contains(.Photos)
        let containsData = itemsToExport.contains(.Data)
        let footerLabel = tableView.footerView(forSection: 0)?.contentView.subviews[0] as! UILabel
        
        self.navigationItem.rightBarButtonItem!.isEnabled = true
        
        if containsData && containsPhotos {
            // Both data and photos are selected.
            let message = "Photos and data will be zipped. Data is in a JSON format."
            footerLabel.text = message
        } else if containsPhotos {
            // Only photos is selected.
            let message = "Photos will be zipped."
            footerLabel.text = message
        } else if containsData {
            // Only data is selected.
            let message = "Data will be in JSON format."
            footerLabel.text = message
        } else {
            // Nothing is selected.
            let message = ""
            footerLabel.text = message
            self.navigationItem.rightBarButtonItem!.isEnabled = false
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        if row == 0 {
            if let index = itemsToExport.index(of: .Photos) {
                // This was already selected, deselect it.
                itemsToExport.remove(at: index)
                photosCell.accessoryType = .none
            } else {
                itemsToExport.append(.Photos)
                photosCell.accessoryType = .checkmark
            }
        } else if row == 1 {
            if let index = itemsToExport.index(of: .Data) {
                // This was already selected, deselect it.
                itemsToExport.remove(at: index)
                dataCell.accessoryType = .none
            } else {
                itemsToExport.append(.Data)
                dataCell.accessoryType = .checkmark
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
        changedSelection()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
