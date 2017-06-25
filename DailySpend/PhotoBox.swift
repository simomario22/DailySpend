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
final class NYTPhotoBox: NSObject, NYTPhoto {

    var photoId: Int

    override init() {
        photoId = 0
        super.init()
    }

    init(photoId: Int) {
        self.photoId = photoId
        super.init()
    }

    init(photoId: Int, image: UIImage) {
        self.photoId = photoId
        self.image = image
        super.init()
    }

    var image: UIImage?

    // We don't use these but they are required.
    var imageData: Data?
    var placeholderImage: UIImage?
    var attributedCaptionTitle: NSAttributedString?
    var attributedCaptionSummary: NSAttributedString?
    var attributedCaptionCredit: NSAttributedString?
}

extension NYTPhotoBox {
    @objc
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherPhoto = object as? NYTPhotoBox else { return false }
        return photoId == otherPhoto.photoId
    }
}
