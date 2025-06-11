//
//  UITextField+Placeholder.swift
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import ObjectiveC.runtime

private var kPlaceholderLabelKey: UInt8 = 0

extension UITextView {

    private var placeholderLabel: UILabel {
        get {
            if let label = objc_getAssociatedObject(self, &kPlaceholderLabelKey) as? UILabel {
                return label
            } else {
                let label = UILabel()
                label.numberOfLines = 0
                label.font = self.font
                label.textColor = UIColor.placeholderText
                label.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(label)
                self.sendSubviewToBack(label)
                
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
                    label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
                    label.topAnchor.constraint(equalTo: self.topAnchor, constant: 8)
                ])
                
                objc_setAssociatedObject(self, &kPlaceholderLabelKey, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return label
            }
        }
    }
    
    public var placeholder: String? {
        get {
            return placeholderLabel.text
        }
        set {
            placeholderLabel.text = newValue
            updatePlaceholderVisibility()
        }
    }
    
    public func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !self.text.isEmpty
    }
    
    // Lets us automatically update placeholder when user types
    public func enablePlaceholderObservation() {
        NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaceholderVisibility()
        }
    }
    
}

