//
//  DarkNamedColorTheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/6/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


import UIKit

class DarkNamedColorTheme: DarkAppTheme {
    override init() {
        super.init()

        if let colorScheme = colorScheme as? DarkColorScheme {
            colorScheme.primaryColorVariant = UIColor(named: "primaryVariant") ?? UIColor.systemBlue
            colorScheme.primaryColor = UIColor(named: "primary") ?? UIColor.systemBlue
            colorScheme.secondaryColor = UIColor(named: "secondary") ?? UIColor.systemOrange
            colorScheme.onSecondaryColor = UIColor(named: "onSecondary") ?? UIColor.white
            colorScheme.surfaceColor = UIColor(named: "surface") ?? UIColor.systemGray6
            colorScheme.onSurfaceColor = UIColor.white
            colorScheme.backgroundColor = UIColor(named: "background") ?? UIColor.black
            colorScheme.onBackgroundColor = UIColor.white
            colorScheme.errorColor = UIColor.systemRed
            colorScheme.onPrimaryColor = UIColor(named: "onPrimary") ?? UIColor.white
        }
    }
}
