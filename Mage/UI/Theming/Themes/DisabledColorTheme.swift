//
//  DisabledColorTheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


import UIKit

class DisabledColorTheme: LightAppTheme {
    override init() {
        super.init()

        if let colorScheme = colorScheme as? LightColorScheme {
            let grey300 = UIColor.systemGray3
            let grey500 = UIColor.systemGray

            colorScheme.primaryColorVariant = grey300
            colorScheme.primaryColor = grey300
            colorScheme.secondaryColor = grey300
            colorScheme.onSecondaryColor = grey500
            colorScheme.surfaceColor = grey300
            colorScheme.onSurfaceColor = grey500
            colorScheme.backgroundColor = grey300
            colorScheme.onBackgroundColor = grey500
            colorScheme.errorColor = .systemRed
            colorScheme.onPrimaryColor = grey500
        }
    }
}
