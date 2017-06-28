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
import NYTPhotoViewer

class ImageSelectorView: UIScrollView,
UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var _images = [UIImage]()
    private var photoBoxes = [NYTPhotoBox]()
    
    var selectorDelegate: ImageSelectorDelegate?

    let buttonMargin: CGFloat = 10
    
    let deleteButtonRadius: CGFloat = 10
    let offset: CGFloat = 5.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.layer.borderWidth = 1.0
        self.layer.borderColor = self.tintColor.cgColor

        // Add the plus button.
        let addButton = makeButton(index: 0)
        let buttonBgColor = UIColor(colorLiteralRed: 150 / 255,
                                    green: 150 / 255,
                                    blue: 150 / 255,
                                    alpha: 1)
        if let image = imageWithColor(buttonBgColor) {
            addButton.setBackgroundImage(image, for: .highlighted)
        }
        let font = UIFont.systemFont(ofSize: 40, weight: UIFontWeightLight)
        addButton.setTitle("＋", for: .normal)
        addButton.titleLabel?.font = font
        addButton.addTarget(self,
                            action: #selector(selectSourceForNewPhoto(sender:)),
                            for: .touchUpInside)
        addButton.tag = -1
        self.addSubview(addButton)

        recreateButtons()
    }

    func recreateButtons() {
        // Remove all subviews.
        for subview in subviews {
            if subview.tag != -1 {
                subview.removeFromSuperview()
            }
        }

        
        // Add all image buttons.
        for (i, image) in _images.enumerated() {
            let photoButton = makeButton(index: i + 1, type: .custom)
            photoButton.tag = i
            photoButton.addTarget(self, action: #selector(viewPhoto(_:)),
                                  for: .touchUpInside)
            
            photoButton.setImage(image, for: .normal)
            // Make images scale with higher quality anti-aliasing
            photoButton.imageView?.layer.shouldRasterize = true
            photoButton.imageView?.layer.rasterizationScale = 6
            photoButton.imageView?.layer.minificationFilter = kCAFilterTrilinear
            photoButton.imageView?.contentMode = .scaleAspectFill


            let deleteButton = makeButton(index: i + 1)
            deleteButton.tag = _images.count + i
            let frame = deleteButton.frame
            let NECorner = CGPoint(x: frame.origin.x + frame.size.height,
                                   y: frame.origin.y)
            deleteButton.frame = CGRect(x: NECorner.x - deleteButtonRadius - offset,
                                        y: NECorner.y - deleteButtonRadius + offset,
                                        width: deleteButtonRadius * 2,
                                        height: deleteButtonRadius * 2)
            deleteButton.layer.cornerRadius = deleteButtonRadius
            deleteButton.clipsToBounds = true
            deleteButton.backgroundColor = UIColor.white
            let font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightBold)
            deleteButton.titleLabel?.font = font
            deleteButton.setTitle("✕", for: .normal)
            deleteButton.addTarget(self,
                                   action: #selector(deletePhoto(_:)),
                                   for: .touchUpInside)

            self.addSubview(photoButton)
            self.addSubview(deleteButton)
        }
        
        let sideSize: CGFloat = self.frame.size.height
        let contentWidth = ((sideSize - buttonMargin) * CGFloat(_images.count + 1)) +
                           buttonMargin
        self.contentSize = CGSize(width: contentWidth, height: self.frame.size.height)

    }
    
    func selectSourceForNewPhoto(sender: UIButton) {
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
        
        selectorDelegate?.present(actionSheet, animated: true,
                                  completion: nil, sender: self)
    }
    
    func showImagePickerForCamera(_ action: UIAlertAction) {
        // The user wants to take a photo from the camera.
        // Check to make sure they have access, or ask for it.
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
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
            selectorDelegate?.present(alert, animated: true, completion: nil, sender: self)
        case .notDetermined:
            // The user has not yet been presented with the option to grant
            // access to the camera hardware. Ask for it.
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
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
    
    func showImagePickerForPhotoPicker(_ action: UIAlertAction) {
        // The user wants to select a photo from their photo library.
        // The photo library will take care of access control appropriately
        // in this case, so just present it.
        self.showImagePickerForSourceType(.photoLibrary)
    }
    
    func showImagePickerForSourceType(_ sourceType: UIImagePickerControllerSourceType) {
        // Present an image picker for the source type, once we've determined
        // what it is and gotten permissions as necessary.
        let imagePicker = UIImagePickerController()
        imagePicker.modalPresentationStyle = .currentContext
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = (sourceType == .camera) ? .fullScreen : .popover
        selectorDelegate?.present(imagePicker, animated: true, completion: nil, sender: self)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        // The user chose an image. Add the image to our images array and
        // add a NYTPhotoBox with the image so we don't have to create one
        // when the user wants to view the image later.
        let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        let photoBox = NYTPhotoBox(photoId: 0, image: image)
        _images.insert(image, at: 0)
        photoBoxes.forEach { $0.photoId += 1 }
        photoBoxes.insert(photoBox, at: 0)
        recreateButtons()
        selectorDelegate?.addedImage(image)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func viewPhoto(_ sender: UIButton!) {
        // Present the NYTimes photos view controller.
        let photoId = sender.tag

        let vc = NYTPhotosViewController(photos: photoBoxes,
                                         initialPhoto: photoBoxes[photoId],
                                         delegate: self)
        selectorDelegate?.present(vc, animated: true, completion: nil, sender: self)
    }
    
    func deletePhoto(_ sender: UIButton!) {
        // The user tapped the plus button to remove a photo.
        
        // To calculate the index, subtract the number of images from the 
        // delete tag.
        let index = sender.tag - _images.count

        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        let deleteButton = UIAlertAction(title: "Delete",
                                               style: .destructive,
                                               handler:
        { _ in
            let image = self._images.remove(at: index)
            self.photoBoxes.remove(at: 0)
            for (i, box) in self.photoBoxes.enumerated() {
                if i >= index {
                    box.photoId -= 1
                }
            }
            
            self.recreateButtons()
            self.selectorDelegate?.removedImage(image)
        })
        let cancelButton = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler:
        { _ in
            actionSheet.dismiss(animated: true, completion: nil)
        })
        
        actionSheet.addAction(deleteButton)
        actionSheet.addAction(cancelButton)
        
        selectorDelegate?.present(actionSheet, animated: true,
                                  completion: nil, sender: self)
    }

    func makeButton(index: Int, type: UIButtonType = .system) -> UIButton {
        // Create a button at a particular index, properly setting visual
        // attributes and the frame of the button.
        let sideSize: CGFloat = self.frame.height
        let startX: CGFloat = ((sideSize - buttonMargin) * CGFloat(index))
        
        let button = UIButton(type: type)
        let fullsizeFrame = CGRect(x: startX, y: 0,
                                   width: sideSize, height: sideSize)
        button.frame = fullsizeFrame.insetBy(dx: buttonMargin,
                                             dy: buttonMargin)
        button.layer.borderWidth = 1.0
        button.layer.borderColor = self.tintColor.cgColor
        
        return button
    }
    
    func imageWithColor(_ color: UIColor) -> UIImage? {
        // Return a 1x1 px UIImage of a particular color
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

protocol ImageSelectorDelegate: class {
    func addedImage(_ image: UIImage)
    func removedImage(_ image: UIImage)
    func present(_ vc: UIViewController, animated: Bool,
                 completion: (() -> Void)?, sender: Any?)
}


extension ImageSelectorView: NYTPhotosViewControllerDelegate {

    func photosViewController(_ photosViewController: NYTPhotosViewController,
                              handleActionButtonTappedFor photo: NYTPhoto) -> Bool {
        guard let photoImage = photo.image else { return false }

        let activityVC = UIActivityViewController(activityItems: [photoImage],
                                                  applicationActivities: nil)
        
        photosViewController.present(activityVC, animated: true, completion: nil)

        return true
    }

    func photosViewController(_ photosViewController: NYTPhotosViewController,
                              referenceViewFor photo: NYTPhoto) -> UIView? {
        guard let box = photo as? NYTPhotoBox else { return nil }

        let tag = box.photoId
        for view in subviews {
            if view.tag == tag {
                return view
            }
        }
        return nil
    }
}
