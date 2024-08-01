//
//  ViewExtensions.swift
//  Marlin
//
//  Created by Daniel Barela on 8/12/22.
//

import Foundation
import SwiftUI
import MAGEStyle

public extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @discardableResult
    @ViewBuilder func `if`<Content: View>(
        _ condition: @autoclosure () -> Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }

    /**
     Usage

     .complexModifier {
     if #available(iOS 16, *) {
     $0.toolbarColorScheme(.dark, for: .navigationBar)
     }
     else {
     $0
     }
     }
     */
    func complexModifier<V: View>(@ViewBuilder _ closure: (Self) -> V) -> some View {
        closure(self)
    }

    func underlineTextField() -> some View {
        self
            .padding(.vertical, 10)
            .overlay(Rectangle().frame(height: 2).padding(.top, 35))
            .foregroundColor(Color.primaryColorVariant)
            .padding(10)
    }

    func underlineTextFieldWithLabel() -> some View {
        self
            .overlay(Rectangle().frame(height: 2).padding(.top, 35))
            .foregroundColor(Color.primaryColorVariant)
            .padding(.bottom, 10)
    }

    func borderedTextField() -> some View {
        self
            .foregroundColor(Color.onSurfaceColor.opacity(0.87))
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.primaryColor, lineWidth: 1)
            )
    }
}

public struct EmptyPlaceholderModifier<Items: Collection>: ViewModifier {
    let items: Items
    let placeholder: AnyView

    @ViewBuilder public func body(content: Content) -> some View {
        if !items.isEmpty {
            content
        } else {
            placeholder
        }
    }
}

public extension View {
    func emptyPlaceholder<Items: Collection, PlaceholderView: View>(
        _ items: Items, _ placeholder: @escaping () -> PlaceholderView
    ) -> some View {
        modifier(EmptyPlaceholderModifier(items: items, placeholder: AnyView(placeholder())))
    }
}
