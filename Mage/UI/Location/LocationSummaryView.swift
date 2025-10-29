//
//  LocationSummaryView.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher

struct LocationSummaryView: View {
    
    @StateObject
    var viewModel: LocationSummaryViewModel
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let timeText = viewModel.timeText {
                        Text(timeText)
                            .overlineText()
                    }
                    if let userName = viewModel.location?.userModel?.name {
                        Text(userName)
                            .primaryText()
                    }
                }
                Spacer()
                if let url = URL(string: viewModel.location?.userModel?.avatarUrl ?? "") {
                    KFImage(url)
                        .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                        .forceRefresh()
                        .cacheOriginalImage()
                        .onlyFromCache(!DataConnectionUtilities.shouldFetchAttachments())
                        .placeholder {
                            Image(systemName: "person.crop.square")
                                .symbolRenderingMode(.monochrome)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                        }
                    
                        .fade(duration: 0.3)
                        .resizable()
                        .scaledToFill()
                        .frame(idealWidth: 48, maxWidth: 48, idealHeight: 48, maxHeight: 48)
                }
            }
            .padding()
            
            UserBottomSheetActionBar(
                coordinate: viewModel.location?.coordinate,
                email: viewModel.location?.userModel?.email,
                phone: viewModel.location?.userModel?.phone,
                navigateToAction: CoordinateActions.navigateTo(
                    coordinate: viewModel.location?.coordinate,
                    itemKey: viewModel.location?.userModel?.userId?.absoluteString,
                    dataSource: DataSources.user
                )
            )
        }

    }
}
