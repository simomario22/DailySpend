//
//  ImageSelectorDataSource.swift
//  DailySpend
//
//  Created by Josh Sherick on 7/27/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation
import CoreData

class ImageSelectorDataSource {
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)

    private struct ImageContainer {
        var image: UIImage
        var imageName: String
        var imageType: String?
        var saved: Bool = false
    }

    private var containers: [ImageContainer]
    private var imagesToRemove = [ImageContainer]()
    
    lazy var fileManager: FileManager = {
        return FileManager.default
    }()
    
    lazy var imagesDirectoryURL: URL = {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("images", isDirectory: true)
    }()
    
    private func imageURL(name: String) -> URL {
        return imagesDirectoryURL.appendingPathComponent(name)
    }
    
    init(expense: Expense?) {
        self.containers = [ImageContainer]()
        for image in expense?.sortedImages ?? [] {
            guard let imageData = image.image,
                  let imageName = image.imageName else {
                continue
            }
            let container = ImageContainer(
                image: imageData,
                imageName: imageName,
                imageType: nil,
                saved: true
            )
            self.containers.append(container)
        }
    }
    
    
    /**
     * Provides data about the current images via a callback.
     *
     * - Parameters:
     *     - callback: A function accepting parameters containing the
                       image, image name, and optional image type.
     *     - image: The name of an image currently staged to be
                     associated with the expense.
     *     - imageName: The name of the image, not necessarily unique
                        from other images, nor necessarily the name after
                        saving.
     *     - imageType: The type of the image, if available.
     */
    func provide(to callback: (_ image: UIImage, _ imageName: String, _ imageType: String?) -> ()) {
        for container in containers {
            callback(container.image, container.imageName, container.imageType)
        }
    }

    /**
     * Commits staged images associated with an expense, saving or deleting
     * them as appropriate. If there is an error deleting an image, it will
     * be logged, but this function will still succeed.
     *
     * This function does not call context.save, that is the job of the caller.
     *
     * - Parameters:
     *     - expense: The expense on which to save the staged images.
     *
     * - Returns: A boolean value indicating whether the commit operation
     *            succeeded
     */
    func saveImages(expense: Expense, context: NSManagedObjectContext) -> Bool {
        // Delete any images that the user has deleted.
        removeImages(expense: expense, context: context)
        
        // Remove all images from expense image set.
        expense.images = Set<Image>()
        
        for container in self.containers {
            var imageName = container.imageName
            if !container.saved {
                if let name = saveImage(container: container) {
                    imageName = name
                } else {
                    // There was an error saving.
                    return false
                }
            }

            let image = Image(context: context)
            image.expense = expense
            image.dateCreated = Date()
            image.imageName = imageName
        }
        return true
    }
    
    private func saveImage(container: ImageContainer) -> String? {
        makeImagesDirectory()
        var imageName = container.imageName
        var imageUrl = imageURL(name: imageName)
        
        // Find a name that hasn't been taken.
        var num = 0
        while fileManager.fileExists(atPath: imageUrl.path) {
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
                return image.pngData()
            } else {
                return image.jpegData(compressionQuality: 0.85)
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
    
    private func removeImages(expense: Expense, context: NSManagedObjectContext) {
        for container in imagesToRemove {
            if !container.saved {
                continue
            }
            for image in expense.images! {
                if image.imageName == container.imageName {
                    let imageURL = self.imageURL(name: image.imageName!)
                    do {
                        try fileManager.removeItem(at: imageURL)
                    } catch {
                        Logger.warning("Could not delete image at \(imageURL.path).")
                        break
                    }

                    let image = context.object(with: image.objectID)
                    context.delete(image)
                }
            }
        }
    }
    
    private func makeImagesDirectory() {
        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            try! fileManager.createDirectory(
                at: imagesDirectoryURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        }
    }
}

extension ImageSelectorDataSource : ImageSelectorDelegate {
    /**
     * Implements `ImageSelectorDelegate`.
     */
    func addedImage(_ image: UIImage, imageName: String, imageType: String?) {
        let container = ImageContainer(image: image, imageName: imageName,
                                       imageType: imageType, saved: false)
        containers.append(container)
    }
    
    /**
     * Implements `ImageSelectorDelegate`.
     */
    func removedImage(index: Int) {
        // Remove from images array and add to imagesToRemove.
        let container = containers.remove(at: index)
        imagesToRemove.append(container)
    }
}
