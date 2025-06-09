//
//  UIColor+Scheming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

extension AppColorScheming {
    func color(_ keyPath: KeyPath<AppColorScheming, UIColor?>, fallback: UIColor) -> UIColor {
        return self[keyPath: keyPath] ?? fallback
    }
}

extension Optional where Wrapped == AppColorScheming {
    func color(_ keyPath: KeyPath<AppColorScheming, UIColor?>, fallback: UIColor) -> UIColor {
        switch self {
        case .some(let scheme):
            return scheme[keyPath: keyPath] ?? fallback
        case .none:
            return fallback
        }
    }
}
