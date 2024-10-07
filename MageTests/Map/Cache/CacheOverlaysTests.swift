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
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
    }
    
    func testUnregisterListener() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        await CacheOverlays.getInstance().unregisterListener(mockListener)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz2", andDirectory: "directory2")])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
    }
    
    func testSetCacheOverlays() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
                
        await CacheOverlays.getInstance().addCacheOverlay(overlay: XYZDirectoryCacheOverlay(name: "xyz2", andDirectory: "directory2"))
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 2)
        
        XCTAssertEqual(CacheOverlays.getInstance().count(), 2)
        
        XCTAssertEqual(CacheOverlays.getInstance().atIndex(index: 0)?.getName(), "xyz")
        XCTAssertEqual(CacheOverlays.getInstance().atIndex(index: 1)?.getName(), "xyz2")
        
        await CacheOverlays.getInstance().setCacheOverlays(overlays: [XYZDirectoryCacheOverlay(name: "xyz3", andDirectory: "directory3")])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 4)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        XCTAssertEqual(CacheOverlays.getInstance().count(), 1)
    }
    
    func testUpdateOverlay() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        let overlay1 = XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")!
        overlay1.enabled = true
        await CacheOverlays.getInstance().add([overlay1])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
                
        let overlay = XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")!
        overlay.added = true
        XCTAssertFalse(overlay.enabled)
        await CacheOverlays.getInstance().addCacheOverlay(overlay: overlay)
        XCTAssertTrue(overlay.enabled)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        overlay.replaced = overlay1
        
        let overlay3 = XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")!
        overlay3.added = true
        XCTAssertFalse(overlay3.enabled)
        XCTAssertNil(overlay3.replaced)
        await CacheOverlays.getInstance().addCacheOverlay(overlay: overlay3)
        XCTAssertTrue(overlay3.enabled)
        XCTAssertNotNil(overlay3.replaced)
        
        XCTAssertEqual(CacheOverlays.getInstance().count(), 1)
    }
    
    func testRemoveByCacheName() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
                
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz2", andDirectory: "directory2")])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 2)
        XCTAssertEqual(CacheOverlays.getInstance().count(), 2)
        
        XCTAssertNotNil(CacheOverlays.getInstance().getByCacheName("xyz"))
        XCTAssertNotNil(CacheOverlays.getInstance().getByCacheName("xyz2"))
        
        await CacheOverlays.getInstance().remove(byCacheName: "xyz2")
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 4)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        XCTAssertNotNil(CacheOverlays.getInstance().getByCacheName("xyz"))
        XCTAssertNil(CacheOverlays.getInstance().getByCacheName("xyz2"))
        XCTAssertEqual(CacheOverlays.getInstance().count(), 1)
    }
    
    func testRemoveByOverlay() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")])

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
                
        let cache2 = XYZDirectoryCacheOverlay(name: "xyz2", andDirectory: "directory2")!
        await CacheOverlays.getInstance().add([cache2])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 2)
        XCTAssertEqual(CacheOverlays.getInstance().count(), 2)
        
        XCTAssertNotNil(CacheOverlays.getInstance().getByCacheName("xyz"))
        XCTAssertNotNil(CacheOverlays.getInstance().getByCacheName("xyz2"))
        
        await CacheOverlays.getInstance().removeCacheOverlay(overlay: cache2)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 4)
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        XCTAssertNotNil(CacheOverlays.getInstance().getByCacheName("xyz"))
        XCTAssertNil(CacheOverlays.getInstance().getByCacheName("xyz2"))
        
        XCTAssertEqual(CacheOverlays.getInstance().count(), 1)
    }
    
    func testProcessing() async {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 1)
        
        await CacheOverlays.getInstance().addProcessing(name: "xyz")

        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 2)
        XCTAssertEqual(CacheOverlays.getInstance().getProcessing().count, 1)
        XCTAssertEqual(CacheOverlays.getInstance().getProcessing().first!, "xyz")
                
        let cache2 = XYZDirectoryCacheOverlay(name: "xyz2", andDirectory: "directory2")!
        await CacheOverlays.getInstance().addProcessing(from: [cache2.getName()!])
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 3)
        XCTAssertEqual(CacheOverlays.getInstance().getProcessing().count, 2)
        XCTAssertEqual(CacheOverlays.getInstance().getProcessing().first!, "xyz")
        XCTAssertEqual(CacheOverlays.getInstance().getProcessing()[1] , "xyz2")
        
        await CacheOverlays.getInstance().removeProcessing(cache2.getName()!)
        
        XCTAssertEqual(mockListener.cacheOverlaysUpdatedCalled, 4)
        XCTAssertEqual(CacheOverlays.getInstance().getProcessing().count, 1)
        XCTAssertEqual(CacheOverlays.getInstance().getProcessing().first!, "xyz")
    }
    
    func testGetOverlaysXYZ() async {
        // XYZ layers are never downloaded so they should always be returned
        await CacheOverlays.getInstance().add([XYZDirectoryCacheOverlay(name: "xyz", andDirectory: "directory")])

        var overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 1)
                
        let cache2 = XYZDirectoryCacheOverlay(name: "xyz2", andDirectory: "directory2")!
        await CacheOverlays.getInstance().add([cache2])

        overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 2)
        
        var name = await CacheOverlays.getInstance().getOverlays()[0].getName()
        XCTAssertEqual(name!, "xyz")
        name = await CacheOverlays.getInstance().getOverlays()[1].getName()
        XCTAssertEqual(name!, "xyz2")
        
        await CacheOverlays.getInstance().removeCacheOverlay(overlay: cache2)
        
        overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 1)
        
        name = await CacheOverlays.getInstance().getOverlays()[0].getName()
        XCTAssertEqual(name!, "xyz")
        
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
        let gpCache = GeoPackageCacheOverlay(name: "gp1", andPath: path, andTables: [])!
        await CacheOverlays.getInstance().add([gpCache])

        Server.setCurrentEventId(2)
        var overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 0)
        
        Server.setCurrentEventId(1)
        overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 1)
        
        let path2 = "\(documentsDirectory)/MapCache/gpkgWithMedia.gpkg"
        let gpCache2 = GeoPackageCacheOverlay(name: "gp2", andPath: path2, andTables: [])!
        await CacheOverlays.getInstance().add([gpCache2])
        
        overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 2)
    }
}
