//
//  ImageSelector.swift
//  DailySpend
//
//  Created by Josh Sherick on 6/23/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import QuartzCore
import AVFoundation
import Photos
import INSPhotoGalleryFramework

class ImageSelectorView: UIScrollView,
UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    var selectorDelegate: ImageSelectorDelegate?
    var selectorController: ImageSelectorController?

    let buttonMargin: CGFloat = 10
    
    let deleteButtonRadius: CGFloat = 10
    let offset: CGFloat = 5.0
    
    private var boxes = [PhotoBox]()

    func addImage(image: UIImage, imageName: String, imageType: String?) {
        let box = PhotoBox(photoId: boxes.count,
                           image: image,
                           imageName: imageName,
                           imageType: imageType)
        boxes.append(box)
        recreateButtons()
    }
    
    func getImages() -> [PhotoBox] {
        return boxes
    }
    
    func removeAllImages() {
        boxes.removeAll()
        recreateButtons()
    }
    
    init(optionalCoder: NSCoder? = nil, optionalFrame: CGRect? = nil) {
        if let coder = optionalCoder {
            super.init(coder: coder)!
        } else if let frame = optionalFrame {
            super.init(frame: frame)
        } else {
            super.init()
        }
        
        self.delegate = self
        
        recreateButtons()
    }
    
    required convenience init(coder: NSCoder) {
        self.init(optionalCoder: coder)
    }
    
    override convenience init(frame: CGRect) {
        self.init(optionalFrame: frame)
    }
    
    var contentWidth: CGFloat {
        let sideSize = self.frame.size.height
        let contentWidth = ((sideSize - buttonMargin) *
                                CGFloat(boxes.count + 1)) +
                            buttonMargin
        return max(contentWidth, self.frame.size.width)
    }
    
    func scrollToRightEdge() {
        contentOffset = CGPoint(
            x: contentSize.width - frame.size.width,
            y: 0
        )
    }

    func recreateButtons() {
        print(frame)
        // Remove all subviews.
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        // Add the plus button.
        let addButton = makeButton(index: 0)
        let buttonBgColor = UIColor(red255: 150, green: 150, blue: 150)
        if let image = UIImage.withColor(buttonBgColor) {
            addButton.setBackgroundImage(image, for: .highlighted)
        }
        let font = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.light)
        addButton.setTitle("＋", for: .normal)
        addButton.titleLabel?.font = font
        addButton.addTarget(self,
                            action: #selector(selectSourceForNewPhoto(sender:)),
                            for: .touchUpInside)
        addButton.tag = -1
        self.addSubview(addButton)

        
        // Add all image buttons.
        for (i, box) in boxes.enumerated() {
            let buttonIndex = boxes.count - i
            let photoButton = makeButton(index: buttonIndex, type: .custom)
            photoButton.tag = i
            photoButton.addTarget(self, action: #selector(viewPhoto(_:)),
                                  for: .touchUpInside)
            
            photoButton.setImage(box.image, for: .normal)
            // Make images scale with higher quality anti-aliasing
            photoButton.imageView?.layer.shouldRasterize = true
            photoButton.imageView?.layer.rasterizationScale = 6
            photoButton.imageView?.layer.minificationFilter = kCAFilterTrilinear
            photoButton.imageView?.contentMode = .scaleAspectFill


            let deleteButton = makeButton(index: buttonIndex)
            deleteButton.tag = boxes.count + i
            let frame = deleteButton.frame
            deleteButton.frame = CGRect(x: frame.rightEdge - deleteButtonRadius - offset,
                                        y: frame.topEdge - deleteButtonRadius + offset,
                                        width: deleteButtonRadius * 2,
                                        height: deleteButtonRadius * 2)
            deleteButton.layer.cornerRadius = deleteButtonRadius
            deleteButton.clipsToBounds = true
            deleteButton.backgroundColor = UIColor.white
            let font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.bold)
            deleteButton.titleLabel?.font = font
            deleteButton.setTitle("✕", for: .normal)
            deleteButton.addTarget(self,
                                   action: #selector(deletePhoto(_:)),
                                   for: .touchUpInside)

            self.addSubview(photoButton)
            self.addSubview(deleteButton)
        }
        
        self.contentSize = CGSize(width: contentWidth,
                                  height: self.frame.size.height)
        let rightSide = CGRect(x: contentWidth - self.frame.size.width,
                              y: 0,
                              width: self.frame.size.width,
                              height: self.frame.size.height)
        self.scrollRectToVisible(rightSide, animated: false)

    }
    
    @objc private func selectSourceForNewPhoto(sender: UIButton) {
        selectorController?.interactedWithImageSelectorViewByTapping()
        // The user tapped the plus button to add a new photo.
        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        let photoLibraryButton = UIAlertAction(title: "Choose Photo",
                                               style: .default,
                                               handler: showImagePickerForPhotoPicker)
        let cameraButton = UIAlertAction(title: "Take Photo",
                                         style: .default,
                                         handler: showImagePickerForCamera)
        
        let cancelButton = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: { _ in
            actionSheet.dismiss(animated: true, completion: nil)
        })
        
        actionSheet.addAction(cameraButton)
        actionSheet.addAction(photoLibraryButton)
        actionSheet.addAction(cancelButton)
        
        selectorController?.present(actionSheet, animated: true,
                                  completion: nil, sender: self)
    }
    
    private func showImagePickerForCamera(_ action: UIAlertAction) {
        // The user wants to take a photo from the camera.
        // Check to make sure they have access, or ask for it.
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch status {
        case .denied:
            // The user has previously denied access. Remind the user that we
            // need camera access to be useful.
            let message = "To enable access, go to Settings > Privacy > Camera " +
            "and turn on Camera access for DailySpend."
            let alert = UIAlertController(title: "Unable to access the Camera",
                                          message: message, preferredStyle: .alert)
            let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
            alert.addAction(okay)
            selectorController?.present(alert, animated: true, completion: nil, sender: self)
        case .notDetermined:
            // The user has not yet been presented with the option to grant
            // access to the camera hardware. Ask for it.
            AVCaptureDevice.requestAccess(for: AVMediaType.video,
                                          completionHandler:
                { (granted: Bool) in
                    // If access was denied, we do not set the setup error
                    // message since access was just denied.
                    if granted {
                        // Allowed access to camera, present UIImagePickerController.
                        self.showImagePickerForSourceType(.camera)
                    }
            })
        default:
            // Has previously allowed access to camera, present
            // UIImagePickerController.
            self.showImagePickerForSourceType(.camera)
        }
    }
    
    private func showImagePickerForPhotoPicker(_ action: UIAlertAction) {
        // The user wants to select a photo from their photo library.
        // Check to make sure they have access, or ask for it.
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                self.showImagePickerForSourceType(.photoLibrary)
            case .denied:
                // The user has previously denied access. Remind the user that we
                // need camera access to be useful.
                let message = "To enable access, go to Settings > Privacy > Camera " +
                "and turn on Photo Library access for DailySpend."
                let alert = UIAlertController(title: "Unable to access the Photo Library",
                                              message: message, preferredStyle: .alert)
                let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
                alert.addAction(okay)
                self.selectorController?.present(alert, animated: true, completion: nil, sender: self)
            default:
                break
            }
        }
    }
    
    private func showImagePickerForSourceType(_ sourceType: UIImagePickerControllerSourceType) {
        // Present an image picker for the source type, once we've determined
        // what it is and gotten permissions as necessary.
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePicker = UIImagePickerController()
            imagePicker.modalPresentationStyle = .currentContext
            imagePicker.sourceType = sourceType
            imagePicker.delegate = self
            imagePicker.modalPresentationStyle = (sourceType == .camera) ? .fullScreen : .popover
            selectorController?.present(imagePicker, animated: true, completion: nil, sender: self)
        } else {
            let humanSource = sourceType == .camera ? "camera" : "Photo Library"
            let message = "The \(humanSource) isn't available. Please try a " +
                            "different type."
            let title = "Unable to access \(humanSource)"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
            alert.addAction(okay)
            selectorController?.present(alert, animated: true, completion: nil, sender: self)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        // The user chose an image. Add the image to our boxes array and
        // add a PhotoBox with the image so we don't have to create one
        // when the user wants to view the image later.
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        var imageType = "jpeg"
        if let url = info[UIImagePickerControllerReferenceURL] as? NSURL {
            if let lastComponent = url.lastPathComponent {
                if lastComponent.contains("PNG") {
                    imageType = "png"
                }
            }
        }
        
        // Come up with a name for the photo.
        var photoNum = UserDefaults.standard.integer(forKey: "photoNumber")
        let imageName = "DailySpend" + String(photoNum) + "." + imageType
        photoNum += 1
        UserDefaults.standard.set(photoNum, forKey: "photoNumber")
        
        self.addImage(image: image, imageName: imageName, imageType: imageType)
        selectorDelegate?.addedImage(image, imageName: imageName, imageType: imageType)
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc private func viewPhoto(_ sender: UIButton!) {
        selectorController?.interactedWithImageSelectorViewByTapping()
        // Present the NYTimes photos view controller.
        let photoId = sender.tag
        let box = boxes[photoId]
        
        func referenceViewForPhoto(_ photo: INSPhotoViewable) -> UIView? {
            guard let box = photo as? PhotoBox else { return nil }
            
            let tag = box.photoId
            for view in subviews {
                if view.tag == tag {
                    return view
                }
            }
            return nil
        }

        let vc = INSPhotosViewController(photos: boxes, initialPhoto: box, referenceView: referenceViewForPhoto(box))
        vc.referenceViewForPhotoWhenDismissingHandler = referenceViewForPhoto(_:)
        selectorController?.present(vc, animated: true, completion: nil, sender: self)
    }
    
    @objc private func deletePhoto(_ sender: UIButton!) {
        // The user tapped the plus button to remove a photo.
        selectorController?.interactedWithImageSelectorViewByTapping()
        
        // To calculate the index, subtract the number of boxes from the
        // delete tag.
        let index = sender.tag - boxes.count

        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        let deleteButton = UIAlertAction(title: "Remove Photo",
                                               style: .destructive) { _ in
            let removedBox = self.boxes.remove(at: index)
            for (i, box) in self.boxes.enumerated() {
                if i >= index {
                    box.photoId -= 1
                }
            }
            
            self.recreateButtons()
            self.selectorDelegate?.removedImage(index: removedBox.photoId)
        }
        let cancelButton = UIAlertAction(title: "Cancel",
                                         style: .cancel) { _ in
            actionSheet.dismiss(animated: true, completion: nil)
        }
        
        actionSheet.addAction(deleteButton)
        actionSheet.addAction(cancelButton)
        
        selectorController?.present(actionSheet, animated: true,
                                  completion: nil, sender: self)
    }

    private func makeButton(index: Int, type: UIButtonType = .system) -> UIButton {
        // Create a button at a particular index, properly setting visual
        // attributes and the frame of the button.
        let sideSize: CGFloat = self.frame.height
        let startXFromEnd: CGFloat = ((sideSize - buttonMargin) * CGFloat(index)) + sideSize - buttonMargin
        
        let startX = contentWidth - startXFromEnd
        
        let button = UIButton(type: type)
        let fullsizeFrame = CGRect(x: startX, y: 0,
                                   width: sideSize, height: sideSize)
        button.frame = fullsizeFrame.insetBy(dx: buttonMargin,
                                             dy: buttonMargin)
        button.layer.borderWidth = 1.0
        button.layer.borderColor = self.tintColor.cgColor
        
        return button
    }
}

protocol ImageSelectorController: class {
    /**
     * Called to present a view controller.
     */
    func present(_ vc: UIViewController, animated: Bool,
                 completion: (() -> Void)?, sender: Any?)
    /**
     * Called when the user interacts with the ImageSelectorView by tapping.
     */
    func interactedWithImageSelectorViewByTapping()
}

protocol ImageSelectorDelegate: class {
    /**
     * Called when an image has been successfully added to the image view.
     */
    func addedImage(_ image: UIImage, imageName: String, imageType: String?)

    /**
     * Called when an image has been removed from the image view.
     */
    func removedImage(index: Int)
}
