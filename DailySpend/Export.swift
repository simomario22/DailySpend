//
//  Export.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

fileprivate let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
fileprivate let encoding = String.Encoding.utf8

class Exporter {
    class func exportPhotos() -> URL? {
        let fm = FileManager.default
        let cacheDirectory = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let documentsDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy-HHmmss"
        let name = "DailySpendExport \(dateFormatter.string(from: Date()))"
        let exportDirectory = cacheDirectory.appendingPathComponent(name)
        
        if !fm.fileExists(atPath: imagesDirectory.path) {
            do {
                try fm.createDirectory(at: exportDirectory,
                                       withIntermediateDirectories: false,
                                       attributes: nil)
            } catch {
                Logger.debug("Could not create export directory.")
                return nil
            }
        } else {
            do {
                try fm.copyItem(at: imagesDirectory, to: exportDirectory)
            } catch {
                Logger.debug("Could not copy images directory to export directory.")
                return nil
            }
        }
        return exportDirectory
    }

    class func exportData() -> URL? {
        let fm = FileManager.default
        let paths = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectory = paths[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy-HHmmss"
        let name = dateFormatter.string(from: Date())
        let directoryUrl = cacheDirectory.appendingPathComponent(name)
        let fileUrl = directoryUrl.appendingPathComponent("/\(name).dailyspend")
        let context = appDelegate.persistentContainer.viewContext
        
        // Create directory and file.
        if !fm.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            do {
                try fm.createDirectory(at: directoryUrl,
                                       withIntermediateDirectories: false,
                                       attributes: nil)
            } catch {
                Logger.debug("Could not create directory for export file.")
                return nil
            }
        }
        
        if !fm.createFile(atPath: fileUrl.path, contents: Data(), attributes: nil) {
            Logger.debug("Could not create export file.")
            return nil
        }
        
        guard let os = FileHandle(forWritingAtPath: fileUrl.path) else {
            Logger.debug("Could not get handle for export file.")
            return nil
        }
        
        // Write opening JSON dictionary character, and a key for "defaults".
        os.write("{\"defaults\":".data(using: encoding)!)
        
        var defaults = [String: Any]()
        defaults["photoNumber"] = UserDefaults.standard.integer(forKey: "photoNumber")

        if let defaultsData = try? JSONSerialization.data(withJSONObject: defaults) {
            os.write(defaultsData)
        } else {
            Logger.debug("Could not serialize defaults object.")
            os.closeFile()
            return nil
        }
        
        // Write separating JSON character, a key for "goals" and an opening
        // JSON array character.
        os.write(",\"goals\":[".data(using: encoding)!)
        
        // Fetch all goals
        let goalSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        guard let goals = Goal.get(context: context,
                                     sortDescriptors: [goalSortDesc]) else {
            Logger.debug("Could not get goals.")
            os.closeFile()
            return nil
        }
        
        var goalJsonIdMap = [NSManagedObjectID: Int]()
        var currentJsonIdIndex = 0
        
        for goal in goals {
            goalJsonIdMap[goal.objectID] = currentJsonIdIndex
            currentJsonIdIndex += 1
        }
        
        for (i, goal) in goals.enumerated() {
            if let goalData = goal.serialize(jsonIds: goalJsonIdMap) {
                os.write(goalData)
            } else {
                Logger.debug("Could not serialize a Goal.")
                os.closeFile()
                return nil
            }
            if i < goals.count - 1 {
                // Write separating JSON character if there are more goals
                // after this one.
                os.write(",".data(using: encoding)!)
            }
        }
        
        // Write closing JSON array character, separating JSON character,
        // a key for "expenses" and an opening JSON array character.
        os.write("],\"expenses\":[".data(using: encoding)!)
        
        // Fetch all pauses
        let expenseSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        guard let expenses = Expense.get(context: context, sortDescriptors: [expenseSortDesc]) else {
            Logger.debug("Could not get expenses.")
            os.closeFile()
            return nil
        }
        
        for (i, expense) in expenses.enumerated() {
            if let expenseData = expense.serialize(jsonIds: goalJsonIdMap) {
                os.write(expenseData)
            } else {
                Logger.debug("Could not serialize an Expense.")
                os.closeFile()
                return nil
            }
            if i < expenses.count - 1 {
                // Write separating JSON character if there are more pauses
                // after this one.
                os.write(",".data(using: encoding)!)
            }
        }

        // Write closing JSON array character, separating JSON character, 
        // a key for "pauses" and an opening JSON array character.
        os.write("],\"pauses\":[".data(using: encoding)!)
        
        // Fetch all pauses
        let pauseSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        guard let pauses = Pause.get(context: context, sortDescriptors: [pauseSortDesc]) else {
            Logger.debug("Could not get pauses.")
            os.closeFile()
            return nil
        }
        
        for (i, pause) in pauses.enumerated() {
            if let pauseData = pause.serialize(jsonIds: goalJsonIdMap) {
                os.write(pauseData)
            } else {
                Logger.debug("Could not serialize a Pause.")
                os.closeFile()
                return nil
            }
            if i < pauses.count - 1 {
                // Write separating JSON character if there are more pauses
                // after this one.
                os.write(",".data(using: encoding)!)
            }
        }

        // Write closing JSON array character, separating JSON character,
        // a key for "adjustments" and an opening JSON array character.
        os.write("],\"adjustments\":[".data(using: encoding)!)
        
        // Fetch all months
        let adjustmentsSortDesc = NSSortDescriptor(key: "dateCreated_", ascending: true)
        guard let adjustments = Adjustment.get(context: context, sortDescriptors: [adjustmentsSortDesc]) else {
            Logger.debug("Could not get adjustments.")
            os.closeFile()
            return nil
        }

        var first = true
        for adjustment in adjustments {
            let (adjustmentData, failure) = adjustment.serialize(jsonIds: goalJsonIdMap)
            if let adjustmentData = adjustmentData {
                if !first {
                    os.write(",".data(using: encoding)!)
                }
                os.write(adjustmentData)
                first = false
            } else if failure {
                Logger.debug("Could not serialize an Adjustment.")
                os.closeFile()
                return nil
            }

        }
        
        // Write closing JSON array and dictionary characters
        os.write("]}".data(using: encoding)!)
        
        os.closeFile()
        return fileUrl
    }
}

enum ExportError: Error {
    case unrecoverableDatabaseInBadState
    case recoveredFromBadFormat
    case recoveredFromPersistentStoreProblem
    case recoveredFromBadFormatWithContextChange
    case recoveredFromFilesystemError
    case unrecoverableFilesystemError
}

class Importer {
    class func importURL(_ url: URL) throws {
        if url.lastPathComponent.contains(".dailyspend") {
            try importDataUrl(url)
        } else if url.lastPathComponent.contains(".zip") {
            try importZipUrl(url)
        } else {
            Logger.debug("The format extension wasn't valid.")
            throw ExportError.recoveredFromBadFormat
        }
    }
    
    private class func importZipUrl(_ url: URL) throws {
        let fm = FileManager.default
        
        // Move any images to a temporary directory.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy-HHmmss"
        let name = dateFormatter.string(from: Date()) + "-images"
        let documentsDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        let backupImagesDirectory = imagesDirectory.deletingLastPathComponent()
                                .appendingPathComponent(name, isDirectory: true)
        var movedImages = false
        if fm.fileExists(atPath: imagesDirectory.path) {
            do {
                try fm.moveItem(at: imagesDirectory, to: backupImagesDirectory)
                try fm.createDirectory(at: imagesDirectory,
                                       withIntermediateDirectories: false,
                                       attributes: nil)
            } catch {
                Logger.debug("Couldn't move existing images directory or create new images directory.")
                throw ExportError.recoveredFromFilesystemError
            }
            movedImages = true
        } else {
            do {
                try fm.createDirectory(at: imagesDirectory,
                                        withIntermediateDirectories: false,
                                        attributes: nil)
            } catch {
                Logger.debug("Couldn't create a new images directory.")
                throw ExportError.recoveredFromFilesystemError
            }
        }

        let cacheDirectory = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        // The url to unzip into, since we don't know what the unzipped folder
        // will be called.
        let unzipDirectory = cacheDirectory.appendingPathComponent(dateFormatter.string(from: Date()) + "-unzip")

        // Define a function to move the backed up images back if we need to revert
        func revert() throws {
            do {
                try fm.removeItem(at: url)
                try fm.removeItem(at: unzipDirectory)
            } catch {
                // We don't actually care, just log the error.
                Logger.debug("Could not remove zipped or unzipped URL.")
            }
            
            if !movedImages {
                // We never actually moved the images directory, we're done
                return
            }
            
            do {
                // Remove the old images directory and rename the backup folder
                // to "images"
                try fm.removeItem(at: imagesDirectory)
                try fm.moveItem(at: backupImagesDirectory, to: imagesDirectory)
            } catch {
                Logger.debug("Couldn't not remove the images directory or " +
                             "move the old images directory back.")
                throw ExportError.unrecoverableFilesystemError
            }
        }

        // Unzip archive.
        if !SSZipArchive.unzipFile(atPath: url.path,
                                  toDestination: unzipDirectory.path) {
            try revert()
            Logger.debug("Could not unzip archive.")
            throw ExportError.recoveredFromBadFormat
        }

        // The URL of the actual directory that was unzipped in the previous
        // process.
        var unzippedUrl: URL
        if let contents = try? fm.contentsOfDirectory(at: unzipDirectory,
                                                     includingPropertiesForKeys: nil,
                                                     options: []) {
            if contents.count == 1 {
                unzippedUrl = contents.first!
            } else {
                try revert()
                Logger.debug("Unexpected number of items in unzip directory.")
                throw ExportError.recoveredFromFilesystemError
            }
        } else {
            try revert()
            Logger.debug("Could not get contents of unzip directory.")
            throw ExportError.recoveredFromFilesystemError
        }

        if let contents = try? fm.contentsOfDirectory(
            at: unzippedUrl,
            includingPropertiesForKeys: nil,
            options: []
        ) {
            for fileUrl in contents {
                if fileUrl.lastPathComponent.contains(".dailyspend") {
                    // This is a data file, let's import that
                    try importDataUrl(fileUrl)
                } else {
                    // This is an image, move it to the images directory.
                    do {
                        let newUrl = imagesDirectory
                            .appendingPathComponent(fileUrl.lastPathComponent,
                                                    isDirectory: false)
                        try fm.moveItem(at: fileUrl, to: newUrl)
                    } catch {
                        try revert()
                        Logger.debug("Could not move image.")
                        throw ExportError.recoveredFromFilesystemError
                    }
                }
            }
        } else {
            try revert()
            Logger.debug("Could not get contents of unzipped directory.")
            throw ExportError.recoveredFromFilesystemError
        }

        // All done, clean up
        do {
            try fm.removeItem(at: url)
            try fm.removeItem(at: unzipDirectory)
            try fm.removeItem(at: backupImagesDirectory)
        } catch {
            // We don't really care.
            Logger.warning("Could not delete import zipped file, unzipped file, or images backup.")
        }
    }
    
    private class func importDataUrl(_ url: URL) throws {
        guard let stream = InputStream(url: url) else {
            throw ExportError.recoveredFromBadFormat
        }
        
        stream.open()
        
        guard let ambiguousObj = try? JSONSerialization.jsonObject(with: stream, options: [])
        else {
            Logger.debug("Could not deserialize JSON.")
            throw ExportError.recoveredFromBadFormat
        }
        
        guard let jsonObj = ambiguousObj as? [String: Any] else {
            // We didn't understand the format
            Logger.debug("JSON was not an object.")
            throw ExportError.recoveredFromBadFormat
        }

        let managedObjMod = appDelegate.persistentContainer.managedObjectModel
        let storeCoord = appDelegate.persistentContainer.persistentStoreCoordinator
        if storeCoord.persistentStores.count != 1 {
            Logger.debug("There wasn't exactly one persistent store.")
            throw ExportError.recoveredFromPersistentStoreProblem
        }
        
        let store = storeCoord.persistentStores.first!
        let storeURL = store.url!
        let storeOptions = store.options
        
        // Make backup copy of store.
        let backupStoreCoord = NSPersistentStoreCoordinator(managedObjectModel: managedObjMod)
        do {
            try backupStoreCoord.addPersistentStore(ofType: NSSQLiteStoreType,
                                                configurationName: nil,
                                                at: storeURL,
                                                options: storeOptions)
        } catch {
            Logger.debug("There wasn't exactly one persistent store.")
            throw ExportError.recoveredFromPersistentStoreProblem
        }
        
        let backupStore = backupStoreCoord.persistentStores.first!
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy-HHmmss"
        let name = dateFormatter.string(from: Date()) + ".sqlite"
        let backupStoreURL = storeURL.deletingLastPathComponent()
                                         .appendingPathComponent(name, isDirectory: false)
        
        do {
            try backupStoreCoord.migratePersistentStore(backupStore,
                                                  to: backupStoreURL,
                                                  options: storeOptions,
                                                  withType: NSSQLiteStoreType)
            try storeCoord.destroyPersistentStore(at: storeURL,
                                              ofType: NSSQLiteStoreType,
                                              options: storeOptions)
        } catch {
            Logger.debug("Could not migrate persistent store to backup or delete original store.")
            throw ExportError.recoveredFromPersistentStoreProblem
        }
        
        appDelegate.persistentContainer = nil

        // Define a function reset everything in case we need to revert
        func revert() throws {
            do {
                try storeCoord.replacePersistentStore(at: storeURL,
                                                      destinationOptions: storeOptions,
                                                      withPersistentStoreFrom: backupStoreURL,
                                                      sourceOptions: storeOptions,
                                                      ofType: NSSQLiteStoreType)
                
                // Delete the backup.
                try storeCoord.destroyPersistentStore(at: backupStoreURL,
                                                      ofType: NSSQLiteStoreType,
                                                      options: storeOptions)
                appDelegate.persistentContainer = nil
            } catch {
                // Reset failed.
                Logger.debug("Could not restore backup persistent store or delete backup store file.")
                throw ExportError.unrecoverableDatabaseInBadState
            }
        }

        let context = appDelegate.persistentContainer.newBackgroundContext()
        var contextError: ExportError?
        context.performAndWait {
            func saveContext() throws {
                do {
                    try context.save()
                } catch {
                    // This import failed. Reset to normal.
                    try revert()
                    throw ExportError.recoveredFromBadFormatWithContextChange
                }
            }

            do {
                try self.importJsonObjects(
                    context: context,
                    jsonObj: jsonObj,
                    revert: revert,
                    saveContext: saveContext
                )
                try saveContext()
            } catch {
                if let error = error as? ExportError {
                    contextError = error
                } else {
                    Logger.debug("\(error)")
                }
            }
        }

        if let error = contextError {
            throw error
        }

        // If there is a defaults array, set some defaults.
        if let defaults = jsonObj["defaults"] as? [String: Any] {
            for key in defaults.keys {
                switch key {
                case "photoNumber":
                    guard let photoNumber = defaults[key] as? NSNumber else {
                        try revert()
                        Logger.debug("Could not convert photo number to a number.")
                        throw ExportError.recoveredFromBadFormatWithContextChange
                    }
                    UserDefaults.standard.set(photoNumber.intValue, forKey: key)
                default:
                    // Ignore bad keys.
                    Logger.debug("There was an unrecognized key '\(key)' in defaults.")
                    continue
                }
            }
        }
        
        do {
            // Import successful. Delete the backup store.
            try storeCoord.destroyPersistentStore(at: backupStoreURL,
                                                  ofType: NSSQLiteStoreType,
                                                  options: storeOptions)
            try FileManager.default.removeItem(at: url)
        } catch {
            // We don't really care.
            Logger.warning("Could not delete backup store or import file.")
        }

        self.performPostImportDataProcessing()
    }

    private class func importJsonObjects(
        context: NSManagedObjectContext,
        jsonObj: [String: Any],
        revert: () throws -> (),
        saveContext: () throws -> ()
    ) throws {
        guard let goals = jsonObj["goals"] as? [[String: Any]] else {
            return
        }

        var goalJsonIdMap = [Int: NSManagedObjectID]()
        var maxIterations = goals.count
        var currentIteration = 0

        var goalsQueue = Array<[String: Any]>(goals)

        while currentIteration <= maxIterations && !goalsQueue.isEmpty {
            currentIteration += 1
            let jsonGoal = goalsQueue.popLast()!

            switch Goal.create(context: context, json: jsonGoal, jsonIds: goalJsonIdMap) {
            case .Failure:
                // This import failed. Reset to normal.
                try revert()
                Logger.debug("Could not import Goal.")
                throw ExportError.recoveredFromBadFormatWithContextChange
            case .NeedsOtherGoalsToBeCreatedFirst:
                goalsQueue.insert(jsonGoal, at: 0)
            case .Success(let goal):
                // Save so that the goal gets a permanent objectID.
                try saveContext()
                let id = goal.objectID
                if let jsonId = jsonGoal["jsonId"] as? NSNumber {
                    goalJsonIdMap[jsonId.intValue] = id
                }

                // Since we popped a goal, we potentially have to iterate
                // through the whole queue again to get a goal we can insert.
                maxIterations = goalsQueue.count
                currentIteration = 0
            }
        }

        if currentIteration > maxIterations {
            // Circular parents or one goal's parent doesn't exist.
            try revert()
            Logger.debug("Goals had invalid parent goals (e.g. circular) or a " +
                "specified parent goal doesn't exist.")
            throw ExportError.recoveredFromBadFormatWithContextChange
        }

        if let expenses = jsonObj["expenses"] as? [[String: Any]] {
            for jsonExpense in expenses {
                if Expense.create(context: context,
                                  json: jsonExpense,
                                  jsonIds: goalJsonIdMap) == nil {
                    // This import failed. Reset to normal.
                    try revert()
                    Logger.debug("Could not import Expense.")
                    throw ExportError.recoveredFromBadFormatWithContextChange
                }
            }
        }

        if let pauses = jsonObj["pauses"] as? [[String: Any]] {
            for jsonPause in pauses {
                if Pause.create(context: context,
                                json: jsonPause,
                                jsonIds: goalJsonIdMap) == nil {
                    // This import failed. Reset to normal.
                    try revert()
                    Logger.debug("Could not import Pause.")
                    throw ExportError.recoveredFromBadFormatWithContextChange
                }
            }
        }

        if let adjustments = jsonObj["adjustments"] as? [[String: Any]] {
            for jsonAdjustment in adjustments {
                if !Adjustment.create(context: context,
                                      json: jsonAdjustment,
                                      jsonIds: goalJsonIdMap).1 {
                    // This import failed. Reset to normal.
                    try revert()
                    Logger.debug("Could not import Adjustment.")
                    throw ExportError.recoveredFromBadFormatWithContextChange
                }
            }
        }

    }

    /**
     * Performs processing to ensure correct balances after a successfully
     * imported data set on a background thread.
     */
    private class func performPostImportDataProcessing() {
        let context = appDelegate.persistentContainer.viewContext
        let goals = Goal.get(context: context)
        for goal in goals ?? [] {
            let adjustmentManager = CarryOverAdjustmentManager(persistentContainer: appDelegate.persistentContainer)
            adjustmentManager.performPostImportTasks(for: goal, completion: {updated, inserted, deleted in
//                Logger.debug("updated carry over adjustments:")
//                for adj in updated ?? [] {
//                    Logger.printAdjustment(adj)
//                }
//
//                Logger.debug("inserted carry over adjustments:")
//                for adj in inserted ?? [] {
//                    Logger.printAdjustment(adj)
//                }
//
//                Logger.debug("deleted carry over adjustments:")
//                for adj in deleted ?? [] {
//                    Logger.printAdjustment(adj)
//                }
            })
        }
    }
}
