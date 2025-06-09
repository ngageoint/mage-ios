//
//  ErrorColorScheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public class ErrorColorScheme: NSObject, AppColorScheming {
    public var primaryColor: UIColor? = .systemRed
    public var primaryColorVariant: UIColor? = .systemRed
    public var secondaryColor: UIColor? = .systemRed
    public var onSecondaryColor: UIColor? = .white
    public var surfaceColor: UIColor? = UIColor(named: "surface") ?? .systemBackground
    public var onSurfaceColor: UIColor? = .label
    public var backgroundColor: UIColor? = UIColor(named: "background") ?? .systemBackground
    public var onBackgroundColor: UIColor? = .label
    public var errorColor: UIColor? = .systemRed
    public var onPrimaryColor: UIColor? = .white
}
