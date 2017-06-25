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

    let buttonMargin: CGFloat = 2.5
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.layer.borderWidth = 1.0
        self.layer.borderColor = self.tintColor.cgColor

        recreateButtons()
    }

    func recreateButtons() {
        // Remove all subviews.
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
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
        addButton.addTarget(self, action: #selector(selectSourceForNewPhoto(sender:)),
                            for: .touchUpInside)
        addButton.tag = -1
        self.addSubview(addButton)
        
        // Add all image buttons.
        for (i, image) in _images.enumerated() {
            let photoButton = makeButton(index: i + 1, type: .custom)
            photoButton.tag = i
            photoButton.addTarget(self, action: #selector(viewPhoto(_:)),
                                  for: .touchUpInside)
            
            photoButton.setImage(image, for: .normal)
            photoButton.imageView?.layer.shouldRasterize = true
            photoButton.imageView?.layer.rasterizationScale = 6
            photoButton.imageView?.layer.minificationFilter = kCAFilterTrilinear
            photoButton.imageView?.contentMode = .scaleAspectFill
            self.addSubview(photoButton)
        }
        
        let sideSize: CGFloat = self.frame.size.height
        let contentWidth = (2 * buttonMargin) + (sideSize * CGFloat(1 + _images.count))
        self.contentSize = CGSize(width: contentWidth, height: self.frame.size.height)

    }
    
    func selectSourceForNewPhoto(sender: UIButton) {
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
            showImagePickerForSourceType(.camera)
        }
    }
    
    func showImagePickerForPhotoPicker(_ action: UIAlertAction) {
        self.showImagePickerForSourceType(.photoLibrary)
    }
    
    func showImagePickerForSourceType(_ sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.modalPresentationStyle = .currentContext
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = (sourceType == .camera) ? .fullScreen : .popover
        selectorDelegate?.present(imagePicker, animated: true, completion: nil, sender: self)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        let photoBox = NYTPhotoBox(photoId: 0, image: image)
        _images.insert(image, at: 0)
        photoBoxes.forEach { $0.photoId += 1 }
        photoBoxes.insert(photoBox, at: 0)
        recreateButtons()
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    func viewPhoto(_ sender: UIButton!) {
        let photoId = sender.tag

        let vc = NYTPhotosViewController(photos: photoBoxes,
                                         initialPhoto: photoBoxes[photoId],
                                         delegate: self)
        selectorDelegate?.present(vc, animated: true, completion: nil, sender: self)
    }

    func makeButton(index: Int, type: UIButtonType = .system) -> UIButton {
        let sideSize: CGFloat = self.frame.height
        let startX: CGFloat = buttonMargin + (sideSize * CGFloat(index))
        
        let button = UIButton(type: type)
        let fullsizeFrame = CGRect(x: startX, y: 0, width: sideSize, height: sideSize)
        button.frame = fullsizeFrame.insetBy(dx: buttonMargin * 2,
                                             dy: buttonMargin * 2)
        button.layer.borderWidth = 1.0
        button.layer.borderColor = self.tintColor.cgColor
        
        return button
    }
    
    func imageWithColor(_ color: UIColor) -> UIImage? {
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
    func selectedNewImage(_ image: UIImage)
    func removedImage(_ image: UIImage)
    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?, sender: Any?)
}


extension ImageSelectorView: NYTPhotosViewControllerDelegate {

    func photosViewController(_ photosViewController: NYTPhotosViewController, handleActionButtonTappedFor photo: NYTPhoto) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad, let photoImage = photo.image else {
            return false
        }

        let shareActivityViewController = UIActivityViewController(activityItems: [photoImage], applicationActivities: nil)
        shareActivityViewController.completionWithItemsHandler = {(activityType: UIActivityType?, completed: Bool, items: [Any]?, error: Error?) in
            if completed {
                photosViewController.delegate?.photosViewController!(photosViewController, actionCompletedWithActivityType: activityType?.rawValue)
            }
        }

        shareActivityViewController.popoverPresentationController?.barButtonItem = photosViewController.rightBarButtonItem
        photosViewController.present(shareActivityViewController, animated: true, completion: nil)

        return true
    }

    func photosViewController(_ photosViewController: NYTPhotosViewController, referenceViewFor photo: NYTPhoto) -> UIView? {
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
