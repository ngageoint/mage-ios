//
//  DarkColorScheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public class DarkColorScheme: NSObject, AppColorScheming {
    public var primaryColor: UIColor? = UIColor(named: "primary") ?? .systemBlue
    public var primaryColorVariant: UIColor? = UIColor(named: "primaryVariant") ?? .systemBlue
    public var secondaryColor: UIColor? = UIColor(named: "secondary") ?? .systemOrange
    public var onSecondaryColor: UIColor? = UIColor(named: "onSecondary") ?? .white
    public var surfaceColor: UIColor? = UIColor(named: "surface") ?? .systemGray6
    public var onSurfaceColor: UIColor? = .white
    public var backgroundColor: UIColor? = UIColor(named: "background") ?? .black
    public var onBackgroundColor: UIColor? = .white
    public var errorColor: UIColor? = .systemRed
    public var onPrimaryColor: UIColor? = UIColor(named: "onPrimary") ?? .white
}
