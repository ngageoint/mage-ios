//
//  UITextField+Theming.swift
//  MAGE
//
//  Created by Brent Michalski on 6/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

extension UITextField {
    enum TextFieldThemeType {
        case primary
        case disabled
    }
    
    func applyTheme(
        type: TextFieldThemeType,
        colorScheme: AppColorScheming?,
        typographScheme: AppTypographyScheming?,
        defaultFont: UIFont? = nil) {
            guard let colorScheme = colorScheme,
                    let typographScheme = typographScheme else { return }
            
            // Background and text color
            switch type {
                case .primary:
                backgroundColor = colorScheme.surfaceColor ?? .systemBackground
                textColor = colorScheme.primaryColor ?? .systemBlue
                tintColor = colorScheme.primaryColor ?? .systemBlue
                
            case .disabled:
                backgroundColor = colorScheme.surfaceColor?.withAlphaComponent(0.5) ?? UIColor.systemGray5
                textColor = colorScheme.surfaceColor?.withAlphaComponent(0.5) ?? UIColor.systemGray
                tintColor = colorScheme.primaryColor?.withAlphaComponent(0.5) ?? UIColor.systemGray
            }
            
            // Placeholder color
            if let placeholder {
                let placeholderAlpha: CGFloat = {
                    switch type {
                    case .primary: return 0.6
                    case .disabled: return 0.4
                    }
                }()
                
                self.attributedPlaceholder = NSAttributedString(
                    string: placeholder,
                    attributes: [
                        .foregroundColor: (colorScheme.onSurfaceColor ?? .label).withAlphaComponent(placeholderAlpha)
                    ]
                )
            }
            
            // Font
            switch type {
            case .primary:
                font = defaultFont ?? typographScheme.bodyFont
            case .disabled:
                font = defaultFont ?? typographScheme.bodyFont
            }
            
            // Border
            let borderColor: UIColor  = {
                switch type {
                case .primary: return colorScheme.primaryColor ?? .systemBlue
                case .disabled: return colorScheme.onSurfaceColor ?? .systemGray
                }
            }()
            
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 1.0
            layer.cornerRadius = 8.0
    }
    
    
    func applyPrimaryTheme(withScheme scheme: AppContainerScheming?) {
        self.applyTheme(type: .primary, colorScheme: scheme?.colorScheme, typographScheme: scheme?.typographyScheme)
    }

    func applyDisabledTheme(withScheme scheme: AppContainerScheming?) {
        self.applyTheme(type: .primary, colorScheme: scheme?.colorScheme, typographScheme: scheme?.typographyScheme)
    }
}
