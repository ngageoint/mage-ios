//
//  File.swift
//  
//
//  Created by Dan Barela on 7/17/24.
//

import Foundation
import SwiftUI

public struct CardModifier: ViewModifier {

    public func body(content: Content) -> some View {
        content
            .background(Color.surfaceColor)
            .mask(Rectangle()
                .cornerRadius(5.0)
            )
            .overlay( /// apply a rounded border
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.onSurfaceColor.opacity(0.15), lineWidth: 0.25)
            )
    }

}

extension View {
    public func card() -> some View {
        modifier(CardModifier())
    }
}

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

public struct NoContentTitleText: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(Font.headline4)
            .foregroundColor(Color.onSurfaceColor)
            .opacity(0.6)
    }
}

public extension View {
    func noContentText() -> some View {
        modifier(NoContentTitleText())
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
