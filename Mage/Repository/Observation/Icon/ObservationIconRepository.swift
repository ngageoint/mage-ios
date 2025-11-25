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
            Task {
                await self.resetEventIconSize(eventId: Int(truncating: currentEventId))
            }
        }
    }

    func getMaximumIconHeightToWidthRatio(eventId: Int) async -> CGSize {
        await localDataSource.getMaximumIconHeightToWidthRatio(eventId: eventId)
    }
    
    func resetEventIconSize(eventId: Int) async {
        await localDataSource.resetEventIconSize(eventId: eventId)
    }
}
