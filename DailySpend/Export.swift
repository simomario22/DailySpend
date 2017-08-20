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
                return nil
            }
        } else {
            do {
                try fm.copyItem(at: imagesDirectory, to: exportDirectory)
            } catch {
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
        
        
        // Create directory and file.
        if !fm.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            do {
                try fm.createDirectory(at: directoryUrl,
                                       withIntermediateDirectories: false,
                                       attributes: nil)
            } catch {
                return nil
            }
        }
        
        if !fm.createFile(atPath: fileUrl.path, contents: Data(), attributes: nil) {
            return nil
        }
        
        guard let os = FileHandle(forWritingAtPath: fileUrl.path) else {
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
            throw ExportError.recoveredFromBadFormat
        }
    }
    
    private class func importZipUrl(_ url: URL) throws {
        let fm = FileManager.default
        
        // Move any images to a temporary directory.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy-HHmmss"
        let name = dateFormatter.string(from: Date())
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
                throw ExportError.recoveredFromFilesystemError
            }
            movedImages = true
        } else {
            do {
                try fm.createDirectory(at: imagesDirectory,
                                        withIntermediateDirectories: false,
                                        attributes: nil)
            } catch {
                throw ExportError.recoveredFromFilesystemError
            }
        }

        let cacheDirectory = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let unzippedName = url.deletingPathExtension().lastPathComponent
        let unzippedUrl = cacheDirectory.appendingPathComponent(unzippedName,
                                                                isDirectory: true)

        // Define a function to move the backed up images back if we need to revert
        func revert() throws {
            do {
                try fm.removeItem(at: url)
                try fm.removeItem(at: unzippedUrl)
            } catch { }
            
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
                throw ExportError.unrecoverableFilesystemError
            }
        }

        // Unzip archive.
        if !SSZipArchive.unzipFile(atPath: url.path,
                                  toDestination: cacheDirectory.path) {
            try revert()
            throw ExportError.recoveredFromBadFormat
        }
        
        if let contents = try? fm.contentsOfDirectory(at: unzippedUrl,
                                                     includingPropertiesForKeys: nil,
                                                     options: []) {
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
                        throw ExportError.recoveredFromFilesystemError
                    }
                }
            }
        } else {
            try revert()
            throw ExportError.recoveredFromFilesystemError
        }
        
        // All done, clean up
        do {
            try fm.removeItem(at: url)
            try fm.removeItem(at: unzippedUrl)
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
            try FileManager.default.removeItem(at: url)
        } catch {
            // We don't really care.
            Logger.warning("Could not delete backup store or import file.")
        }
    }
}
