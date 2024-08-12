//
//  LocationRepository.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct LocationRepositorySourceProviderKey: InjectionKey {
    static var currentValue: LocationRepository = LocationRepository()
}

extension InjectedValues {
    var locationRepository: LocationRepository {
        get { Self[LocationRepositorySourceProviderKey.self] }
        set { Self[LocationRepositorySourceProviderKey.self] = newValue }
    }
}

class LocationRepository: ObservableObject {
    @Injected(\.locationLocalDataSource)
    var localDataSource: LocationLocalDataSource
    
    func locations(
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        localDataSource.locations(paginatedBy: paginator)
    }
    
    func getLocation(locationUri: URL) async -> LocationModel? {
        await localDataSource.getLocation(uri: locationUri)
    }
    
    func observeLocation(locationUri: URL) -> AnyPublisher<LocationModel, Never>? {
        localDataSource.observeLocation(locationUri: locationUri)
    }
}
