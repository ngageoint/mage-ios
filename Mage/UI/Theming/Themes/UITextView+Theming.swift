//
//  UITextView+Theming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

extension UITextView {

    func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme = scheme else { return }
        applyTheme(colorScheme: scheme.colorScheme, typographyScheme: scheme.typographyScheme)
    }

    func applyTheme(colorScheme: AppColorScheming?, typographyScheme: AppTypographyScheming?, defaultFont: UIFont? = nil) {
        guard let colorScheme = colorScheme,
              let typographyScheme = typographyScheme else { return }
        
        backgroundColor = colorScheme.surfaceColor ?? .systemBackground
        textColor = colorScheme.onSurfaceColor ?? .label
        tintColor = colorScheme.primaryColor ?? .systemBlue
        
        font = defaultFont ?? typographyScheme.bodyFont
        
        layer.borderColor = (colorScheme.primaryColor ?? .systemBlue).cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 8.0
    }
}

