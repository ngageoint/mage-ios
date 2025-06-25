//
//  UITabBar+Theming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/25/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc extension UITabBar {

    @objc func applyPrimaryTheme(withScheme scheme: AppContainerScheming?) {
        guard let colorScheme = scheme?.colorScheme else { return }
        self.barTintColor = colorScheme.surfaceColor
        self.tintColor = colorScheme.primaryColor
        self.unselectedItemTintColor = colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        self.isTranslucent = false
    }
}
