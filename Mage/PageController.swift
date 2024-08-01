//
//  PageController.swift
//  MAGE
//
//  Created by Dan Barela on 7/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import MaterialViews

struct PageController: View {
    var count: Int
    var selectedItem: Int
    var leftTap: (() -> Void)
    var rightTap: (() -> Void)
    
    var body: some View {
        HStack(spacing: 8) {
            Button(
                action: {
                    leftTap()

                },
                label: {
                    Label(
                        title: {},
                        icon: {
                            Image(systemName: "chevron.left")
                                .renderingMode(.template)
                                .foregroundColor(selectedItem != 0
                                                 ? Color.primaryColorVariant : Color.disabledColor
                                )
                        })
                }
            )
            .buttonStyle(MaterialButtonStyle())
            .accessibilityElement()
            .accessibilityLabel("previous")

            Text("\(selectedItem + 1) of \(count)")
                .font(Font.caption)
                .foregroundColor(Color.onSurfaceColor.opacity(0.6))

            Button(
                action: {
                    rightTap()
                },
                label: {
                    Label(
                        title: {},
                        icon: {
                            Image(systemName: "chevron.right")
                                .renderingMode(.template)
                                .foregroundColor(count - 1 != selectedItem
                                                 ? Color.primaryColorVariant : Color.disabledColor)
                        })
                }
            )
            .buttonStyle(MaterialButtonStyle())
            .accessibilityElement()
            .accessibilityLabel("next")
        }
    }
}
