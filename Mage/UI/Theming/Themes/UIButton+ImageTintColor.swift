//
//  UIButton+ImageTintColor.swift
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

extension UIButton {
    func setImageTintColor(_ color: UIColor?, for state: UIControl.State) {
        guard let image = self.image(for: state)?.withRenderingMode(.alwaysTemplate) else { return }
        self.setImage(image, for: state)
        self.tintColor = color
    }
}
