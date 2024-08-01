//
//  GeoPackageMediaView.swift
//  MAGE
//
//  Created by Dan Barela on 7/24/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import MAGEStyle

struct GeoPackageMediaView: View {
    var medias: [GeoPackageMediaRow]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(medias) { media in
                    VStack {
                        Text(media.title)
                            .overlineText()
                            .truncationMode(.tail)
                            .frame(width: 100)
                        Image(uiImage: media.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    }
                    .padding(8)
                    .overlay( /// apply a rounded border
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.onSurfaceColor.opacity(0.45), lineWidth: 1)
                    )
                }
            }
            .padding(8)
        }
    }
}
