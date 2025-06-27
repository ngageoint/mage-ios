//
//  FavoriteButton.swift
//  MAGE
//
//  Created by Dan Barela on 7/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct FavoriteButton: View {
    var favoriteCount: Int?
    var currentUserFavorite: Bool
    var favoriteAction: ObservationActions
    
    var body: some View {
        Button {
            favoriteAction()
        } label: {
            Label {
                if let count = favoriteCount, count != 0 {
                    Text("\(count)").padding(.leading, 8)
                }
            } icon: {
                if currentUserFavorite {
                    Image(
                        uiImage: UIImage(
                            systemName: "heart.fill",
                            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))!
                            .aspectResize(to: CGSize(width: 24, height: 24))
                            .withRenderingMode(.alwaysTemplate)
                    )
                } else {
                    Image(
                        uiImage: UIImage(
                            systemName: "heart",
                            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))!
                            .aspectResize(to: CGSize(width: 24, height: 24))
                            .withRenderingMode(.alwaysTemplate)
                    )
                }
            }
            
        }
        .transformEffect(.identity)
    }
}
