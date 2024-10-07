//
//  LayerLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 10/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct LayerLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: LayerLocalDataSource = LayerLocalCoreDataDataSource()
}

extension InjectedValues {
    var layerLocalDataSource: LayerLocalDataSource {
        get { Self[LayerLocalDataSourceProviderKey.self] }
        set { Self[LayerLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol LayerLocalDataSource: Actor {
    func createLoadedXYZLayer(name: String) async -> Layer?
    func markRemoteLayerNotDownloaded(remoteId: NSNumber)
    func markRemoteLayerLoaded(remoteId: NSNumber)
    func createGeoPackageLayer(name: String) async -> Layer?
    func removeOutdatedOfflineMapArchives()
    func count(eventId: NSNumber, layerId: Int) -> Int
}

actor LayerLocalCoreDataDataSource: LayerLocalDataSource {
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    func count(eventId: NSNumber, layerId: Int) -> Int {
        let count = try? context?.countOfObjects(
            Layer.self,
            predicate: NSPredicate(
                format: "eventId == %@ AND remoteId == %@", eventId, NSNumber(value:layerId)
            )
        )
        
        return count ?? 0
    }
    
    func createLoadedXYZLayer(name: String) async -> Layer? {
        if let context = context {
            return await context.perform {
                do {
                    let predicate = NSPredicate(format: "eventId == -1 AND (type == %@ OR type == %@) AND name == %@", argumentArray: ["GeoPackage", "Local_XYZ", name])
                    
                    let l = try context.fetchFirst(Layer.self, sortBy: [NSSortDescriptor(key: "eventId", ascending: true)], predicate: predicate)
                    if l == nil {
                        let l = Layer(context: context)
                        l.name = name
                        l.loaded = NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED)
                        l.type = "Local_XYZ"
                        l.eventId = -1
                        try context.obtainPermanentIDs(for: [l])
                        try context.save()
                        return l
                    }
                    return l
                } catch {
                    NSLog("Exception fetching and saving \(error)")
                }
                return nil
            }
        }
        return nil
    }
    
    func markRemoteLayerNotDownloaded(remoteId: NSNumber) {
        if let context = context {
            context.perform {
                do {
                    let layers: [Layer] = try context.fetchObjects(Layer.self, predicate: NSPredicate(format: "remoteId == %@", argumentArray: [remoteId])) ?? []
                    for layer in layers {
                        layer.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED)
                        layer.downloading = false
                    }
                    try context.save()
                } catch {
                    NSLog("Exception setting layer \(remoteId) to not downloaded \(error)")
                }
            }
        }
    }
    
    func markRemoteLayerLoaded(remoteId: NSNumber) {
        if let context = context {
            context.perform {
                do {
                    let layers: [Layer] = try context.fetchObjects(Layer.self, predicate: NSPredicate(format: "remoteId == %@", argumentArray: [remoteId])) ?? []
                    for layer in layers {
                        layer.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_LOADED)
                        layer.downloading = false
                    }
                    try context.save()
                } catch {
                    NSLog("Exception setting layer \(remoteId) to loaded \(error)")
                }
            }
        }
    }
    
    func createGeoPackageLayer(name: String) async -> Layer? {
        if let context = context {
            return await context.perform {
                do {
                    let l = Layer(context: context)
                    l.name = name
                    l.loaded = NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED)
                    l.type = "GeoPackage"
                    l.eventId = -1
                    try context.obtainPermanentIDs(for: [l])
                    try context.save()
                    return l
                } catch {
                    NSLog("Error saving local GeoPackage \(error)")
                }
                return nil
            }
        }
        return nil
    }
    
    func removeOutdatedOfflineMapArchives() {
        if let context = context {
            context.perform {
                do {
                    let layers: [Layer] = try context.fetchObjects(Layer.self, predicate: NSPredicate(format: "eventId == -1 AND (type == %@ OR type == %@)", argumentArray: ["GeoPackage", "Local_XYZ"])) ?? []
                    for layer in layers {
                        let overlay = CacheOverlays.getInstance().getByCacheName(layer.name)
                        
                        if (overlay == nil) {
                            context.delete(layer)
                        } else if let overlay = overlay as? GeoPackageCacheOverlay {
                            if !FileManager.default.fileExists(atPath: overlay.filePath) {
                                context.delete(layer)
                            }
                        }
                    }
                    try context.save()
                } catch {
                    NSLog("Exception removing layer \(error)")
                }
            }
        }
    }
}
