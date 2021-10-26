//
//  UIWindowExtensions.swift
//  MAGE
//
//  Created by Daniel Barela on 7/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension UIWindow {
    @objc static var isLandscape: Bool {
        return UIApplication.shared.windows
            .first?
            .windowScene?
            .interfaceOrientation
            .isLandscape ?? false
    }

    @objc static func forceDarkMode() {
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            UIView.transition (with: window, duration: 0.4, options: .transitionCrossDissolve, animations: {
                window.overrideUserInterfaceStyle = .dark
            }, completion: nil)
        }
    }
    
    @objc static func forceLightMode() {
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            UIView.transition (with: window, duration: 0.4, options: .transitionCrossDissolve, animations: {
                window.overrideUserInterfaceStyle = .light
            }, completion: nil)
        }
    }
    
    @objc static func followSystemColors() {
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            UIView.transition (with: window, duration: 0.4, options: .transitionCrossDissolve, animations: {
                window.overrideUserInterfaceStyle = .unspecified
            }, completion: nil)
        }
    }
    
    @objc static func getInterfaceStyle() -> UIUserInterfaceStyle {
        return (UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.overrideUserInterfaceStyle) ?? .unspecified;
    }
}
