//
//  UIImage+Color.swift
//  DailySpend
//
//  Created by Josh Sherick on 5/6/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//

import Foundation


extension UIImage {
    class func withColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        // Return a 1x1 px UIImage of a particular color
        let rect = CGRect(origin: CGPoint(), size: size)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
