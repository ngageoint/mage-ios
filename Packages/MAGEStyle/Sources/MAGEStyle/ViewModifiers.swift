//
//  File.swift
//  
//
//  Created by Dan Barela on 7/17/24.
//

import Foundation
import SwiftUI

public struct OverlineText: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(Font.overline)
            .foregroundColor(Color.onSurfaceColor)
            .opacity(0.45)
    }
}

public extension View {
    func overlineText() -> some View {
        modifier(OverlineText())
    }
}

public struct PrimaryText: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(Font.headline6)
            .foregroundColor(Color.onSurfaceColor)
            .opacity(0.87)
    }
}

public extension View {
    func primaryText() -> some View {
        modifier(PrimaryText())
    }
}

public struct SecondaryText: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(Font.subtitle2)
            .foregroundColor(Color.onSurfaceColor)
            .opacity(0.6)
    }
}

public extension View {
    func secondaryText() -> some View {
        modifier(SecondaryText())
    }
}

public struct PropertyValueText: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(Font.body1)
            .foregroundColor(Color.onSurfaceColor)
    }
}

public extension View {
    func propertyValueText() -> some View {
        modifier(PropertyValueText())
    }
}
