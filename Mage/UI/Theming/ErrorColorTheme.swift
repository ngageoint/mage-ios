//
//  ErrorColorTheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


import UIKit

class ErrorColorTheme: LightAppTheme {
    override init() {
        super.init()

        if let colorScheme = colorScheme as? LightColorScheme {
            colorScheme.primaryColorVariant = .systemRed
            colorScheme.primaryColor = .systemRed
            colorScheme.secondaryColor = .systemRed
            colorScheme.onSecondaryColor = .white
            colorScheme.surfaceColor = UIColor(named: "surface") ?? .systemBackground
            colorScheme.onSurfaceColor = .label
            colorScheme.backgroundColor = UIColor(named: "background") ?? .systemBackground
            colorScheme.onBackgroundColor = .label
            colorScheme.errorColor = .systemRed
            colorScheme.onPrimaryColor = .white
        }
    }
}
