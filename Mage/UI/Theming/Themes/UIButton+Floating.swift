//
//  UIButton+Floating.swift
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

public extension UIButton {
    
    /// Full version (customizable floating button)
    static func floatingButton(
        imageName: String?,
        scheme: AppContainerScheming?,
        useErrorColor: Bool = false,
        size: CGFloat = 40.0,
        cornerRadius: CGFloat? = nil,
        target: Any?,
        action: Selector,
        tag: Int = 0,
        accessibilityLabel: String? = nil
    ) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = tag
        
        if let name = imageName {
            button.setImage(UIImage(named: name), for: .normal)
        }

        if let label = accessibilityLabel {
            button.accessibilityLabel = label
        }
        
        button.addTarget(target, action: action, for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])

        // Round or custom styling
        button.layer.cornerRadius = cornerRadius ?? size / 2.0
        button.clipsToBounds = true

        let color = useErrorColor ? scheme?.colorScheme.errorColor : scheme?.colorScheme.primaryColor
        button.backgroundColor = color ?? .systemBlue

        button.tintColor = scheme?.colorScheme.onPrimaryColor ?? .white
        
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
