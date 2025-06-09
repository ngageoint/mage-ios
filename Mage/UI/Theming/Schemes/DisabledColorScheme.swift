//
//  DisabledColorScheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc public final class DisabledColorScheme: NSObject, AppColorScheming {
    
    public let primaryColor: UIColor? = .systemGray3
    public let primaryColorVariant: UIColor? = .systemGray3
    public let secondaryColor: UIColor? = .systemGray3
    public let onSecondaryColor: UIColor? = .systemGray
    public let surfaceColor: UIColor? = .systemGray3
    public let onSurfaceColor: UIColor? = .systemGray
    public let backgroundColor: UIColor? = .systemGray3
    public let onBackgroundColor: UIColor? = .systemGray
    public let errorColor: UIColor? = .systemRed
    public let onPrimaryColor: UIColor? = .systemGray
}
