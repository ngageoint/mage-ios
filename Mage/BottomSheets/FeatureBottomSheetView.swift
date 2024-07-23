//
//  FeatureBottomSheetView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import MaterialViews

class StaticLayerBottomSheetViewModel: ObservableObject {
    @Injected(\.staticLayerRepository)
    var repository: StaticLayerRepository
    
    @Published
    var featureItem: FeatureItem
    
    init(featureItem: FeatureItem) {
        self.featureItem = featureItem
    }
}

struct FeatureBottomSheet: View {
    @ObservedObject
    var viewModel: StaticLayerBottomSheetViewModel
    
    var body: some View {
        Group {
            VStack(spacing: 0) {
                StaticLayerFeatureSummary(featureItem: viewModel.featureItem)
                
                StaticLayerFeatureBottomSheetActionBar(
                    coordinate: viewModel.featureItem.coordinate,
                    navigateToAction: CoordinateActions.navigateTo(
                        coordinate: viewModel.featureItem.coordinate,
                        itemKey: viewModel.featureItem.toKey(),
                        dataSource: DataSources.featureItem
                    )
                )
            }
            .id("\(viewModel.featureItem.layerName ?? "")_\(viewModel.featureItem.featureId)")
            .ignoresSafeArea()
        }
    }
}
