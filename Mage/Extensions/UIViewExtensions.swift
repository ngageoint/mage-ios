//
//  UIViewExtensions.swift
//  MAGE
//
//  Created by Daniel Barela on 8/23/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension UIResponder {
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}

extension UIView {
    var firstResponder: UIView? {
        if self.isFirstResponder {
            return self
        }
        return getSubView(views: self.subviews)
    }

    func firstInputResponder() -> UIView? {
        if self is UITextField || self is UITextView || self is NumberFieldView {
            return self
        }
        for subview in subviews {
            if let found = subview.firstInputResponder() {
                return found
            }
        }
        return nil
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
