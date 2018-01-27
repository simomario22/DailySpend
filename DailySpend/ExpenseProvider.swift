//
//  ExpenseProvider.swift
//  DailySpend
//
//  Created by Josh Sherick on 6/29/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import CoreData

protocol ExpenseViewDataSource: class {
    var calDay: CalendarDay! { get set }
    var amount: Decimal? { get set }
    var shortDescription: String? { get set }
    var notes: String? { get set }
    var imageContainers: [ImageContainer]? { get }
    
    func setDayToToday()
    func addImage(container: ImageContainer)
    func removeImage(index: Int)
    func save() -> Expense?
}

struct ImageContainer {
    var image: UIImage
    var imageName: String
    var imageType: String?
    var saved: Bool = false
}

class ExpenseProvider: NSObject, ExpenseViewDataSource {
    
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    // The actual Expense
    private var expense: Expense?
    
    // Attributes of the expense that we can change
    // The date of the Day that the expense should be associated with
    var calDay: CalendarDay!
    var amount: Decimal?
    var shortDescription: String?
    var notes: String?
    var imageContainers: [ImageContainer]?
    private var imagesToRemove = [ImageContainer]()
    
    override init() {
        super.init()
    }
    
    init?(expense: Expense? = nil) {
        if let expense = expense {
            guard let amount = expense.amount,
                  let shortDescription = expense.shortDescription,
                  let calDay = expense.day!.calendarDay else {
                return nil
            }
            
            self.amount = amount
            self.shortDescription = shortDescription
            self.calDay = calDay
            
            self.notes = expense.notes
            
            if let sortedImages = expense.sortedImages {
                // Add all images to image selector.
                self.imageContainers = sortedImages.map({ image in
                    return ImageContainer(image: image.image!,
                                          imageName: image.imageName!,
                                          imageType: nil,
                                          saved: true)
                })
            }
            self.expense = expense
        } else {
            self.calDay = CalendarDay()
            self.amount = nil
            self.shortDescription = nil
            self.notes = nil
            self.imageContainers = [ImageContainer]()
        }
    }
    
    func addImage(container: ImageContainer) {
        imageContainers?.append(container)
    }
    
    func removeImage(index: Int) {
        // Remove from images array and add to imagesToRemove.
        let container = imageContainers!.remove(at: index)
        imagesToRemove.append(container)
    }
    
    func save() -> Expense? {
        // Create a new expense with our managed object context if one doesn't
        // already exist.
        if self.expense == nil {
            self.expense = Expense(context: context)
            expense!.dateCreated = Date()
        }
        
        // All of these things must exist at this point
        guard let expense = self.expense,
            let amount = self.amount,
            let shortDescription = self.shortDescription,
            let calDay = self.calDay else {
                return nil
        }
        
        // Delete any images that the user has deleted.
        removeImages()
        
        // Create new Days if we need to.
        let earliestDay = earliestDayCreated()
        if calDay < earliestDay {
            // Create from the selectedDate to the earliest day available.
            _ = Day.createDays(context: context, from: calDay, to: earliestDay)
            appDelegate.saveContext()
        }
        
        // Set all the properties on expense.
        if let day = Day.get(context: context, calDay: calDay) {
            expense.day = day
        } else {
            return nil
        }
        expense.amount = amount
        expense.shortDescription = shortDescription
        expense.notes = self.notes
        
        // Remove all images from expense image set.
        expense.images = Set<Image>()
        
        for container in self.imageContainers! {
            var imageName = container.imageName
            if !container.saved {
                if let name = saveImage(container: container) {
                    imageName = name
                } else {
                    // There was an error saving.
                    return nil
                }
            }
            let image = Image(context: context)
            image.expense = expense
            image.dateCreated = Date()
            image.imageName = imageName
        }
        
        appDelegate.saveContext()

        return expense
    }
    
    func earliestDayCreated() -> CalendarDay {
        // Find the earliest day that has already been created.
        let earliestDaySD = NSSortDescriptor(key: "date_", ascending: true)
        let earliestDays = Day.get(context: context,
                                   sortDescriptors: [earliestDaySD],
                                   fetchLimit: 1)!
        return earliestDays.first!.calendarDay!
    }
    
    func saveImage(container: ImageContainer) -> String? {
        makeImagesDirectory()
        var imageName = container.imageName
        let fm = FileManager.default
        let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        let imagesDirUrl = urls[0].appendingPathComponent("images",
                                                          isDirectory: true)
        var imageUrl = imagesDirUrl.appendingPathComponent(container.imageName)
        
        // Find a name that hasn't been taken.
        var num = 0
        while fm.fileExists(atPath: imageUrl.path) {
            let ext = container.imageType
            var components = container.imageName.components(separatedBy: ".")
            _ = components.popLast()
            let nameWithoutExtension = components.joined(separator: ".")
            imageName = nameWithoutExtension + String(num) + "." + ext!
            
            // Delete last path component and re-add it with a number.
            imageUrl.deleteLastPathComponent()
            imageUrl.appendPathComponent(imageName)
            
            num += 1
        }
        
        func compress(image: UIImage, with format: String) -> Data? {
            if format == "png" {
                return UIImagePNGRepresentation(image)
            } else {
                return UIImageJPEGRepresentation(image, 0.85)
            }
        }
        
        // Write the image to disk.
        if let data = compress(image: container.image, with: container.imageType!) {
            do {
                try data.write(to: imageUrl)
            } catch {
                return nil
            }
        }
        return imageName
    }
    
    func removeImages() {
        for container in imagesToRemove {
            if !container.saved {
                continue
            }
            
            for image in expense!.images! {
                if image.imageName == container.imageName {
                    context.delete(image)
                }
            }
        }
    }
    
    func setDayToToday() {
        self.calDay = CalendarDay()
    }

    func makeImagesDirectory() {
        let fm = FileManager.default
        let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        let imagesDirUrl = urls[0].appendingPathComponent("images",
                                                          isDirectory: true)
        if !fm.fileExists(atPath: imagesDirUrl.path) {
                try! fm.createDirectory(at: imagesDirUrl,
                               withIntermediateDirectories: false,
                               attributes: nil)
        }
    }

}
