//
//  FeatureItemRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/24/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct FeatureItemRepositoryProviderKey: InjectionKey {
    static var currentValue: FeatureItemRepository = FeatureItemRepository()
}

extension InjectedValues {
    var featureItemRepository: FeatureItemRepository {
        get { Self[FeatureItemRepositoryProviderKey.self] }
        set { Self[FeatureItemRepositoryProviderKey.self] = newValue }
    }
}

class FeatureItemRepository: ObservableObject {
    
    func getFeatureItem(key: String) -> FeatureItem? {
        FeatureItem.fromKey(jsonString: key)
    }
}
