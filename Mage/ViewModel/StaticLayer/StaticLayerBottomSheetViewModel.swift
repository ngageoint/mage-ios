//
//  StaticLayerBottomSheetViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class StaticLayerBottomSheetViewModel: ObservableObject {
    @Injected(\.staticLayerRepository)
    var repository: StaticLayerRepository
    
    @Published
    var featureItem: FeatureItem
    
    init(featureItem: FeatureItem) {
        self.featureItem = featureItem
    }
}
