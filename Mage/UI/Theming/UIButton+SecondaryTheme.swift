//
//  UIButton+SecondaryTheme.swift
//  MAGE
//
//  Created by Brent Michalski on 6/6/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

extension UIButton {
    func applySecondaryTheme(with colorScheme: AppColorScheming?) {
        guard let colorScheme = colorScheme else { return }

        self.backgroundColor = colorScheme.surfaceColor ?? .systemBackground
        self.setTitleColor(colorScheme.onSurfaceColor ?? .label, for: .normal)
        self.setTitleColor((colorScheme.onSurfaceColor ?? .label).withAlphaComponent(0.5), for: .highlighted)

        self.layer.borderColor = (colorScheme.onSurfaceColor ?? .label).cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 8.0
    }
}
