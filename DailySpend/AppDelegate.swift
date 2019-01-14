//
//  AppDelegate.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/6/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var spendIndicationColor: UIColor? {
        didSet {
            let nc = NotificationCenter.default
            nc.post(name: NSNotification.Name.init("ChangedSpendIndicationColor"),
                    object: UIApplication.shared)
        }
    }

    /**
     * Deletes all Adjustments and Expenses that don't have a parent
     * goal.
     * This should be removed eventually, now that we cascade delete.
     */
    func deleteAllOrphans() {
        var withoutParentGoal = [NSManagedObject]()

        withoutParentGoal += Expense.get(context: persistentContainer.viewContext)!.filter({ return $0.goal == nil }) as [NSManagedObject]
        withoutParentGoal += Adjustment.get(context: persistentContainer.viewContext)!.filter({ return $0.goal == nil }) as [NSManagedObject]

        let context = persistentContainer.newBackgroundContext()
        for obj in withoutParentGoal {
            let objInContext = context.object(with: obj.objectID)
            context.delete(objInContext)
        }
        if context.hasChanges {
            try! context.save()
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //deleteAllOrphans()
//        Logger.printAllCoreData()
        //let balanceCalculator = GoalBalanceCalculator(persistentContainer: persistentContainer)
        let carryOverManager = CarryOverAdjustmentManager(persistentContainer: persistentContainer)
        let goals = Goal.get(context: persistentContainer.viewContext)
        let group = DispatchGroup()
        for goal in goals! {
            group.enter()
            carryOverManager.updateCarryOverAdjustments(for: goal) { (_, _, _) in
                group.leave()
            }
        }

        group.notify(queue: .main) {
            Logger.debug("Totally finished!")
        }

        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.pathExtension == "dailyspend" || url.pathExtension == "zip" else {
            return false
        }
        
        let rootVC = window?.rootViewController
        var visibleVC = getVisibleViewController(rootVC)
        
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
                visibleVC = initialVC
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
                visibleVC = initialVC
                
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
            visibleVC?.present(alert, animated: true, completion: nil)
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

        
        return true
    }
    
    func getVisibleViewController(_ rootViewController: UIViewController?) -> UIViewController? {
        
        var rootVC = rootViewController
        if rootVC == nil {
            rootVC = UIApplication.shared.keyWindow?.rootViewController
        }
        
        if rootVC?.presentedViewController == nil {
            return rootVC
        }
        
        if let presented = rootVC?.presentedViewController {
            if presented.isKind(of: UINavigationController.self) {
                let navigationController = presented as! UINavigationController
                return navigationController.viewControllers.last!
            }
            
            if presented.isKind(of: UITabBarController.self) {
                let tabBarController = presented as! UITabBarController
                return tabBarController.selectedViewController!
            }
            
            return getVisibleViewController(presented)
        }
        return nil
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        //NotificationCenter.default.removeObserver(self, name: Notification.Name.NSCalendarDayChanged, object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //NotificationCenter.default.addObserver(self, selector: #selector(createUpToToday), name: Notification.Name.NSCalendarDayChanged, object: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack
    
    var _persistentContainer: NSPersistentContainer? = nil
    
    var persistentContainer: NSPersistentContainer! {
        get {
            if let pc = _persistentContainer {
                return pc
            }
            
            /*
             The persistent container for the application. This implementation
             creates and returns a container, having loaded the store for the
             application to it. This property is optional since there are legitimate
             error conditions that could cause the creation of the store to fail.
            */
            let container = NSPersistentContainer(name: "DailySpend")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            
            _persistentContainer = container
            return _persistentContainer
        }
        
        set {
            _persistentContainer = newValue
        }
    }



    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

