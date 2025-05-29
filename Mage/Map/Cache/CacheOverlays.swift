//
//  CacheOverlays.m
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc protocol CacheOverlayListener: NSObjectProtocol {
    @objc func cacheOverlaysUpdated(_ cacheOverlays: [CacheOverlay])
}

// TODO: This should be an actor
actor CacheOverlays: NSObject {
    @Injected(\.layerRepository)
    var layerRepository: LayerRepository
    
    static let shared = CacheOverlays()
    
    var overlays: [String: CacheOverlay] = [:]
    var overlayNames: [String] = []
    var listeners: [CacheOverlayListener] = []
    var processing: [String] = []
    
    @objc static func getInstance() -> CacheOverlays {
        shared
    }
    
    @objc func register(_ listener: CacheOverlayListener) async {
        listeners.append(listener)
        listener.cacheOverlaysUpdated(await getOverlays())
    }
    
    func unregisterListener(_ listener: CacheOverlayListener) {
        listeners.removeAll(where: { $0 === listener })
    }
    
    func setCacheOverlays(overlays: [CacheOverlay]) async {
        self.overlays = [:]
        self.overlayNames = []
        await add(overlays)
    }
    
    func add(_ overlays: [CacheOverlay]) async {
        for overlay in overlays {
            addCacheOverlayHelper(overlay: overlay)
        }
        await notifyListeners()
    }
    
    func addCacheOverlayHelper(overlay: CacheOverlay) {
        let cacheName = overlay.name
        if let existingOverlay = overlays[cacheName] {
            overlay.enabled = existingOverlay.enabled

            if overlay.added {
                overlay.replaced = existingOverlay.replaced ?? existingOverlay
            }
        } else {
            overlayNames.append(cacheName)
        }
        overlays[cacheName] = overlay
    }
    
    func addCacheOverlay(overlay: CacheOverlay) async {
        addCacheOverlayHelper(overlay: overlay)
        await notifyListeners()
    }
    
    @objc func notifyListeners() async {
        await notifyListenersExceptCaller(caller: nil)
    }
    
    @objc func notifyListenersExceptCaller(caller: (any CacheOverlayListener)?) async {
        let overlaySnapshot = await getOverlays()
        
        for listener in listeners {
            if caller == nil || !listener.isEqual(caller) {
                listener.cacheOverlaysUpdated(overlaySnapshot)
            }
        }
    }
    
    @objc func getOverlays() async -> [CacheOverlay] {
        var overlaysInCurrentEvent: [CacheOverlay] = []
        
        let sortedNames = overlayNames.sorted()
        
        for name in sortedNames {
            guard let overlay = overlays[name] else { continue }
            
            if await shouldIncludeOverlay(overlay) {
                overlaysInCurrentEvent.append(overlay)
            }
        }
        
        return overlaysInCurrentEvent
    }
    
    private func shouldIncludeOverlay(_ overlay: CacheOverlay) async -> Bool {
        // If it's a GeoPackage overlay, validate it against the current event
        if let geoOverlay = overlay as? GeoPackageCacheOverlay,
           let layerId = geoOverlay.layerId,
           let layerIdInt = Int(layerId),
           let currentEventId = Server.currentEventId()
        {
            let count = await layerRepository.count(eventId: currentEventId, layerId: layerIdInt)
            return count != 0
        }

        // All non-GeoPackage overlays are always included
        return true
    }
    
    func count() -> Int {
        overlayNames.count
    }
    
    func atIndex(index: Int) -> CacheOverlay? {
        overlays[overlayNames[index]]
    }
    
    func getByCacheName(_ cacheName: String?) -> CacheOverlay? {
        guard let cacheName = cacheName else { return nil }
        return overlays[cacheName]
    }
    
    @objc func removeCacheOverlay(overlay: CacheOverlay) async {
        await remove(byCacheName: overlay.cacheName)
    }
    
    func remove(byCacheName: String) async {
        overlays.removeValue(forKey: byCacheName)
        overlayNames.removeAll(where: { $0 == byCacheName })
        await notifyListeners()
    }
    
    func addProcessing(name: String) async {
        self.processing.append(name)
        await notifyListeners()
    }
    
    func addProcessing(from: [String]?) async {
        self.processing.append(contentsOf: from ?? [])
        await notifyListeners()
    }
    
    func removeProcessing(_ name: String) async {
        self.processing.removeAll(where: { $0 == name })
        await notifyListeners()
    }
    
    func getProcessing() -> [String] {
        processing
    }
    
    func removeAll() async {
        for overlay in overlays.values {
            await removeCacheOverlay(overlay: overlay)
        }
    }
}
