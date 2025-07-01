//
//  View+EmptyPlaceholder.swift
//  MAGE
//
//  Created by Brent Michalski on 7/1/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

public struct EmptyPlaceholderModifier<Items: Collection>: ViewModifier {
    let items: Items
    let placeholder: AnyView

    @ViewBuilder
    public func body(content: Content) -> some View {
        if items.isEmpty {
            placeholder
        } else {
            content
        }
    }
}

public extension View {
    func emptyPlaceholder<Items: Collection, PlaceholderView: View>(
        _ items: Items,
        placeholder: @escaping () -> PlaceholderView
    ) -> some View {
        self.modifier(EmptyPlaceholderModifier(items: items, placeholder: AnyView(placeholder())))
    }
}
