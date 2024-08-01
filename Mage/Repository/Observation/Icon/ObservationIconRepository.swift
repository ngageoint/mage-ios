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
    
    init() {
        if let currentEventId = Server.currentEventId() {
            self.resetEventIconSize(eventId: Int(truncating: currentEventId))
        }
    }

//    func getIconPath(observationUri: URL) async -> String? {
//        await localDataSource.getIconPath(observationUri: observationUri)
//    }
//
//    func getIconPath(observation: Observation) -> String? {
//        localDataSource.getIconPath(observation: observation)
//    }

    func getMaximumIconHeightToWidthRatio(eventId: Int) async -> CGSize {
        await localDataSource.getMaximumIconHeightToWidthRatio(eventId: eventId)
    }
    
    func resetEventIconSize(eventId: Int) {
        localDataSource.resetEventIconSize(eventId: eventId)
    }
}
