//
//  CurrentLocationRepository.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct CurrentLocationRepositoryProviderKey: InjectionKey {
    static var currentValue: CurrentLocationRepository = CurrentLocationRepository()
}

extension InjectedValues {
    var currentLocationRepository: CurrentLocationRepository {
        get { Self[CurrentLocationRepositoryProviderKey.self] }
        set { Self[CurrentLocationRepositoryProviderKey.self] = newValue }
    }
}

class CurrentLocationRepository: ObservableObject {
    @Injected(\.currentLocationLocalDataSource)
    var localDataSource: CurrentLocationLocalDataSource
    
    func getLastLocation() -> CLLocation? {
        localDataSource.getLastLocation()
    }
    
    func observeLastLocation() -> Published<CLLocation?>.Publisher {
        localDataSource.observeLastLocation()
    }
}
