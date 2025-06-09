//
//  NamedColorTheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import UIKit

class NamedColorTheme: LightAppTheme {
    override init() {
        super.init()
        
        if let colorScheme = colorScheme as? LightColorScheme {
            colorScheme.primaryColor = UIColor(named: "primary") ?? .systemBlue
            colorScheme.primaryColorVariant = UIColor(named: "primaryVariant") ?? .systemBlue
            colorScheme.secondaryColor = UIColor(named: "secondary") ?? .systemOrange
            colorScheme.onSecondaryColor = UIColor(named: "onSecondary") ?? .label
            colorScheme.surfaceColor = UIColor(named: "surface") ?? .systemBackground
            colorScheme.onSurfaceColor = UIColor.label
            colorScheme.backgroundColor = UIColor(named: "background") ?? .systemBackground
            colorScheme.onBackgroundColor = UIColor.label
            colorScheme.errorColor = UIColor.systemRed
            colorScheme.onPrimaryColor = UIColor(named: "onPrimary") ?? .white
        }
    }
}
