//
//  ImageSelector.swift
//  DailySpend
//
//  Created by Josh Sherick on 6/23/17.
//  Copyright © 2017 Josh Sherick. All rights reserved.
//

import UIKit
import QuartzCore

class ImageSelectorView: UIScrollView {
    private var _images = [UIImage]()
    
    var selectorDelegate: ImageSelectorDelegate?

    let buttonMargin: CGFloat = 2.5
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let addButton = makeButton(index: 0)
        let font = UIFont.systemFont(ofSize: 40, weight: UIFontWeightLight)
        addButton.setTitle("＋", for: .normal)
        addButton.titleLabel?.font = font
        addButton.addTarget(self, action: #selector(addImage(sender:)),
                                  for: .touchUpInside)
        self.addSubview(addButton)
        
        self.layer.borderWidth = 1.0
        self.layer.borderColor = self.tintColor.cgColor
    }
    
    func addImage(sender: UIButton) {
        print("Add image!")
    }
    
    func makeButton(index: Int) -> UIButton {
        let sideSize: CGFloat = self.frame.height
        let startX: CGFloat = sideSize * CGFloat(index)
        
        let button = UIButton(type: .system)
        let fullsizeFrame = CGRect(x: startX, y: 0, width: sideSize, height: sideSize)
        button.frame = fullsizeFrame.insetBy(dx: buttonMargin * 2,
                                                dy: buttonMargin * 2)
        button.layer.borderWidth = 1.0
        button.layer.borderColor = self.tintColor.cgColor
        
        return button
    }
}

protocol ImageSelectorDelegate: class {
    func selectedNewImage(_ image: UIImage)
    func removedImage(_ image: UIImage)
    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)?, sender: Any?)
}
