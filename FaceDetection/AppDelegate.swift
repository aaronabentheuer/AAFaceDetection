//
//  AppDelegate.swift
//  FaceDetection
//
//  Created by Julian Abentheuer on 21.12.14.
//  Copyright (c) 2014 Aaron Abentheuer. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var activeCornerRadius : CGFloat = 0
    var incativeCornerRadius : CGFloat = 0
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window!.clipsToBounds = true
        
        var animation : CABasicAnimation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.fromValue = activeCornerRadius
        animation.toValue = activeCornerRadius
        animation.duration = 0.15
        window!.layer.cornerRadius = activeCornerRadius
        window!.layer.addAnimation(animation, forKey: "cornerRadius")
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        var animation : CABasicAnimation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.fromValue = activeCornerRadius
        animation.toValue = incativeCornerRadius
        animation.duration = 0.15
        window!.layer.cornerRadius = incativeCornerRadius
        window!.layer.addAnimation(animation, forKey: "cornerRadius")
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        var animation : CABasicAnimation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.fromValue = incativeCornerRadius
        animation.toValue = activeCornerRadius
        animation.duration = 0.15
        window!.layer.cornerRadius = activeCornerRadius
        window!.layer.addAnimation(animation, forKey: "cornerRadius")
    }
}

