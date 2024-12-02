//
//  LayerRepository.swift
//  MAGE
//
//  Created by Dan Barela on 10/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct LayerRepositoryProviderKey: InjectionKey {
    static var currentValue: LayerRepository = LayerRepositoryImpl()
}

extension InjectedValues {
    var layerRepository: LayerRepository {
        get { Self[LayerRepositoryProviderKey.self] }
        set { Self[LayerRepositoryProviderKey.self] = newValue }
    }
}

protocol LayerRepository: Actor {
    func createLoadedXYZLayer(name: String) async -> Layer?
    func markRemoteLayerNotDownloaded(remoteId: NSNumber) async
    func createGeoPackageLayer(name: String) async -> Layer?
    func markRemoteLayerLoaded(remoteId: NSNumber) async
    func removeOutdatedOfflineMapArchives() async
    func count(eventId: NSNumber, layerId: Int) async -> Int
}

actor LayerRepositoryImpl: LayerRepository {
    @Injected(\.layerLocalDataSource)
    var localDataSource: LayerLocalDataSource
    
    func count(eventId: NSNumber, layerId: Int) async -> Int {
        await localDataSource.count(eventId: eventId, layerId: layerId)
    }
    
    func createLoadedXYZLayer(name: String) async -> Layer? {
        await localDataSource.createLoadedXYZLayer(name: name)
    }
    
    func createGeoPackageLayer(name: String) async -> Layer? {
        await localDataSource.createGeoPackageLayer(name: name)
    }
    
    func markRemoteLayerNotDownloaded(remoteId: NSNumber) async {
        await localDataSource.markRemoteLayerNotDownloaded(remoteId: remoteId)
    }
    
    func markRemoteLayerLoaded(remoteId: NSNumber) async {
        await localDataSource.markRemoteLayerLoaded(remoteId: remoteId)
    }
    
    func removeOutdatedOfflineMapArchives() async {
        await localDataSource.removeOutdatedOfflineMapArchives()
    }
}
