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
        guard let colorScheme = colorScheme, let typographyScheme = typographyScheme else { return }

        switch type {
          case .primary:
              self.backgroundColor = colorScheme.primaryColor ?? .systemBlue
              self.setTitleColor(colorScheme.onPrimaryColor ?? .white, for: .normal)
              self.setTitleColor((colorScheme.onPrimaryColor ?? .white).withAlphaComponent(0.7), for: .highlighted)

              self.layer.borderWidth = 0
              self.layer.cornerRadius = ThemingConstants.cornerRadius

              // Optional: if you want consistent fonts for buttons
              self.titleLabel?.font = defaultFont ?? typographyScheme.buttonFont

          case .secondary:
              self.backgroundColor = colorScheme.surfaceColor ?? .systemBackground
              self.setTitleColor(colorScheme.onSurfaceColor ?? .label, for: .normal)
              self.setTitleColor((colorScheme.onSurfaceColor ?? .label).withAlphaComponent(0.5), for: .highlighted)

              self.layer.borderColor = (colorScheme.onSurfaceColor ?? .label).cgColor
              self.layer.borderWidth = ThemingConstants.borderWidth
              self.layer.cornerRadius = ThemingConstants.cornerRadius

              self.titleLabel?.font = defaultFont ?? typographyScheme.buttonFont

          case .disabled:
              self.backgroundColor = colorScheme.surfaceColor?.withAlphaComponent(0.5) ?? UIColor.systemGray5
              self.setTitleColor(colorScheme.onSurfaceColor?.withAlphaComponent(0.5) ?? UIColor.systemGray, for: .normal)

              self.layer.borderColor = (colorScheme.onSurfaceColor ?? UIColor.systemGray).cgColor
              self.layer.borderWidth = ThemingConstants.borderWidth
              self.layer.cornerRadius = ThemingConstants.cornerRadius

              self.titleLabel?.font = defaultFont ?? typographyScheme.buttonFont
          }
    }
}


@objc public extension UIButton {
    func applyPrimaryTheme(withScheme scheme: AppContainerScheming?) {
        self.applyTheme(
            type: .primary,
            colorScheme: scheme?.colorScheme,
            typographyScheme: scheme?.typographyScheme
        )
    }

    func applySecondaryTheme(withScheme scheme: AppContainerScheming?) {
        self.applyTheme(
            type: .secondary,
            colorScheme: scheme?.colorScheme,
            typographyScheme: scheme?.typographyScheme
        )
    }

    func applyDisabledTheme(withScheme scheme: AppContainerScheming?) {
        self.applyTheme(
            type: .disabled,
            colorScheme: scheme?.colorScheme,
            typographyScheme: scheme?.typographyScheme
        )
    }
}
