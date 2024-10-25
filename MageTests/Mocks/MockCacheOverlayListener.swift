//
//  MockCacheOverlayListener.swift
//  MAGETests
//
//  Created by Dan Barela on 9/27/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

@objc final class MockCacheOverlayListener: NSObject, CacheOverlayListener {
    var updatedOverlays: [CacheOverlay]?
    var cacheOverlaysUpdatedCalled: Int = 0
    
    var updatedOverlaysWithoutBase: [CacheOverlay]? {
        guard let updatedOverlays = updatedOverlays else { return nil }
        return updatedOverlays.filter { overlay in
            !overlay.name.starts(with: "countries")
        }
    }
    
    @objc func cacheOverlaysUpdated(_ cacheOverlays: [CacheOverlay]) {
        cacheOverlaysUpdatedCalled += 1
        print("XXX overlays updated")
        for overlay in cacheOverlays {
            print("XXX overlay named \(overlay.cacheName)")
        }
        updatedOverlays = cacheOverlays
    }
}
