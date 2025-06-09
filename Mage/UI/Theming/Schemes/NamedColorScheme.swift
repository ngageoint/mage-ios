//
//  NamedColorScheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public final class NamedColorScheme: NSObject, AppColorScheming {
    
    public let primaryColor: UIColor? = UIColor(named: "primary") ?? .systemBlue
    public let primaryColorVariant: UIColor? = UIColor(named: "primaryVariant") ?? .systemBlue
    public let secondaryColor: UIColor? = UIColor(named: "secondary") ?? .systemOrange
    public let onSecondaryColor: UIColor? = UIColor(named: "onSecondary") ?? .label
    public let surfaceColor: UIColor? = UIColor(named: "surface") ?? .systemBackground
    public let onSurfaceColor: UIColor? = .label
    public let backgroundColor: UIColor? = UIColor(named: "background") ?? .systemBackground
    public let onBackgroundColor: UIColor? = .label
    public let errorColor: UIColor? = .systemRed
    public let onPrimaryColor: UIColor? = UIColor(named: "onPrimary") ?? .white
}
