//
//  ThemeProvider.swift
//  MAGE
//
//  Created by Brent Michalski on 6/6/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


enum ThemeProvider {
    static func defaultTheme() -> AppContainerScheming {
        return LightAppTheme()
    }

    static func errorTheme() -> AppContainerScheming {
        return ErrorAppTheme()
    }

    static func disabledTheme() -> AppContainerScheming {
        return DisabledAppTheme()
    }
}
