//
//  FloatingButtonFactory.swift
//  MAGE
//
//  Created by Brent Michalski on 6/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public class FloatingButtonFactory: NSObject {
    
    @objc public static func floatingButtonWithImageName(
        _ imageName: String?,
        scheme: AppContainerScheming?,
        useErrorColor: Bool,
        size: CGFloat,
        target: Any?,
        action: Selector?,
        tag: Int,
        accessabilityLabel: String?
    ) -> UIButton {
        return UIButton.floatingButton(
            imageName: imageName,
            scheme: scheme,
            useErrorColor: useErrorColor,
            size: size,
            target: target,
            action: action ?? #selector(dummySelector),
            tag: tag,
            accessibilityLabel: accessabilityLabel
        )
    }
    
    @objc public static func floatingButtonWithImageName(
        _ imageName: String?,
        scheme: AppContainerScheming?,
        target: Any?,
        action: Selector?,
        tag: Int,
        accessibilityLabel: String?
    ) -> UIButton {
        return UIButton.floatingButton(
            imageName: imageName,
            scheme: scheme,
            target: target,
            action: action ?? #selector(dummySelector),
            tag: tag,
            accessibilityLabel: accessibilityLabel
        )
    }
    
    @objc public static func dummySelector() {
        // Needed as a fallback for nil-safety
    }
}
