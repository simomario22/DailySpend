//
//  PhotoBox.swift
//  NYTPhotoViewer
//
//  Created by Chris Dzombak on 2/2/17.
//  Copyright © 2017 NYTimes. All rights reserved.
//

import UIKit
import NYTPhotoViewer

/// A box allowing NYTPhotoViewer to consume Swift value types from our codebase.
final class PhotoBox: NSObject, NYTPhoto {

    var photoId: Int
    var imageName: String?
    var imageType: String?
    var dateCreated: Date?

    override init() {
        photoId = 0
        self.dateCreated = Date()
        super.init()
    }

    init(photoId: Int) {
        self.photoId = photoId
        self.dateCreated = Date()
        super.init()
    }

    init(photoId: Int, image: UIImage) {
        self.photoId = photoId
        self.image = image
        self.dateCreated = Date()
        super.init()
    }
    
    init(photoId: Int, image: UIImage, imageName: String?) {
        self.photoId = photoId
        self.image = image
        self.imageName = imageName
        self.dateCreated = Date()
        super.init()
    }
    
    
    init(photoId: Int, image: UIImage, imageName: String?, imageType: String?) {
        self.photoId = photoId
        self.image = image
        self.imageName = imageName
        self.imageType = imageType
        self.dateCreated = Date()
        super.init()
    }

    var image: UIImage?

    // We don't use these but they are required by NYTPhotoViewer.
    var imageData: Data?
    var placeholderImage: UIImage?
    var attributedCaptionTitle: NSAttributedString?
    var attributedCaptionSummary: NSAttributedString?
    var attributedCaptionCredit: NSAttributedString?
}

extension PhotoBox {
    @objc
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherPhoto = object as? PhotoBox else { return false }
        return photoId == otherPhoto.photoId
    }
}
