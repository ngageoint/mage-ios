//
//  UILabel+Theming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

extension UILabel {
    enum LabelThemeType {
        case primary
        case secondary
        case disabled
    }
    
    func applyTheme(
        type: LabelThemeType,
        colorScheme: AppColorScheming?,
        typographScheme: AppTypographyScheming?,
        defaultFont: UIFont? = nil) {
            guard let colorScheme = colorScheme,
                    let typographScheme = typographScheme else { return }
            
            let baseColor = colorScheme.onSurfaceColor ?? .label
            backgroundColor = .clear
            
            switch type {
            case .primary:
                textColor = baseColor
                font = defaultFont ?? typographScheme.headlineFont
                
            case .secondary:
                textColor = baseColor.withAlphaComponent(0.6)
                font = defaultFont ?? typographScheme.bodyFont
                
            case .disabled:
                textColor = baseColor.withAlphaComponent(0.4)
                font = defaultFont ?? typographScheme.bodyFont
            }
    }
    
    func applyPrimaryTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme = scheme else { return }
        self.applyTheme(type: .primary, colorScheme: scheme.colorScheme, typographScheme: scheme.typographyScheme)
    }

    func applySecondaryTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme = scheme else { return }
        self.applyTheme(type: .secondary, colorScheme: scheme.colorScheme, typographScheme: scheme.typographyScheme)
    }

    func applyDisabledTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme = scheme else { return }
        self.applyTheme(type: .disabled, colorScheme: scheme.colorScheme, typographScheme: scheme.typographyScheme)
    }
    
}
