//
//  AskToCacheImageView.swift
//  MAGE
//
//  Created by Dan Barela on 8/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import MaterialViews

struct AskToCacheImageView: View {
    
    @EnvironmentObject
    var router: MageRouter
    
    var imageUrl: URL
    
    var body: some View {
        VStack {
            Spacer()
            Text("Your attachment fetch settings do not allow auto downloading full size images.  Would you like to view the image?")
                .font(.body1)
                .foregroundStyle(Color.onSurfaceColor)
            Button {
                router.path.append(FileRoute.cacheImage(url: imageUrl))
            } label: {
                Text("View")
            }
            .buttonStyle(MaterialButtonStyle(type: .contained))

            Spacer()
        }
        .padding()
        .background(Color.backgroundColor)
    }
}
