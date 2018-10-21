//
//  ReverseAnimator.swift
//  DailySpend
//
//  Created by Josh Sherick on 10/21/18.
//  Copyright © 2018 Josh Sherick. All rights reserved.
//
//  Derived from Sam Miller's article and example:
//      https://www.hedgehoglab.com/blog/ios-transition-animations
//  Created by Sam Miller on 08/02/2017.
//  Copyright © 2017 B&M. All rights reserved.

import UIKit


class ReverseAnimator: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    var forward = true
    let duration = 0.25
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        var originView: UIView!
        var animatedView: UIView!
        
        if forward {
            animatedView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
            originView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        } else {
            animatedView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
            originView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        }
        containerView.addSubview(originView)
        containerView.addSubview(animatedView)
        
        let translationX = originView.frame.size.width
        let transform = CGAffineTransform(translationX: translationX, y: 0)
        let originFrame = originView.frame
        let transformedFrame = originFrame.applying(transform)
        
        let fromFrame = forward ? originFrame : transformedFrame
        let toFrame = forward ? transformedFrame : originFrame
        
        animatedView.frame = fromFrame
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                animatedView.frame = toFrame
            },
            completion: { (flag) in
                transitionContext.completeTransition(flag)
            }
        )
    }
}
