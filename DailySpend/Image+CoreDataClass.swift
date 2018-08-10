//
//  Image+CoreDataClass.swift
//  DailySpend
//
//  Created by Josh Sherick on 6/29/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

@objc(Image)
class Image: NSManagedObject {
    
    func json() -> [String: Any]? {
        var jsonObj = [String: Any]()
        
        if let imageName = imageName {
            jsonObj["imageName"] = imageName
        } else {
            Logger.debug("couldn't unwrap imageName in Image")
            return nil
        }
        
        if let dateCreated = dateCreated {
            let num = dateCreated.timeIntervalSince1970 as NSNumber
            jsonObj["dateCreated"] = num
        } else {
            Logger.debug("couldn't unwrap dateCreated in Image")
            return nil
        }
        
        return jsonObj
    }
    
    func serialize() -> Data? {
        if let jsonObj = self.json() {
            let serialization = try? JSONSerialization.data(withJSONObject: jsonObj)
            return serialization
        }
        
        return nil
    }
    
    class func create(context: NSManagedObjectContext,
                      json: [String: Any]) -> Image? {
        let image = Image(context: context)
        
        if let imageName = json["imageName"] as? String {
            if imageName.count == 0 {
                Logger.debug("imageName is empty in Image")
                return nil
            }
            image.imageName = imageName
        } else {
            Logger.debug("couldn't unwrap imageName in Image")
            return nil
        }
        
        if let dateCreated = json["dateCreated"] as? NSNumber {
            let date = Date(timeIntervalSince1970: dateCreated.doubleValue)
            if date > Date() {
                Logger.debug("dateCreated after today in Image")
                return nil
            }
            image.dateCreated = date
        } else {
            Logger.debug("couldn't unwrap dateCreated in Image")
            return nil
        }
        
        return image
    }
    
    
    var dateCreated: Date? {
        get {
            return dateCreated_ as Date?
        }
        set {
            if newValue != nil {
                dateCreated_ = newValue! as NSDate
            } else {
                dateCreated_ = nil
            }
        }
    }
    
    var imageName: String? {
        get {
            return imageName_
        }
        set {
            imageName_ = newValue
        }
    }
    
    var imageURL: URL? {
        if let imageName = self.imageName {
            let fm = FileManager.default
            let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
            let imagesDirUrl = urls[0].appendingPathComponent("images",
                                                              isDirectory: true)
            
            return imagesDirUrl.appendingPathComponent(imageName,
                                                       isDirectory: false)
        } else {
            return nil
        }
    }
    
    var image: UIImage? {
        return imageURL != nil ? UIImage(contentsOfFile: imageURL!.path) : nil
    }
    
    var expense: Expense? {
        get {
            return expense_
        }
        set {
            expense_ = newValue
        }
    }
    
    override func prepareForDeletion() {
        if let imageURL = self.imageURL {
            // Attempt to delete our image.
            do {
                try FileManager.default.removeItem(at: imageURL)
            } catch {
                // We don't *really* care, but log for good measure.
                Logger.warning("The file at at \(imageURL) wasn't able to be deleted.")
            }
        }
    }
}

