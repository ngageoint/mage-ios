//
//  ObservationMapItemRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 4/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct ObservationMapItemRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationMapItemRepository = ObservationMapItemRepository()
}

extension InjectedValues {
    var observationMapItemRepository: ObservationMapItemRepository {
        get { Self[ObservationMapItemRepositoryProviderKey.self] }
        set { Self[ObservationMapItemRepositoryProviderKey.self] = newValue }
    }
}

class ObservationMapItemRepository: ObservableObject {
    @Injected(\.observationLocationLocalDataSource)
    var localDataSource: ObservationLocationLocalDataSource

    func getMapItems(observationUri: URL?) async -> [ObservationMapItem] {
        return await localDataSource.getMapItems(
            observationUri: observationUri,
            minLatitude: nil,
            maxLatitude: nil,
            minLongitude: nil,
            maxLongitude: nil
        )
    }
}
