//
//  AppColorScheming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


import UIKit

@objc public protocol AppColorScheming: AnyObject {
    var primaryColor: UIColor? { get }
    var primaryColorVariant: UIColor? { get }
    var secondaryColor: UIColor? { get }
    var onSecondaryColor: UIColor? { get }
    var surfaceColor: UIColor? { get }
    var onSurfaceColor: UIColor? { get }
    var backgroundColor: UIColor? { get }
    var onBackgroundColor: UIColor? { get }
    var errorColor: UIColor? { get }
    var onPrimaryColor: UIColor? { get }
}
