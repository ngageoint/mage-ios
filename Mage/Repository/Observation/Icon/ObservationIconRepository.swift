//
//  ObservationIconRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 3/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIImageExtensions

private struct ObservationIconRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationIconRepository = ObservationIconRepository()
}

extension InjectedValues {
    var observationIconRepository: ObservationIconRepository {
        get { Self[ObservationIconRepositoryProviderKey.self] }
        set { Self[ObservationIconRepositoryProviderKey.self] = newValue }
    }
}

class ObservationIconRepository: ObservableObject {
    @Injected(\.observationIconLocalDataSource)
    var localDataSource: ObservationIconLocalDataSource

    func getIconPath(observationUri: URL) async -> String? {
        await localDataSource.getIconPath(observationUri: observationUri)
    }

    func getIconPath(observation: Observation) -> String? {
        localDataSource.getIconPath(observation: observation)
    }

    func getMaximumIconHeightToWidthRatio(eventId: Int) -> CGSize {
        localDataSource.getMaximumIconHeightToWidthRatio(eventId: eventId)
    }
}
