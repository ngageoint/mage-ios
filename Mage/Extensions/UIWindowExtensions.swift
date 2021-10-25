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
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.overrideUserInterfaceStyle = .dark;
    }
    
    @objc static func forceLightMode() {
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.overrideUserInterfaceStyle = .light;
    }
    
    @objc static func followSystemColors() {
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.overrideUserInterfaceStyle = .unspecified;
    }
    
    @objc static func getInterfaceStyle() -> UIUserInterfaceStyle {
        return (UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.overrideUserInterfaceStyle) ?? .unspecified;
    }
}
