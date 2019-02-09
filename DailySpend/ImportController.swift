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
            var title = LocalizedString("import.success.title")
            var message = LocalizedString("import.success.message")
            
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
                title = LocalizedString("import.failed.title")
                message = LocalizedString("import.failed.message.recoveredFromPersistentStoreProblem")
            } catch ExportError.recoveredFromBadFormat {
                // Recovered from failure due to an error parsing the import file.
                title = LocalizedString("import.failed.title")
                message = LocalizedString("import.failed.message.recoveredFromBadFormat")
            } catch ExportError.unrecoverableDatabaseInBadState {
                // Could not recover due to being unable to promote the backup
                // persistent store to the primary persistent store.
                title = LocalizedString("import.failed.title")
                message = LocalizedString("import.failed.message.unrecoverableDatabaseInBadState")
            } catch ExportError.recoveredFromBadFormatWithContextChange {
                // The context has changed. Any ManagedObjects stored in memory
                // will be invalidated and cause errors if used.
                // To ensure they aren't, we'll instantiate a new
                // TodayViewController and set it as the window's root VC.
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let initialVC = storyboard.instantiateInitialViewController()
                self.window?.rootViewController = initialVC
                self.visibleVC = initialVC

                title = LocalizedString("import.failed.title")
                message = LocalizedString("import.failed.message.recoveredFromBadFormatWithContextChange")

            } catch ExportError.recoveredFromFilesystemError {
                // Recovered from failure due to filesystem operations.
                title = LocalizedString("import.failed.title")
                message = LocalizedString("import.failed.message.recoveredFromFilesystemError")
            } catch ExportError.unrecoverableFilesystemError {
                // Could not recover from a failure due to filesystem operations.
                title = LocalizedString("import.failed.title")
                message = LocalizedString("import.failed.message.unrecoverableFilesystemError")
            } catch {
                // Catch-all to satisfy function type requirements.
                title = LocalizedString("import.failed.title")
                message = LocalizedString("import.failed.message.unknownError")
                Logger.debug("\(error)")
            }

            // Create and present alert.
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            let okay = UIAlertAction(title: LocalizedString("global.acknowledge"), style: .default, handler: nil)
            alert.addAction(okay)
            self.visibleVC?.present(alert, animated: true, completion: nil)
        }


        // Prompt user as to whether they would like to import.
        let title = LocalizedString("import.prompt.title")
        let message = LocalizedString("import.prompt.message")

        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: LocalizedString("global.cancel"),
                                   style: .cancel,
                                   handler: nil)
        let delete = UIAlertAction(title: LocalizedString("import.confirm.overwriteAndImport"),
                                   style: .destructive,
                                   handler: importHandler)
        alert.addAction(cancel)
        alert.addAction(delete)
        visibleVC?.present(alert, animated: true, completion: nil)
    }
}
