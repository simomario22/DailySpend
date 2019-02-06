//
//  ImportViewController.swift
//  DailySpend
//
//  Created by Josh Sherick on 2/5/19.
//  Copyright © 2019 Josh Sherick. All rights reserved.
//

import Foundation

class ImportController {
    var visibleVC: UIViewController?
    let window: UIWindow?
    init(visibleVC: UIViewController?, window: UIWindow?) {
        self.visibleVC = visibleVC
        self.window = window
    }

    func promptToImport(url: URL) {
        let importHandler: (UIAlertAction) -> Void = { _ in
            // Initialize import feedback message.
            var title = "Success"
            var message = "The import has succeeded. Your data file has been " +
            "loaded into the app."

            do {
                // Attempt to import.
                try Importer.importURL(url)
                // Success, load the main screen.
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let initialVC = storyboard.instantiateInitialViewController()
                self.window?.rootViewController = initialVC
                self.visibleVC = initialVC
            } catch ExportError.recoveredFromPersistentStoreProblem {
                // Recovered from failure due to an error moving or accessing the
                // persistent store.
                title = "Failed"
                message = "Import failed. Please check that your device isn't " +
                    "running low on space. Your data has been restored " +
                "to the state before the import."
            } catch ExportError.recoveredFromBadFormat {
                // Recovered from failure due to an error parsing the import file.
                title = "Failed"
                message = "Import failed. Please check that the file you " +
                    "are trying to import is valid. Your data has been " +
                "restored to the state before the import."
            } catch ExportError.unrecoverableDatabaseInBadState {
                // Could not recover due to being unable to promote the backup
                // persistent store to the primary persistent store.
                title = "Failed"
                message = "Import failed. Unfortunately, we were not able " +
                    "to recover to the state before import, possibly " +
                    "due to a number of factors, one of which could be " +
                    "low space on your device. Check that the imported " +
                    "file is in a correct format and that your device " +
                    "has sufficient space and try again. Sorry for " +
                    "this inconvenience. If you need help, please " +
                "contact support."
            } catch ExportError.recoveredFromBadFormatWithContextChange {
                // The context has changed. Any ManagedObjects stored in memory
                // will be invalidated and cause errors if used.
                // To ensure they aren't, we'll instantiate a new
                // TodayViewController and set it as the window's root VC.
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let initialVC = storyboard.instantiateInitialViewController()
                self.window?.rootViewController = initialVC
                self.visibleVC = initialVC

                title = "Failed"
                message = "Import failed. Please check that the file you " +
                    "are trying to import is valid. Your data has been restored " +
                "to the state before the import."
            } catch ExportError.recoveredFromFilesystemError {
                // Recovered from failure due to filesystem operations.
                title = "Failed"
                message = "Import failed. Please check that your device isn't " +
                    "running low on space. Your data has been restored " +
                "to the state before the import."
            } catch ExportError.unrecoverableFilesystemError {
                // Could not recover from a failure due to filesystem operations.
                title = "Failed"
                message = "Import failed. Unfortunately, we were not able " +
                    "to recover to the state before import, possibly " +
                    "due to a number of factors, one of which could be " +
                    "low space on your device. Check that the imported " +
                    "file is in a correct format and that your device " +
                    "has sufficient space and try again. Sorry for " +
                    "this inconvenience. If you need help, please " +
                "contact support."
            } catch {
                // Catch-all to satisfy function type requirements.
                title = "Failed"
                message = "There was an unknown error."
                Logger.debug("\(error)")
            }

            // Create and present alert.
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
            alert.addAction(okay)
            self.visibleVC?.present(alert, animated: true, completion: nil)
        }


        // Prompt user as to whether they would like to import.
        let title = "Import"
        let message = "Would you like to import this data file to your app? " +
            "This will overwrite any existing data. If you haven't " +
            "made a backup of your existing data, tap cancel, go to " +
            "the Settings menu, export your data, and make a copy " +
            "somewhere safe."

        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        let delete = UIAlertAction(title: "Overwrite and Import",
                                   style: .destructive,
                                   handler: importHandler)
        alert.addAction(cancel)
        alert.addAction(delete)
        visibleVC?.present(alert, animated: true, completion: nil)
    }
}
