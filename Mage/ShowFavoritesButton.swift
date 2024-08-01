//
//  ShowFavoritesButton.swift
//  MAGE
//
//  Created by Dan Barela on 7/30/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

import SwiftUI
import MaterialViews

struct ShowFavoritesButton: View {
    var favoriteCount: Int?
    var favoriteAction: () -> Void
    
    var body: some View {
        Button {
            favoriteAction()
        } label: {
            Label {
                if let count = favoriteCount {
                    Text("\(count) Favorites").padding(.leading, 8)
                }
            } icon: {
            }
        }
        .buttonStyle(
            MaterialButtonStyle(foregroundColor: .onSurfaceColor.opacity(0.6))
        )
        .transformEffect(.identity)
    }
}
