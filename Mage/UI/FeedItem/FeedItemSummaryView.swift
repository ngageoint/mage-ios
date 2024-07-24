//
//  FeedItemSummaryView.swift
//  MAGE
//
//  Created by Dan Barela on 7/24/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Kingfisher

struct FeedItemSummaryView: View {
    var timestamp: Date?
    var primaryValue: String?
    var secondaryValue: String?
    var iconUrl: URL?
    
    // we do not want the date to word break so we replace all spaces with a non word breaking spaces
    var timeText: String {
        if let itemDate: NSDate = timestamp as NSDate? {
            return itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        return ""
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeText)
                    .overlineText()
                if let primaryValue = primaryValue {
                    Text(primaryValue)
                        .primaryText()
                }
                if let secondaryValue = secondaryValue {
                    Text(secondaryValue)
                        .secondaryText()
                }
            }
            Spacer()
            
            if let iconUrl = iconUrl {
                KFImage(iconUrl)
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                    .forceRefresh()
                    .cacheOriginalImage()
                    .downsampling(size: CGSize(width: 48, height: 48))
                    .onlyFromCache(DataConnectionUtilities.shouldFetchAvatars())
                    .placeholder {
                        Image("observations")
                            .symbolRenderingMode(.monochrome)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                            .frame(width: 48, height: 48)
                    }
                    .fade(duration: 0.3)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerSize: CGSizeMake(5, 5)))
            } else {
                Image("observations")
                    .symbolRenderingMode(.monochrome)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                    .frame(width: 48, height: 48)
            }
        }
        .padding()
    }
}
