//
//  UIButton+Floating.swift
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

extension UIButton {
    
    /// Full version (customizable floating button)
    @objc static func floatingButton(
        imageName: String?,
        scheme: AppContainerScheming?,
        useErrorColor: Bool = false,
        size: CGFloat = 40.0,
        target: Any?,
        action: Selector,
        tag: Int = 0,
        accessibilityLabel: String? = nil
    ) -> UIButton {
        
        let button = UIButton(type: .custom)
        
        // Set image if available
        var buttonImage: UIImage? = nil
        if let imageName = imageName {
            buttonImage = UIImage(systemName: imageName) ?? UIImage(named: imageName)
        }
        button.setImage(buttonImage, for: .normal)
        
        // Apply theme
        if useErrorColor {
            button.applySecondaryTheme(withScheme: ThemeProvider.errorTheme())
        } else {
            button.applySecondaryTheme(withScheme: scheme)
        }
        
        // Round styling
        button.frame = CGRect(x: 0, y: 0, width: size, height: size)
        button.layer.cornerRadius = size / 2.0
        button.clipsToBounds = true
        
        // Target/action
        button.addTarget(target, action: action, for: .touchUpInside)
        
        // Tag
        button.tag = tag
        
        // Accessibility
        if let accessibilityLabel = accessibilityLabel {
            button.accessibilityLabel = accessibilityLabel
        }
        
        return button
    }
    
    /// Convenience version (default size = 40.0, useErrorColor = false)
    @objc static func floatingButton(
        imageName: String?,
        scheme: AppContainerScheming?,
        target: Any?,
        action: Selector,
        tag: Int = 0,
        accessibilityLabel: String? = nil
    ) -> UIButton {
        return floatingButton(
            imageName: imageName,
            scheme: scheme,
            useErrorColor: false,
            size: 40.0,
            target: target,
            action: action,
            tag: tag,
            accessibilityLabel: accessibilityLabel
        )
    }
}
