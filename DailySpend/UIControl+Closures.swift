//
//  Date+Convenience.swift
//  DailySpend
//
//  Created by Josh Sherick on 3/16/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//
//  From https://stackoverflow.com/questions/25919472/adding-a-closure-as-target-to-a-uibutton

import UIKit

class ClosureSleeve {
    let closure: ()->()
    
    init (_ closure: @escaping ()->()) {
        self.closure = closure
    }
    
    @objc func invoke () {
        closure()
    }
}

extension UIControl {
    func add (for controlEvents: UIControlEvents, _ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

extension UIBarButtonItem {
    convenience init(title: String?, style: UIBarButtonItemStyle, _ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        self.init(title: title, style: style, target: sleeve, action: #selector(ClosureSleeve.invoke))
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    convenience init(barButtonSystemItem: UIBarButtonSystemItem, _ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        self.init(barButtonSystemItem: barButtonSystemItem, target: sleeve, action: #selector(ClosureSleeve.invoke))
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
