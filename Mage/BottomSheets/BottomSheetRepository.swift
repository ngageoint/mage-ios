//
//  BottomSheetRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/6/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct BottomSheetRepositoryProviderKey: InjectionKey {
    static var currentValue: BottomSheetRepository = BottomSheetRepository()
}

extension InjectedValues {
    var bottomSheetRepository: BottomSheetRepository {
        get { Self[BottomSheetRepositoryProviderKey.self] }
        set { Self[BottomSheetRepositoryProviderKey.self] = newValue }
    }
}

class BottomSheetRepository: ObservableObject {
    @Injected(\.observationLocationRepository)
    var observationLocationRepository: ObservationLocationRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    @Injected(\.feedItemRepository)
    var feedItemRepository: FeedItemRepository
    
    @Injected(\.geoPackageRepository)
    var geoPackageRepository: GeoPackageRepository
    
    @Injected(\.featureItemRepository)
    var featureItemRepository: FeatureItemRepository
    
    private var itemKeys: [String: [String]]?
    
    @Published var bottomSheetItems: [BottomSheetItem]?
    
    func setItemKeys(itemKeys: [String: [String]]?) async {
        self.itemKeys = itemKeys
        
        guard let itemKeys = itemKeys, !itemKeys.isEmpty else {
            if self.bottomSheetItems != nil {
                self.bottomSheetItems = nil
            }
            return
        }
                
        self.bottomSheetItems = await handleItemKeys(itemKeys: itemKeys)
    }
    
    func handleItemKeys(itemKeys: [String: [String]]?) async -> [BottomSheetItem] {
        guard let itemKeys = itemKeys else { return [] }
        
        var bottomSheetItems: [BottomSheetItem] = []
        for (dataSourceKey, itemKeys) in itemKeys {
            switch (dataSourceKey) {
            case DataSources.observation.key:
                for observationLocationUriString in itemKeys {
                    if let observationLocation = await observationLocationRepository.getObservationLocation(
                        observationLocationUri: URL(string: observationLocationUriString)
                    ) {
                        bottomSheetItems.append(BottomSheetItem(item: ObservationMapItem(observation: observationLocation)))
                    }
                }
            case DataSources.user.key:
                for userUriString in itemKeys {
                    if let user = await userRepository.getUser(userUri: URL(string: userUriString)) {
                        bottomSheetItems.append(BottomSheetItem(item: user, actionDelegate: nil, annotationView: nil))
                    }
                }
            case DataSources.feedItem.key:
                for feedUriString in itemKeys {
                    if let feedItem = await feedItemRepository.getFeedItem(feedItemrUri: URL(string: feedUriString)) {
                        bottomSheetItems.append(BottomSheetItem(item: feedItem, actionDelegate: nil, annotationView: nil))
                    }
                }
            case DataSources.geoPackage.key:
                for key in itemKeys {
                    if 
                        let featureKey = GeoPackageFeatureKey.fromKey(jsonString: key),
                        let featureItem = geoPackageRepository.getGeoPackageFeatureItem(key: featureKey)
                    {
                        bottomSheetItems.append(BottomSheetItem(item: featureItem, actionDelegate: nil, annotationView: nil))
                    }
                }
            case DataSources.featureItem.key:
                for key in itemKeys {
                    if
                        let featureItem = featureItemRepository.getFeatureItem(key: key)
                    {
                        bottomSheetItems.append(BottomSheetItem(item: featureItem, actionDelegate: nil, annotationView: nil))
                    }
                }
            default:
                break
            }
        }
        return bottomSheetItems
    }
}
