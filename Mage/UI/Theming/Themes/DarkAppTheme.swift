//
//  DarkAppTheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


import UIKit

@objc public final class DarkAppTheme: NSObject, AppContainerScheming {
    public let colorScheme: AppColorScheming?
    public let shapeScheme: AppShapeScheming?
    public let typographyScheme: AppTypographyScheming?
    
    public override init() {
        self.colorScheme = DarkColorScheme()
        self.shapeScheme = DefaultShapeScheme()
        self.typographyScheme = DefaultTypographyScheme()
        super.init()
    }
}
