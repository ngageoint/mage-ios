//
//  PassThroughStackView.swift
//  MAGE
//
//  Created by Daniel Barela on 1/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class PassThroughStackView : UIStackView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result == self { return nil }
        return result
    }
}
