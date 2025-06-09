//
//  AppContainerScheming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public protocol AppContainerScheming: AnyObject {
    var colorScheme: AppColorScheming? { get }
    var shapeScheme: AppShapeScheming? { get }
    var typographyScheme: AppTypographyScheming? { get }
}
