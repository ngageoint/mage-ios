//
//  ObservationLocationRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/6/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct ObservationLocationRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationLocationRepository = ObservationLocationRepository()
}

extension InjectedValues {
    var observationLocationRepository: ObservationLocationRepository {
        get { Self[ObservationLocationRepositoryProviderKey.self] }
        set { Self[ObservationLocationRepositoryProviderKey.self] = newValue }
    }
}

class ObservationLocationRepository: ObservableObject {
    @Injected(\.observationLocationLocalDataSource)
    var localDataSource: ObservationLocationLocalDataSource
    
    func getObservationLocation(observationLocationUri: URL?) async -> ObservationLocation? {
        await localDataSource.getObservationLocation(observationLocationUri: observationLocationUri)
    }
    
    func observeObservationLocation(observationLocationUri: URL?) -> AnyPublisher<ObservationMapItem, Never>? {
        localDataSource.observeObservationLocation(observationLocationUri: observationLocationUri)
    }
    
    func getObservationMapItems(observationUri: URL, formId: String, fieldName: String) async -> [ObservationMapItem]? {
        await localDataSource.getObservationMapItems(
            observationUri: observationUri,
            formId: formId,
            fieldName: fieldName
        )
    }
}
