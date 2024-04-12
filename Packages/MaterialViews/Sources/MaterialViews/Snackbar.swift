//
//  Snackbar.swift
//  Marlin
//
//  Created by Daniel Barela on 8/15/22.
//

import Foundation
import SwiftUI
import MAGEStyle
import ViewExtensions

public struct SnackbarModel {
    let message: String?
    let actionText: String?
    let action: (() -> Void)?

    public init(message: String?) {
        self.init(message: message, actionText: nil, action: nil)
    }

    public init(message: String?, actionText: String?, action: (() -> Void)?) {
        self.message = message
        self.actionText = actionText
        self.action = action
    }
}

public struct SnackbarContent: View {
    let snackbarModel: SnackbarModel?

    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if let message = snackbarModel?.message {
                Text(message)
                    .font(Font.body2)
                    .foregroundColor(Color.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .padding([.top, .bottom], 16)
                    .padding(.trailing, 8)
            }
            Spacer()
            if let actionText = snackbarModel?.actionText, let action = snackbarModel?.action {
                Button(action: action) {
                    Label {
                        Text(actionText)
                    } icon: {}
                }
                .buttonStyle(MaterialButtonStyle(type: .text))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .background(Color(.sRGB, red: 32/256.0, green: 32/256.0, blue: 32/256.0, opacity: 1))
    }
}

public struct Snackbar<Presenting, Content>: View where Presenting: View, Content: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var isPresented: Bool
    let presenter: () -> Presenting
    let content: () -> Content
    let delay: TimeInterval = 2

    public var body: some View {
        if self.isPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                withAnimation {
                    self.isPresented = false
                }
            }
        }

        return GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                self.presenter()
                self.content()
                    .background(RoundedRectangle(cornerRadius: 4.0)
                        .border(Color.onSurfaceColor.opacity(0.45), width: 1.0)
                    )
                    .opacity(self.isPresented ? 1 : 0)

                    .if(horizontalSizeClass == .regular) { view in
                        view.frame(
                            minWidth: 344.0,
                            idealWidth: 344.0,
                            maxWidth: 344.0,
                            minHeight: 48.0,
                            idealHeight: 48.0,
                            maxHeight: 68.0,
                            alignment: .leading
                        )
                    }
                    .if(horizontalSizeClass == .compact) { view in
                        view.frame(width: geometry.size.width - 16, height: 48.0)
                    }
                    .padding(.bottom)
            }
        }
    }
}

public extension View {
    func snackbar<Content>(
        isPresented: Binding<Bool>,
        content: @escaping () -> Content
    ) -> some View where Content: View {
        Snackbar(
            isPresented: isPresented,
            presenter: { self },
            content: content
        )
    }
}
