//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/26.
//

import UIKit

extension NSObject {
    
    public struct App {
        
        private let app: UIApplication = .shared
        
        @available(iOS 13.0, *)
        private var windowScene: UIWindowScene? {
            let scenes: Set<UIScene> = app.connectedScenes
            return scenes.compactMap { $0 as? UIWindowScene }.first
        }
    }
    
    public var app: App { .init() }
    public static var app: App { .init() }
}

extension NSObject.App {
    
    public var screen: UIScreen? {
        if #available(iOS 13, *) {
            return windowScene?.screen
        } else {
            return .main
        }
    }
    
    public var keyWindow: UIWindow? {
        if #available(iOS 13, *) {
            
            if #available(iOS 15, *) {
                return windowScene?.keyWindow
            } else {
                return app.windows.filter({ $0.isKeyWindow }).first
            }
            
        } else {
            return app.keyWindow
        }
    }
    
    public var orienation: UIInterfaceOrientation {
        if #available(iOS 13, *) {
            return windowScene?.interfaceOrientation ?? .unknown
        } else {
            return app.statusBarOrientation
        }
    }
    
    public var statusBarFrame: CGRect {
        if #available(iOS 13, *) {
            return windowScene?.statusBarManager?.statusBarFrame ?? .zero
        } else {
            return app.statusBarFrame
        }
    }
    
    public var currentViewController: UIViewController? {
        guard let rootVC = keyWindow?.rootViewController else { return nil }
        var current: UIViewController? = rootVC
        while current != nil {
            current = current?.presentedViewController;
        }
        if let nav = current as? UINavigationController {
            return nav.topViewController ?? nav
        }
        if let tab = current as? UITabBarController {
            return tab.selectedViewController ?? tab
        }
        return current
    }
    
    public func rotate(to orientation: UIInterfaceOrientation) {
        if #available(iOS 16, *) {
            
            guard let currentVC = currentViewController,
                  let windowScene = windowScene else { return }
            
            currentVC.setNeedsUpdateOfSupportedInterfaceOrientations()
            
            let dict: [UIInterfaceOrientation: UIInterfaceOrientationMask] = [
                .portrait : .portrait,
                .landscapeLeft : .landscapeLeft,
                .landscapeRight : .landscapeRight
            ]
            
            windowScene.requestGeometryUpdate(.iOS.init(interfaceOrientations: dict[orientation] ?? .all)) { error in
                print("rotate to \(orientation) error = \(error)")
            }
            
        } else {
            let sel = NSSelectorFromString("setOrientation:")
            if UIDevice.current.responds(to: sel) {
                UIDevice.current.setValue(orientation, forKey: "orientation")
            }
        }
    }
}
