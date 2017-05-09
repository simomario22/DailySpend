//
//  Export.swift
//  DailySpend
//
//  Created by Josh Sherick on 4/14/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
var context: NSManagedObjectContext {
    return appDelegate.persistentContainer.viewContext
}

let encoding = String.Encoding.utf8

func desc(_ obj: Any) -> String {
    return String(describing: obj)
}

class Exporter {
    class func exportPhotos() -> URL? {
        return nil
    }

    class func exportData() -> URL? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cacheDirectory = paths[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy-HHmmss"
        let name = dateFormatter.string(from: Date())
        let directoryPath = cacheDirectory + "/" + name
        let filePath = directoryPath + "/\(name).dailyspend"
        
        let fm = FileManager.default
        
        // Create directory and file.
        if !fm.fileExists(atPath: directoryPath, isDirectory: nil) {
            do {
                try fm.createDirectory(atPath: directoryPath,
                                       withIntermediateDirectories: false)
            } catch {
                return nil
            }
        }
        
        if !fm.createFile(atPath: filePath, contents: Data(), attributes: nil) {
            return nil
        }
        
        guard let os = FileHandle(forWritingAtPath: filePath) else {
            return nil
        }
        
        // Write opening JSON character.
        os.write("[".data(using: encoding)!)
        
        // Fetch all months
        let monthsFetchReq: NSFetchRequest<Month> = Month.fetchRequest()
        let monthSortDesc = NSSortDescriptor(key: "month_", ascending: true)
        monthsFetchReq.sortDescriptors = [monthSortDesc]
        guard let months = try? context.fetch(monthsFetchReq) else {
            os.closeFile()
            return nil
        }
        
        for (i, month) in months.enumerated() {
            if let monthData = month.serialize() {
                os.write(monthData)
            } else {
                os.closeFile()
                return nil
            }
            if i < months.count - 1 {
                // Write separating JSON character if there are more months 
                // after this one.
                os.write(",".data(using: encoding)!)
            }
        }
        
        // Write closing JSON character
        os.write("]".data(using: encoding)!)
        
        os.closeFile()
        return URL(fileURLWithPath: filePath)
    }
}

enum ExportError: Error {
    case unrecoverableDatabaseInBadState
    case recoveredFromBadFormat
    case recoveredFromPersistentStoreProblem
    case recoveredFromBadFormatWithContextChange
}

class Importer {
    class func importDataUrl(_ url: URL) throws {
        guard let stream = InputStream(url: url) else {
            throw ExportError.recoveredFromBadFormat
        }
        
        stream.open()
        
        guard let ambiguousObj = try? JSONSerialization.jsonObject(with: stream, options: []),
              let jsonObj = ambiguousObj as? [[String: Any]] else {
            throw ExportError.recoveredFromBadFormat
        }
        
        let managedObjMod = appDelegate.persistentContainer.managedObjectModel
        let storeCoord = appDelegate.persistentContainer.persistentStoreCoordinator
        if storeCoord.persistentStores.count != 1 {
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
            throw ExportError.recoveredFromPersistentStoreProblem
        }
        
        appDelegate.persistentContainer = nil
        
        for jsonMonth in jsonObj {
            if Month.create(context: context, json: jsonMonth) == nil {
                // This import failed. Reset to normal.
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
                    throw ExportError.unrecoverableDatabaseInBadState
                }
                throw ExportError.recoveredFromBadFormatWithContextChange
            }
        }
        
        do {
            // Import successful. Delete the backup store.
            try storeCoord.destroyPersistentStore(at: backupStoreURL,
                                                  ofType: NSSQLiteStoreType,
                                                  options: storeOptions)
        } catch {
            // We don't really care.
            print("Could not delete backup store.")
        }
        
    }
}
