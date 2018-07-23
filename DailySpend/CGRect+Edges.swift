//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import Foundation

extension CGRect {
    
    var topEdge: CGFloat {
        return self.origin.y
    }
    
    var leftEdge: CGFloat {
        return self.origin.x
    }
    
    var bottomEdge: CGFloat {
        return self.topEdge + self.size.height
    }
    
    var rightEdge: CGFloat {
        return self.leftEdge + self.size.width
    }

    var topRightCorner: CGPoint {
        return CGPoint(x: rightEdge, y: topEdge)
    }
    
    var topLeftCorner: CGPoint {
        return CGPoint(x: leftEdge, y: topEdge)
    }
    
    var bottomRightCorner: CGPoint {
        return CGPoint(x: rightEdge, y: bottomEdge)
    }
    
    var bottomLeftCorner: CGPoint {
        return CGPoint(x: leftEdge, y: bottomEdge)
    }
    
    func shiftedLeftEdge(by shift: CGFloat) -> CGRect {
        return CGRect(x: origin.x + shift, y: origin.y, width: size.width - shift, height: size.height)
    }
    
    func shiftedRightEdge(by shift: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: origin.y, width: size.width + shift, height: size.height)
    }
    
    func shiftedTopEdge(by shift: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: origin.y + shift, width: size.width, height: size.height - shift)
    }
    
    func shiftedBottomEdge(by shift: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height + shift)
    }
}
