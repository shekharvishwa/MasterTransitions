//
//  MTTransitionAnimator.swift
//  Pods
//
//  Created by Frgallah on 4/11/17.
//
//  Copyright (c) 2017 Mohammed Frgallah. All rights reserved.
//
//  Licensed under the MIT license, can be found at:  https://github.com/Frgallah/MasterTransitions/blob/master/LICENSE  or  https://opensource.org/licenses/MIT
//

//  For last updated version of this code check the github page at https://github.com/Frgallah/MasterTransitions
//
//

import UIKit


enum MTTransitionCategory: Int {
    
    case View
    case Layer
    case CoreImage
    case SceneKit
    
}


enum MTTransitionType: Int {
    
    case Push2  //0
    case Pull1 //1
    case SwingDoor //2
    case Door2 //3
    case Door3 //4
    case Door4 //5
    case Door5 //6
    case Folder1 //7
    case Book1 //8
    case Cube1 //9
    case Cube2 //10
    case Cube3 //11
    case Blinds1 //12
    case Blinds2 //13
    case Puzzle1 //14
    case Max
}

enum MTTransitionSubType: Int {
    
    case RightToLeft
    case LeftToRight
    case BottomToTop
    case TopToBottom
    case Horizontal
    case Vertical
    case HorizontalOpposite
    case VerticalOpposite
    case Max
    
}


class MTTransitionAnimator: NSObject {
    
    var propertyAnimator: UIViewPropertyAnimator?
    var isInteractive: Bool = false
    var duration: TimeInterval = 0
    var midDuration: CGFloat = 0.5
    var transitionCategory: MTTransitionCategory = .View
    fileprivate(set) var defaultDuration = 1.0;
    lazy var effectView: UIVisualEffectView = UIVisualEffectView.init(effect: UIBlurEffect.init(style: UIBlurEffectStyle.light))
    
    var transitionCompletion: ((Bool) -> ())?
    
    var transitionUpdated: (() -> ())?
    
    
    var fractionComplete: CGFloat {
        get {
            return (propertyAnimator?.fractionComplete)!
        }
        set(newFractionComplete) {
            propertyAnimator?.fractionComplete = newFractionComplete
        }
    }
    
    var transitionSubType: MTTransitionSubType
    
    init(transitionSubType: MTTransitionSubType) {
        self.transitionSubType = transitionSubType
        super.init()
        
    }
    
    func setupTranisition(transitionContext: UIViewControllerContextTransitioning, transitionCompletion: @escaping (Bool) -> ()) {
        
        self.transitionCompletion = transitionCompletion
        let fromViewController = transitionContext.viewController(forKey: .from)
        let toViewController = transitionContext.viewController(forKey: .to)
        let containerView = transitionContext.containerView
        var fromView: UIView!
        var toView: UIView!
        
        if transitionContext.responds(to:#selector(transitionContext.view(forKey:))) {
            fromView = transitionContext.view(forKey: .from)
            toView = transitionContext.view(forKey: .to)
        } else {
            fromView = fromViewController?.view
            toView = toViewController?.view
        }
        
        let fromViewFrame = transitionContext.initialFrame(for: fromViewController!)
        let toViewFrame = transitionContext.finalFrame(for: toViewController!)
        
        setupTranisition(containerView: containerView, fromView: fromView, toView: toView, fromViewFrame: fromViewFrame, toViewFrame: toViewFrame)
        
    }
    
    func setupTranisition(containerView: UIView, fromView: UIView, toView: UIView, fromViewFrame:CGRect, toViewFrame:CGRect) {
        
    }
    
    func animateTo(position: UIViewAnimatingPosition, isResume: Bool) {
        
        guard let animator = propertyAnimator else { return }
        animator.isReversed = position == .start
        if animator.state == .inactive {
            
            animator.startAnimation()
            
        } else {
            
            animator.continueAnimation(withTimingParameters: nil, durationFactor: (animator.fractionComplete))
        }
        
    }
    
}

class MTViewTransitionAnimator: MTTransitionAnimator {
    
    override init(transitionSubType: MTTransitionSubType) {
        super.init(transitionSubType: transitionSubType)
        self.transitionCategory = .View
        
    }
    
}


class MTLayerTransitionAnimator: MTTransitionAnimator {
    
    private var isReversed: Bool = false
    private var fraction: CGFloat = 0
    var secondView: UIView?
    
    override var fractionComplete: CGFloat {
        get {
            return (propertyAnimator?.fractionComplete)!
        }
        set(newFractionComplete) {
            
            propertyAnimator?.fractionComplete = newFractionComplete
            fraction = newFractionComplete
        }
    }
    
    override init(transitionSubType: MTTransitionSubType) {
        super.init(transitionSubType: transitionSubType)
        self.transitionCategory = .Layer
        
    }
    
    override func setupTranisition(containerView: UIView, fromView: UIView, toView: UIView, fromViewFrame:CGRect, toViewFrame:CGRect) {
        
        var fromViewSnapshot: UIImage?
        var toViewSnapshot: UIImage?
        fromView.frame = fromViewFrame
        toView.frame = toViewFrame
        containerView.addSubview(toView)
        UIGraphicsBeginImageContextWithOptions(fromView.bounds.size, true, (containerView.window?.screen.scale)!)
        fromView.drawHierarchy(in: fromView.bounds, afterScreenUpdates: false)
        fromViewSnapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        DispatchQueue.main.async {
            UIGraphicsBeginImageContextWithOptions(toView.bounds.size, true, (containerView.window?.screen.scale)!)
            toView.drawHierarchy(in: toView.bounds, afterScreenUpdates: false)
            toViewSnapshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        effectView.frame = containerView.frame
        containerView.addSubview(effectView)
        let transitionContainer = UIView.init(frame: effectView.bounds)
        effectView.contentView.addSubview(transitionContainer)
        var t = CATransform3DIdentity
        t.m34 = -1.0/(transitionContainer.bounds.size.height * 2.0)
        transitionContainer.layer.transform = t
        
        let fromContentLayer = CALayer()
        fromContentLayer.frame = fromViewFrame
        fromContentLayer.rasterizationScale = (fromViewSnapshot?.scale)!
        fromContentLayer.masksToBounds = true
        fromContentLayer.isDoubleSided = false
        fromContentLayer.contents = fromViewSnapshot?.cgImage
        
        let toContentLayer = CALayer()
        toContentLayer.frame = fromViewFrame
        DispatchQueue.main.async {
            let wereActiondDisabled = CATransaction.disableActions()
            CATransaction.setDisableActions(true)
            toContentLayer.rasterizationScale = (toViewSnapshot?.scale)!
            toContentLayer.masksToBounds = true
            toContentLayer.isDoubleSided = false
            toContentLayer.contents = toViewSnapshot?.cgImage
            CATransaction.setDisableActions(wereActiondDisabled)
            
        }
        secondView = toView
        setupTranisition(mainLayer: transitionContainer.layer, fromLayer: fromContentLayer, toLayer: toContentLayer, fromLayerFrame: fromViewFrame, toLayerFrame: toViewFrame)
        
    }
    
    func setupTranisition(mainLayer:CALayer, fromLayer:CALayer, toLayer:CALayer, fromLayerFrame:CGRect, toLayerFrame:CGRect) {
        //
    }
    
    override func animateTo(position: UIViewAnimatingPosition, isResume: Bool) {
        
        if let animator = propertyAnimator {
            animator.isReversed = position == .start
            if animator.state == .inactive {
                
                animator.startAnimation()
                
            } else {
                
                animator.continueAnimation(withTimingParameters: nil, durationFactor: (animator.fractionComplete))
            }
            
            
        }
    }
    
}


class MTInterruptibleTransitionAnimator: MTTransitionAnimator {
    
    func startAnimation() {
        
    }
    
    func startAnimation(afterDelay delay: TimeInterval) {
        
    }
    
    func startInteractiveAnimation() {
        
    }
    
    func pauseAnimation() {
        
    }
    
    func updateAnimationTime() {
        
    }
    
}


