//
//  AttributedMessageView.swift
//  MAGE
//
//  Created by Brent Michalski on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import SwiftUI

struct AttributedMessageView: UIViewRepresentable {
    let attributed: NSAttributedString
    let accessibilityLabel: String?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.isAccessibilityElement = true
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributed
        uiView.accessibilityLabel = accessibilityLabel ?? "Message"
        uiView.textAlignment = .center
    }
}
