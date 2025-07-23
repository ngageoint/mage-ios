//
//  SchemeTemporaryReplacement.swift
//  MAGE
//
//  Created by Brent Michalski on 7/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

// MARK: - Color Scheming Protocol

@objc public protocol AppColorScheming {
    var primaryColor: UIColor { get }
    var primaryColorVariant: UIColor { get }
    var secondaryColor: UIColor { get }
    var errorColor: UIColor { get }
    var surfaceColor: UIColor { get }
    var backgroundColor: UIColor { get }
    var onPrimaryColor: UIColor { get }
    var onSecondaryColor: UIColor { get }
    var onSurfaceColor: UIColor { get }
    var onBackgroundColor: UIColor { get }
    @objc optional var elevationOverlayEnabledForDarkMode: Bool { get }
}

@objc public protocol AppTypographyScheming {
    var headline1: UIFont { get }
    var headline2: UIFont { get }
    var headline3: UIFont { get }
    var headline4: UIFont { get }
    var headline5: UIFont { get }
    var headline6: UIFont { get }
    var subtitle1: UIFont { get }
    var subtitle2: UIFont { get }
    var body1: UIFont { get }
    var body2: UIFont { get }
    var caption: UIFont { get }
    var button: UIFont { get }
    var overline: UIFont { get }
    @objc optional var useCurrentContentSizeCategoryWhenApplied: Bool { get }
}

@objc public protocol AppShapeScheming {
    var smallComponentCornerRadius: CGFloat { get }
    var mediumComponentCornerRadius: CGFloat { get }
    var largeComponentCornerRadius: CGFloat { get }
}

@objc public protocol AppContainerScheming {
    var colorScheme: AppColorScheming { get }
    var typographyScheme: AppTypographyScheming { get }
    @objc optional var shapeScheme: AppShapeScheming { get }
}

// MARK: - Default Implementations

@objcMembers
public class AppDefaultColorScheme: NSObject, AppColorScheming {
    public var primaryColor: UIColor { UIColor.systemBlue }
    public var primaryColorVariant: UIColor { UIColor.systemIndigo }
    public var secondaryColor: UIColor { UIColor.systemTeal }
    public var errorColor: UIColor { UIColor.systemRed }
    public var surfaceColor: UIColor { UIColor.systemBackground }
    public var backgroundColor: UIColor { UIColor.systemBackground }
    public var onPrimaryColor: UIColor { UIColor.white }
    public var onSecondaryColor: UIColor { UIColor.black }
    public var onSurfaceColor: UIColor { UIColor.label }
    public var onBackgroundColor: UIColor { UIColor.label }
    public var elevationOverlayEnabledForDarkMode: Bool { true }
}

@objcMembers
public class AppDefaultTypographyScheme: NSObject, AppTypographyScheming {
    public var headline1: UIFont { UIFont.systemFont(ofSize: 32, weight: .bold) }
    public var headline2: UIFont { UIFont.systemFont(ofSize: 28, weight: .semibold) }
    public var headline3: UIFont { UIFont.systemFont(ofSize: 24, weight: .semibold) }
    public var headline4: UIFont { UIFont.systemFont(ofSize: 22, weight: .semibold) }
    public var headline5: UIFont { UIFont.systemFont(ofSize: 20, weight: .medium) }
    public var headline6: UIFont { UIFont.systemFont(ofSize: 18, weight: .medium) }
    public var subtitle1: UIFont { UIFont.systemFont(ofSize: 16, weight: .regular) }
    public var subtitle2: UIFont { UIFont.systemFont(ofSize: 14, weight: .regular) }
    public var body1: UIFont { UIFont.systemFont(ofSize: 16, weight: .regular) }
    public var body2: UIFont { UIFont.systemFont(ofSize: 14, weight: .regular) }
    public var caption: UIFont { UIFont.systemFont(ofSize: 12, weight: .regular) }
    public var button: UIFont { UIFont.systemFont(ofSize: 16, weight: .medium) }
    public var overline: UIFont { UIFont.systemFont(ofSize: 10, weight: .regular) }
    public var useCurrentContentSizeCategoryWhenApplied: Bool { true }
}

@objcMembers
public class AppDefaultShapeScheme: NSObject, AppShapeScheming {
    public var smallComponentCornerRadius: CGFloat { 4 }
    public var mediumComponentCornerRadius: CGFloat { 8 }
    public var largeComponentCornerRadius: CGFloat { 0 }
}

@objcMembers
public class AppDefaultContainerScheme: NSObject, AppContainerScheming {
    public let colorScheme: AppColorScheming
    public let typographyScheme: AppTypographyScheming
    public let shapeScheme: AppShapeScheming

    public override init() {
        self.colorScheme = AppDefaultColorScheme()
        self.typographyScheme = AppDefaultTypographyScheme()
        self.shapeScheme = AppDefaultShapeScheme()
        super.init()
    }
}
