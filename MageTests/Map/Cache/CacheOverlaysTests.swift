//
//  CacheOverlaysTests.swift
//  MAGETests
//
//  Created by Dan Barela on 10/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import geopackage_ios

@testable import MAGE

final class CacheOverlaysTests: MageCoreDataTestCase {
    
    override func tearDown() async throws {
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
        await CacheOverlays.getInstance().removeAll()
        try await super.tearDown()
    }
    
    override func setUp() async throws {
        try await super.setUp()
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
        await CacheOverlays.getInstance().removeAll()
    }
    
    func testRegisterListener() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
    }
    
    func testNotifyExceptCaller() async {
        let mockListener = MockCacheOverlayListener()
        let mockListener2 = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        await CacheOverlays.getInstance().register(mockListener2)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        XCTAssertEqual(mockListener2.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().notifyListenersExceptCaller(caller: mockListener2)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener2.cacheOverlaysUpdatedCalled, 1)
    }
    
    func testAddOverlay() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
    }
    
    func testUnregisterListener() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        await CacheOverlays.getInstance().unregisterListener(mockListener)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz2", directory: "directory2")])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
    }
    
    func testSetCacheOverlays() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
                
        await CacheOverlays.getInstance().addCacheOverlay(overlay: XYZDirectoryCacheOverlay(name: "xyz2", directory: "directory2"))
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 2)
        
        let count = await CacheOverlays.getInstance().count()
        XCTAssertEqual(count, 2)
        
        let overlay0 = await CacheOverlays.getInstance().atIndex(index: 0)?.name
        let overlay1 = await CacheOverlays.getInstance().atIndex(index: 1)?.name
        XCTAssertEqual(overlay0, "xyz")
        XCTAssertEqual(overlay1, "xyz2")
        
        await CacheOverlays.getInstance().setCacheOverlays(overlays: [XYZDirectoryCacheOverlay(name: "xyz3", directory: "directory3")])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 4)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        let countAfter = await CacheOverlays.getInstance().count()
        XCTAssertEqual(countAfter, 1)
    }
    
    func testUpdateOverlay() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        let overlay1 = XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")
        overlay1.enabled = true
        await CacheOverlays.getInstance().add([overlay1])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
                
        let overlay = XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")
        overlay.added = true
        XCTAssertFalse(overlay.enabled)
        await CacheOverlays.getInstance().addCacheOverlay(overlay: overlay)
        XCTAssertTrue(overlay.enabled)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        overlay.replaced = overlay1
        
        let overlay3 = XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")
        overlay3.added = true
        XCTAssertFalse(overlay3.enabled)
        XCTAssertNil(overlay3.replaced)
        await CacheOverlays.getInstance().addCacheOverlay(overlay: overlay3)
        XCTAssertTrue(overlay3.enabled)
        XCTAssertNotNil(overlay3.replaced)
        
        let countAfter = await CacheOverlays.getInstance().count()
        XCTAssertEqual(countAfter, 1)
    }
    
    func testRemoveByCacheName() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
                
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz2", directory: "directory2")])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 2)
        
        let count = await CacheOverlays.getInstance().count()
        XCTAssertEqual(count, 2)
        
        let overlay0 = await CacheOverlays.getInstance().getByCacheName("xyz")
        let overlay1 = await CacheOverlays.getInstance().getByCacheName("xyz2")
        XCTAssertEqual(overlay0?.name, "xyz")
        XCTAssertEqual(overlay1?.name, "xyz2")

        
        await CacheOverlays.getInstance().remove(byCacheName: "xyz2")
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 4)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        let remainingOverlay = await CacheOverlays.getInstance().getByCacheName("xyz")
        let removedOverlay = await CacheOverlays.getInstance().getByCacheName("xyz2")
        
        XCTAssertNotNil(remainingOverlay)
        XCTAssertNil(removedOverlay)
        
        let countAfter = await CacheOverlays.getInstance().count()
        XCTAssertEqual(countAfter, 1)
    }
    
    func testRemoveByOverlay() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
                
        let cache2 = XYZDirectoryCacheOverlay(name: "xyz2", directory: "directory2")
        await CacheOverlays.getInstance().add([cache2])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 2)

        let count = await CacheOverlays.getInstance().count()
        XCTAssertEqual(count, 2)
        
        let overlay0 = await CacheOverlays.getInstance().getByCacheName("xyz")
        let overlay1 = await CacheOverlays.getInstance().getByCacheName("xyz2")
        XCTAssertNotNil(overlay0)
        XCTAssertNotNil(overlay1)
        
        await CacheOverlays.getInstance().removeCacheOverlay(overlay: cache2)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 4)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        let overlay3 = await CacheOverlays.getInstance().getByCacheName("xyz")
        let overlay4 = await CacheOverlays.getInstance().getByCacheName("xyz2")
        XCTAssertNotNil(overlay3)
        XCTAssertNil(overlay4)
        
        let countAfter = await CacheOverlays.getInstance().count()
        XCTAssertEqual(countAfter, 1)
    }
    
    func testProcessing() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().addProcessing(name: "xyz")

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        let count1 = await CacheOverlays.getInstance().getProcessing().count
        XCTAssertEqual(count1, 1)

        let overlay1 = await CacheOverlays.getInstance().getProcessing().first!
        XCTAssertEqual(overlay1, "xyz")
                
        let cache2 = XYZDirectoryCacheOverlay(name: "xyz2", directory: "directory2")
        await CacheOverlays.getInstance().addProcessing(from: [cache2.name])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        
        let count2 = await CacheOverlays.getInstance().getProcessing().count
        XCTAssertEqual(count2, 2)

        let overlay2 = await CacheOverlays.getInstance().getProcessing()[0]
        let overlay3 = await CacheOverlays.getInstance().getProcessing()[1]
        XCTAssertEqual(overlay2, "xyz")
        XCTAssertEqual(overlay3, "xyz2")
        
        await CacheOverlays.getInstance().removeProcessing(cache2.name)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 4)
        let overlay4 = await CacheOverlays.getInstance().getProcessing().first!
        XCTAssertEqual(overlay4, "xyz")

        let count3 = await CacheOverlays.getInstance().getProcessing().count
        XCTAssertEqual(count3, 1)
    }
    
    func testGetOverlaysXYZ() async {
        // XYZ layers are never downloaded so they should always be returned
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", directory: "directory")])

        var overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 1)
                
        let cache2 = XYZDirectoryCacheOverlay(name: "xyz2", directory: "directory2")
        await CacheOverlays.getInstance().add([cache2])

        overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 2)
        
        var name = await CacheOverlays.getInstance().getOverlays()[0].name
        XCTAssertEqual(name, "xyz")
        name = await CacheOverlays.getInstance().getOverlays()[1].name
        XCTAssertEqual(name, "xyz2")
        
        await CacheOverlays.getInstance().removeCacheOverlay(overlay: cache2)
        
        overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 1)
        
        name = await CacheOverlays.getInstance().getOverlays()[0].name
        XCTAssertEqual(name, "xyz")
        
    }
    
    func testGetOverlaysGeoPackage() async {
        context.performAndWait {
            let l = Layer(context: context)
            l.populate(["name": "gp1", "type": "geopackage", "url": "", "eventId": 1, "id": 1], eventId: 1)
            try? context.obtainPermanentIDs(for: [l])
            try? context.save()
        }
        // GeoPackage layers should be returned if they are local, or if they were downloaded AND in the current event
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let path = "\(documentsDirectory)/geopackages/1/gpkgWithMedia.gpkg"
        let gpCache = GeoPackageCacheOverlay(name: "gp1", path: path, tables: [])
        await CacheOverlays.getInstance().add([gpCache])

        Server.setCurrentEventId(2)
        var overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 0)
        
        Server.setCurrentEventId(1)
        overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 1)
        
        let path2 = "\(documentsDirectory)/MapCache/gpkgWithMedia.gpkg"
        let gpCache2 = GeoPackageCacheOverlay(name: "gp2", path: path2, tables: [])
        await CacheOverlays.getInstance().add([gpCache2])
        
        overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 2)
    }
}
