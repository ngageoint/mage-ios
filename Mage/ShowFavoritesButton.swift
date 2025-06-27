//
//  ShowFavoritesButton.swift
//  MAGE
//
//  Created by Dan Barela on 7/30/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

import SwiftUI

struct ShowFavoritesButton: View {
    var favoriteCount: Int?
    var favoriteAction: () -> Void
    
    var body: some View {
        if let count = favoriteCount, count != 0 {
            Button {
                favoriteAction()
            } label: {
                Label {
                    Text("\(count) Favorite\(count > 1 ? "s" : "")").padding(.leading, 8)
                } icon: {
                }
            }
            .transformEffect(.identity)
        }
    }
}
