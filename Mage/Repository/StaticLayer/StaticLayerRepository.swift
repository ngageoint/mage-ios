//
//  StaticLayerRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/24/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct StaticLayerRepositoryProviderKey: InjectionKey {
    static var currentValue: StaticLayerRepository = StaticLayerRepository()
}

extension InjectedValues {
    var staticLayerRepository: StaticLayerRepository {
        get { Self[StaticLayerRepositoryProviderKey.self] }
        set { Self[StaticLayerRepositoryProviderKey.self] = newValue }
    }
}

class StaticLayerRepository: ObservableObject {
    @Injected(\.staticLayerLocalDataSource)
    var localDataSource: StaticLayerLocalDataSource
    
    func getStaticLayer(remoteId: NSNumber?, eventId: NSNumber?) -> StaticLayer? {
        localDataSource.getStaticLayer(remoteId: remoteId, eventId: eventId)
    }
    
    func getStaticLayer(remoteId: NSNumber?) -> StaticLayer? {
        localDataSource.getStaticLayer(remoteId: remoteId)
    }
}
