//
//  GeoPackageFeatureSummary.swift
//  MAGE
//
//  Created by Dan Barela on 7/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import MaterialViews
import MAGEStyle

struct GeoPackageFeatureSummary: View {
    var title: String
    var date: Date?
    var secondaryTitle: String?
    var layerName: String
    var featureDetail: String?
    var icon: UIImage?
    var color: Color?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let date = date {
                    Text("\(date.formatted())")
                        .overlineText()
                }
                
                Text(title)
                    .primaryText()
                
                if let secondaryTitle = secondaryTitle {
                    Text(secondaryTitle)
                        .secondaryText()
                } else {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .resizable()
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                            .frame(width: 14, height: 14)
                        Text(layerName)
                            .secondaryText()
                    }
                }
                
                if let featureDetail = featureDetail {
                    Text(featureDetail)
                        .secondaryText()
                }
            }
            Spacer()

            if let icon = icon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                    .frame(width: 48, height: 48)
            } else {
                Image("observations")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(color ?? Color.onSurfaceColor.opacity(0.45))
            }
        }
        .padding()
    }
}
