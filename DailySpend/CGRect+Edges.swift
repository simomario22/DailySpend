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
}
