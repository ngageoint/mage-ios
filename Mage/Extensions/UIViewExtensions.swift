//
//  UIViewExtensions.swift
//  MAGE
//
//  Created by Daniel Barela on 8/23/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension UIView {
    var firstResponder: UIView? {
        if self.isFirstResponder {
            return self
        }
        return getSubView(views: self.subviews)
    }
    
    private func getSubView(views: [UIView]) -> UIView? {
        guard subviews.count > 0 else {
            return nil
        }
        if let responder = views.filter({ $0.isFirstResponder }).first {
            return responder
        }
        for responder in views {
            if let view = getSubView(views: responder.subviews) {
                return view
            }
        }
        return .none
    }
}
