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
    static var currentValue: ObservationLocationRepository = ObservationLocationRepositoryImpl()
}

extension InjectedValues {
    var observationLocationRepository: ObservationLocationRepository {
        get { Self[ObservationLocationRepositoryProviderKey.self] }
        set { Self[ObservationLocationRepositoryProviderKey.self] = newValue }
    }
}

protocol ObservationLocationRepository {
    func getObservationLocation(observationLocationUri: URL?) async -> ObservationMapItem?
    func observeObservationLocation(observationLocationUri: URL?) -> AnyPublisher<ObservationMapItem, Never>?
    func getObservationMapItems(observationUri: URL, formId: String, fieldName: String) async -> [ObservationMapItem]?
}

class ObservationLocationRepositoryImpl: ObservableObject, ObservationLocationRepository {
    @Injected(\.observationLocationLocalDataSource)
    var localDataSource: ObservationLocationLocalDataSource
    
    func getObservationLocation(observationLocationUri: URL?) async -> ObservationMapItem? {
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
