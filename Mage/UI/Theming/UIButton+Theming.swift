//
//  UIButton+SecondaryTheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/6/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

extension UIButton {
    enum ButtonThemeType {
        case primary
        case secondary
        case disabled
    }

    func applyTheme(type: ButtonThemeType, colorScheme: AppColorScheming?, typographyScheme: AppTypographyScheming?, defaultFont: UIFont? = nil) {
        
    }
    
    func applyPrimaryTheme(with colorScheme: AppColorScheming?) {
        guard let colorScheme = colorScheme else { return }

        self.backgroundColor = colorScheme.primaryColor ?? .systemBlue
        self.setTitleColor(colorScheme.onPrimaryColor ?? .white, for: .normal)
        self.setTitleColor((colorScheme.onPrimaryColor ?? .white).withAlphaComponent(0.7), for: .highlighted)

        self.layer.borderWidth = 0
        self.layer.cornerRadius = 8.0
    }

    func applySecondaryTheme(with colorScheme: AppColorScheming?) {
        guard let colorScheme = colorScheme else { return }

        self.backgroundColor = colorScheme.surfaceColor ?? .systemBackground
        self.setTitleColor(colorScheme.onSurfaceColor ?? .label, for: .normal)
        self.setTitleColor((colorScheme.onSurfaceColor ?? .label).withAlphaComponent(0.5), for: .highlighted)

        self.layer.borderColor = (colorScheme.onSurfaceColor ?? .label).cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 8.0
    }

    func applyDisabledTheme(with colorScheme: AppColorScheming?) {
        guard let colorScheme = colorScheme else { return }

        self.backgroundColor = colorScheme.surfaceColor?.withAlphaComponent(0.5) ?? UIColor.systemGray5
        self.setTitleColor(colorScheme.onSurfaceColor?.withAlphaComponent(0.5) ?? UIColor.systemGray, for: .normal)

        self.layer.borderColor = (colorScheme.onSurfaceColor ?? UIColor.systemGray).cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 8.0
    }
}
