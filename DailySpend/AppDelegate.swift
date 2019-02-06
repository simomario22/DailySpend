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
        context.performAndWait {
            for obj in withoutParentGoal {
                let objInContext = context.object(with: obj.objectID)
                context.delete(objInContext)
            }
            if context.hasChanges {
                try! context.save()
            }
        }
    }

    func migrateGoalSchedules() {
        let context = persistentContainer.newBackgroundContext()
        context.performAndWait {
            let needsSchedule = Goal.get(context: context)?.filter{ $0.paySchedules?.isEmpty ?? true }

            for goal in needsSchedule ?? [] {
                let schedule = PaySchedule(context: context)
                let validation = schedule.propose(
                    amount: goal.amount,
                    start: goal.start,
                    end: goal.end,
                    period: goal.period,
                    payFrequency: goal.payFrequency,
                    adjustMonthAmountAutomatically: goal.adjustMonthAmountAutomatically,
                    goal: goal,
                    dateCreated: Date()
                )

                if !validation.valid {
                    Logger.debug("Error creating pay schedule: \(validation.problem ?? "")")
                    context.rollback()
                    fatalError() // can't continue without a pay schedule.
                }
                goal.amount = nil
                goal.start = nil
                goal.end = nil
                goal.period = .none
                goal.payFrequency = .none
                goal.adjustMonthAmountAutomatically = false
            }
            if context.hasChanges {
                try! context.save()
            }
        }
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        deleteAllOrphans()
        migrateGoalSchedules()
        Logger.printAllCoreData()

        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.pathExtension == "dailyspend" || url.pathExtension == "zip" else {
            return false
        }
        
        let rootVC = window?.rootViewController
        let visibleVC = getVisibleViewController(rootVC)

        let importController = ImportController(visibleVC: visibleVC, window: window)
        importController.promptToImport(url: url)
        
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

