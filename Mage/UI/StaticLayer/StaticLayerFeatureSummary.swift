//
//  StaticLayerFeatureSummary.swift
//  MAGE
//
//  Created by Dan Barela on 7/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Kingfisher
import MAGEStyle

struct StaticLayerFeatureSummary: View {
    var featureItem: FeatureItem
    
    // we do not want the date to word break so we replace all spaces with a non word breaking spaces
    var timeText: String {
        if let itemDate: NSDate = featureItem.featureDate as NSDate? {
            return itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        return ""
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(timeText)")
                    .overlineText()
                
                if let featureTitle = featureItem.featureTitle {
                    Text(featureTitle)
                        .primaryText()
                }
                
                if let layerName = featureItem.layerName {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .resizable()
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                            .frame(width: 14, height: 14)
                        Text(layerName)
                            .secondaryText()
                    }
                }
                
                if let featureDetail = featureItem.featureDetail {
                    Text(featureDetail)
                        .secondaryText()
                }
            }
            Spacer()

            if let iconURL = featureItem.iconURL {
                KFImage(iconURL)
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                    .forceRefresh()
                    .cacheOriginalImage()
                    .downsampling(size: CGSize(width: 48, height: 48))
                    .onlyFromCache(DataConnectionUtilities.shouldFetchAvatars())
                    .placeholder {
                        Image("observations")
                            .resizable()
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                            .frame(width: 48, height: 48)
                    }
                    .fade(duration: 0.3)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerSize: CGSizeMake(5, 5)))
            }
        }
        .padding()
    }
}
