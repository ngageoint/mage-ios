//
//  LayerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/10/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs

@testable import MAGE
import CoreData

class LayerTests: KIFSpec {
    
    override func spec() {
        
        var staticLayerObserver: AnyObject?
    
        xdescribe("Layer Tests") {
            
            beforeEach {
                var cleared = false;
                while (!cleared) {
                    let clearMap = TestHelpers.clearAndSetUpStack()
                    cleared = (clearMap[String(describing: Layer.self)] ?? false)
                    
                    if (!cleared) {
                        cleared = Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0
                    }
                    
                    if (!cleared) {
                        Thread.sleep(forTimeInterval: 0.5);
                    }
                    
                }
                
                if let staticLayerObserver = staticLayerObserver {
                    NotificationCenter.default.removeObserver(staticLayerObserver, name: .StaticLayerLoaded, object: nil)
                }
                
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Layers still exist in default");
                
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_rootSaving())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Layers still exist in root");
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                NSManagedObject.mr_setDefaultBatchSize(0);
            }
            
            afterEach {
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("should pull a GeoPackage layer") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.type.key: "GeoPackage",
                        LayerKey.file.key: [
                            LayerFileKey.name.key:"geopackage.gpkg",
                            LayerFileKey.contentType.key: "application/octet-stream",
                            LayerFileKey.size.key: "303104"
                        ]
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("GeoPackage"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).toNot(beNil());
                expect(layer.file![LayerFileKey.name.key] as? String).to(equal("geopackage.gpkg"))
                expect(layer.file![LayerFileKey.contentType.key] as? String).to(equal("application/octet-stream"))
                expect(layer.file![LayerFileKey.size.key] as? String).to(equal("303104"))
                expect(layer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_NOT_DOWNLOADED)))
            }
            
            it("should pull a GeoPackage layer and download it") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.type.key: "GeoPackage",
                        LayerKey.file.key: [
                            LayerFileKey.name.key:"geopackage.gpkg",
                            LayerFileKey.contentType.key: "application/octet-stream",
                            LayerFileKey.size.key: "303104"
                        ]
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("GeoPackage"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).toNot(beNil());
                expect(layer.file![LayerFileKey.name.key] as? String).to(equal("geopackage.gpkg"))
                expect(layer.file![LayerFileKey.contentType.key] as? String).to(equal("application/octet-stream"))
                expect(layer.file![LayerFileKey.size.key] as? String).to(equal("303104"))
                expect(layer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_NOT_DOWNLOADED)))
                
                
                var geopackageStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1")
                ) { (request) -> HTTPStubsResponse in
                    geopackageStubCalled = true;
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/octet-stream"]);
                }
                
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0] as String
                if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/geopackages/1/geopackage_1_from_server.gpkg")) {
                    do {
                        try FileManager.default.removeItem(atPath: "\(documentsDirectory)/geopackages/1/geopackage_1_from_server.gpkg")
                    } catch {}
                }
                
                var notificationReceived = false;
                NotificationCenter.default.addObserver(forName: .GeoPackageDownloaded, object: nil, queue: nil) { notification in
                    expect(notification.userInfo!["filePath"] as? String).to(equal("\(documentsDirectory)/geopackages/1/geopackage_1_from_server.gpkg"));
                    expect(notification.userInfo!["layerId"] as? NSNumber).to(equal(1));
                    notificationReceived = true;
                }
                
                var successfulDownload = false;
                Layer.downloadGeoPackage(layer: layer) {
                    successfulDownload = true;
                    
                } failure: { error in
                    expect(true).to(beFalse()); // force a failure
                }
                
                expect(geopackageStubCalled).toEventually(beTrue());
                expect(successfulDownload).toEventually(beTrue());
                expect(notificationReceived).toEventually(beTrue());
                expect(Layer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.downloadedBytes ).toEventually(beGreaterThan(NSNumber(0)), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
            }
            
            it("should pull a GeoPackage layer and re-download it") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.type.key: "GeoPackage",
                        LayerKey.file.key: [
                            LayerFileKey.name.key:"geopackage.gpkg",
                            LayerFileKey.contentType.key: "application/octet-stream",
                            LayerFileKey.size.key: "303104"
                        ]
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("GeoPackage"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).toNot(beNil());
                expect(layer.file![LayerFileKey.name.key] as? String).to(equal("geopackage.gpkg"))
                expect(layer.file![LayerFileKey.contentType.key] as? String).to(equal("application/octet-stream"))
                expect(layer.file![LayerFileKey.size.key] as? String).to(equal("303104"))
                expect(layer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_NOT_DOWNLOADED)))
                
                
                var geopackageStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1")
                ) { (request) -> HTTPStubsResponse in
                    geopackageStubCalled = true;
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/octet-stream"]);
                }
                
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0] as String
                if (!FileManager.default.fileExists(atPath: "\(documentsDirectory)/geopackages/1/geopackage_1_from_server.gpkg")) {
                    FileManager.default.createFile(atPath: "\(documentsDirectory)/geopackages/1/geopackage_1_from_server.gpkg", contents: Data(base64Encoded: "A"), attributes: nil)
                }
                
                var notificationReceived = false;
                NotificationCenter.default.addObserver(forName: .GeoPackageDownloaded, object: nil, queue: nil) { notification in
                    expect(notification.userInfo!["filePath"] as? String).to(equal("\(documentsDirectory)/geopackages/1/geopackage_1_from_server.gpkg"));
                    expect(notification.userInfo!["layerId"] as? NSNumber).to(equal(1));
                    notificationReceived = true;
                }
                
                var successfulDownload = false;
                Layer.downloadGeoPackage(layer: layer) {
                    successfulDownload = true;

                } failure: { error in
                    expect(true).to(beFalse()); // force a failure
                }
                
                expect(geopackageStubCalled).toEventually(beTrue());
                expect(successfulDownload).toEventually(beTrue());
                expect(notificationReceived).toEventually(beTrue());
                expect(Layer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.downloadedBytes ).toEventually(beGreaterThan(NSNumber(0)), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
            }
            
            it("should pull a GeoPackage layer that already exists in a different event") {
                var stubCalled = false;
                var stubCalledEvent2 = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.type.key: "GeoPackage",
                        LayerKey.file.key: [
                            LayerFileKey.name.key:"geopackage.gpkg",
                            LayerFileKey.contentType.key: "application/octet-stream",
                            LayerFileKey.size.key: "303104"
                        ]
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/2/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalledEvent2 = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.type.key: "GeoPackage",
                        LayerKey.file.key: [
                            LayerFileKey.name.key:"geopackage.gpkg",
                            LayerFileKey.contentType.key: "application/octet-stream",
                            LayerFileKey.size.key: "303104"
                        ]
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("GeoPackage"))
                expect(layer.file).toNot(beNil());
                expect(layer.eventId).to(equal(1))
                expect(layer.file![LayerFileKey.name.key] as? String).to(equal("geopackage.gpkg"))
                expect(layer.file![LayerFileKey.contentType.key] as? String).to(equal("application/octet-stream"))
                expect(layer.file![LayerFileKey.size.key] as? String).to(equal("303104"))
                expect(layer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_NOT_DOWNLOADED)))
                
                // pretend we loaded it
                MagicalRecord.save(blockAndWait: { context in
                    let locallayer = layer.mr_(in: context);
                    locallayer?.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_LOADED)
                })
                
                Layer.refreshLayers(eventId: 2);
                
                expect(stubCalledEvent2).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer2 = Layer.mr_findFirst(byAttribute: "eventId", withValue: 2)!;
                expect(layer2.remoteId).to(equal(1))
                expect(layer2.name).to(equal("name"))
                expect(layer2.type).to(equal("GeoPackage"))
                expect(layer2.file).toNot(beNil());
                expect(layer2.eventId).to(equal(2))
                expect(layer2.file![LayerFileKey.name.key] as? String).to(equal("geopackage.gpkg"))
                expect(layer2.file![LayerFileKey.contentType.key] as? String).to(equal("application/octet-stream"))
                expect(layer2.file![LayerFileKey.size.key] as? String).to(equal("303104"))
                expect(layer2.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
            }
            
            it("should pull a GeoPackage layer then pull a new set and delete the old one") {
                var stubCalled = 0;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = stubCalled + 1;
                    if stubCalled == 1 {
                        return HTTPStubsResponse(jsonObject: [[
                            LayerKey.id.key: 1,
                            LayerKey.name.key: "name",
                            LayerKey.type.key: "GeoPackage",
                            LayerKey.file.key: [
                                LayerFileKey.name.key:"geopackage.gpkg",
                                LayerFileKey.contentType.key: "application/octet-stream",
                                LayerFileKey.size.key: "303104"
                            ]
                        ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                    } else {
                        return HTTPStubsResponse(jsonObject: [[
                            LayerKey.id.key: 2,
                            LayerKey.name.key: "two",
                            LayerKey.type.key: "GeoPackage",
                            LayerKey.file.key: [
                                LayerFileKey.name.key:"geopackage.gpkg",
                                LayerFileKey.contentType.key: "application/octet-stream",
                                LayerFileKey.size.key: "303104"
                            ]
                        ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                    }
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(equal(1));
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst(in: NSManagedObjectContext.mr_default())!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("GeoPackage"))
                expect(layer.file).toNot(beNil());
                expect(layer.eventId).to(equal(1))
                expect(layer.file![LayerFileKey.name.key] as? String).to(equal("geopackage.gpkg"))
                expect(layer.file![LayerFileKey.contentType.key] as? String).to(equal("application/octet-stream"))
                expect(layer.file![LayerFileKey.size.key] as? String).to(equal("303104"))
                expect(layer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_NOT_DOWNLOADED)))
                
                UserDefaults.standard.selectedOnlineLayers = ["1" : [1]]
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(equal(2));
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                expect(Layer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.remoteId).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                let layer2 = Layer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!;
                expect(layer2.remoteId).to(equal(2))
                expect(layer2.name).to(equal("two"))
                expect(layer2.type).to(equal("GeoPackage"))
                expect(layer2.file).toNot(beNil());
                expect(layer2.eventId).to(equal(1))
                expect(layer2.file![LayerFileKey.name.key] as? String).to(equal("geopackage.gpkg"))
                expect(layer2.file![LayerFileKey.contentType.key] as? String).to(equal("application/octet-stream"))
                expect(layer2.file![LayerFileKey.size.key] as? String).to(equal("303104"))
                expect(layer2.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_NOT_DOWNLOADED)))
                
                let selectedOnlineLayers = UserDefaults.standard.selectedOnlineLayers;
                expect(selectedOnlineLayers?["1"]).to(beEmpty());
            }
            
            it("should pull a Static layer") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.description.key: "description",
                        LayerKey.type.key: "Feature",
                        LayerKey.url.key: "https://magetest/api/events/1/layers",
                        LayerKey.state.key: "available"
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var featuresStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresStubCalled = true;
                    let stubPath = OHPathForFile("staticFeatures.geojson", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/testkmlicon.png")
                ) { (request) -> HTTPStubsResponse in
                    iconStubCalled = true;
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0] as String
                if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")) {
                    do {
                    try FileManager.default.removeItem(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")
                    } catch {}
                }
                
                var staticLayerLoaded = false
                staticLayerObserver = NotificationCenter.default.addObserver(forName: .StaticLayerLoaded, object: nil, queue: .main) { notification in
                    staticLayerLoaded = true
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Feature"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).to(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
                expect(layer.state).to(equal("available"))
                
                let sl = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())
                expect(sl).toNot(beNil())
                
                StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
                
                expect(featuresStubCalled).toEventually(beTrue());
                // this one is failing
                expect(staticLayerLoaded).toEventually(beTrue())
                expect(StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.data).toEventuallyNot(beNil(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                
                let staticLayer = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!
                expect(staticLayer.data).toNot(beNil());
                expect(staticLayer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
                expect(iconStubCalled).toEventually(beTrue());
                
                let staticLayerFeatures = staticLayer.data![LayerKey.features.key] as! [[AnyHashable : Any]];
                expect(staticLayerFeatures.count).to(equal(6));
                let lastFeature = staticLayerFeatures[2];
                let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
                expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
            }
            
            it("should delete static layer data") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.description.key: "description",
                        LayerKey.type.key: "Feature",
                        LayerKey.url.key: "https://magetest/api/events/1/layers",
                        LayerKey.state.key: "available"
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var featuresStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresStubCalled = true;
                    let stubPath = OHPathForFile("staticFeatures.geojson", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/testkmlicon.png")
                ) { (request) -> HTTPStubsResponse in
                    iconStubCalled = true;
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0] as String
                if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")) {
                    do {
                        try FileManager.default.removeItem(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")
                    } catch {}
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Feature"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).to(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
                expect(layer.state).to(equal("available"))
                
                let sl = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())
                expect(sl).toNot(beNil())
                
                StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
                
                expect(featuresStubCalled).toEventually(beTrue());
                
                expect(StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.data).toEventuallyNot(beNil(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                
                let staticLayer = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!
                expect(staticLayer.data).toNot(beNil());
                expect(staticLayer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
                expect(iconStubCalled).toEventually(beTrue());
                
                let staticLayerFeatures = staticLayer.data![LayerKey.features.key] as! [[AnyHashable : Any]];
                expect(staticLayerFeatures.count).to(equal(6));
                let lastFeature = staticLayerFeatures[2];
                let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
                expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
                
                staticLayer.removeStaticLayerData()
                expect(StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.data).toEventually(beNil(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                
                let staticLayerWithDeletedData = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!
                expect(staticLayerWithDeletedData.data).to(beNil());
                expect(staticLayerWithDeletedData.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_NOT_DOWNLOADED)))
            }
            
            it("should update a Static layer") {
                var stubCalled = 0;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = stubCalled + 1;
                    if stubCalled == 1 {
                        return HTTPStubsResponse(jsonObject: [[
                            LayerKey.id.key: 1,
                            LayerKey.name.key: "name",
                            LayerKey.description.key: "description",
                            LayerKey.type.key: "Feature",
                            LayerKey.url.key: "https://magetest/api/events/1/layers",
                            LayerKey.state.key: "available"
                        ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                    } else {
                        return HTTPStubsResponse(jsonObject: [[
                            LayerKey.id.key: 1,
                            LayerKey.name.key: "new name",
                            LayerKey.description.key: "new description",
                            LayerKey.type.key: "Feature",
                            LayerKey.url.key: "https://magetest/api/events/1/layers",
                            LayerKey.state.key: "available"
                        ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                    }
                }
                
                var featuresStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresStubCalled = true;
                    let stubPath = OHPathForFile("staticFeatures.geojson", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/testkmlicon.png")
                ) { (request) -> HTTPStubsResponse in
                    iconStubCalled = true;
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0] as String
                if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")) {
                    do {
                        try FileManager.default.removeItem(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")
                    } catch {}
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(equal(1));
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Feature"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).to(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
                expect(layer.state).to(equal("available"))
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(equal(2));
                
                let sl = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())
                expect(sl).toNot(beNil())
                
                StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
                
                expect(featuresStubCalled).toEventually(beTrue());
                
                expect(StaticLayer.mr_findFirst(byAttribute: "name", withValue: "new name", in: NSManagedObjectContext.mr_default())?.data).toEventuallyNot(beNil(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                
                expect(iconStubCalled).toEventually(beTrue());
                
                let staticLayer = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!
                expect(staticLayer.data).toNot(beNil());
                expect(staticLayer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
                expect(staticLayer.name).to(equal("new name"))
                expect(staticLayer.type).to(equal("Feature"))
                expect(staticLayer.layerDescription).to(equal("new description"))
                let staticLayerFeatures = staticLayer.data![LayerKey.features.key] as! [[AnyHashable : Any]];
                expect(staticLayerFeatures.count).to(equal(6));
                let lastFeature = staticLayerFeatures[2];
                let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
                expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
            }
            
            it("should remove a static layer which the server no longer provides") {
                var stubCalled = 0;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = stubCalled + 1;
                    if stubCalled == 1 {
                        return HTTPStubsResponse(jsonObject: [[
                            LayerKey.id.key: 1,
                            LayerKey.name.key: "name",
                            LayerKey.description.key: "description",
                            LayerKey.type.key: "Feature",
                            LayerKey.url.key: "https://magetest/api/events/1/layers",
                            LayerKey.state.key: "available"
                        ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                    } else {
                        return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                    }
                }
                
                var featuresStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresStubCalled = true;
                    let stubPath = OHPathForFile("staticFeatures.geojson", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/testkmlicon.png")
                ) { (request) -> HTTPStubsResponse in
                    iconStubCalled = true;
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0] as String
                if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")) {
                    do {
                        try FileManager.default.removeItem(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")
                    } catch {}
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(equal(1));
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Feature"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).to(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
                expect(layer.state).to(equal("available"))
                
                UserDefaults.standard.selectedStaticLayers = ["1" : [1]]
                
                let sl = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())
                expect(sl).toNot(beNil())
                
                StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
                
                expect(featuresStubCalled).toEventually(beTrue());
                expect(iconStubCalled).toEventually(beTrue());
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(equal(2));
                
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                
                
                let selectedStaticLayers = UserDefaults.standard.selectedStaticLayers;
                expect(selectedStaticLayers?["1"]).to(beEmpty());
            }
            
            it("should pull an Imagery layer then delete it when it is not returned form the server") {
                var stubCalled = 0;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = stubCalled + 1;
                    if stubCalled == 1 {
                        return HTTPStubsResponse(jsonObject: [[
                            LayerKey.id.key: 1,
                            LayerKey.name.key: "name",
                            LayerKey.type.key: "Imagery",
                            LayerKey.description.key: "description",
                            LayerKey.url.key: "https://magetest/layer",
                            LayerKey.format.key: "WMS",
                            LayerKey.state.key: "available",
                            LayerKey.wms.key: [
                                WMSLayerOptionsKey.format.key: "image/png",
                                WMSLayerOptionsKey.layers.key: "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14",
                                WMSLayerOptionsKey.styles.key: "",
                                WMSLayerOptionsKey.transparent.key: true,
                                WMSLayerOptionsKey.version.key: "1.3.0"
                            ]
                        ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                    } else {
                        return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                    }
                }
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(equal(1));
                expect(ImageryLayer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = ImageryLayer.mr_findFirst(in: NSManagedObjectContext.mr_default())!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Imagery"))
                expect(layer.file).to(beNil());
                expect(layer.eventId).to(equal(1))
                expect(layer.isSecure).to(beTrue())
                expect(layer.options![WMSLayerOptionsKey.format.key] as? String).to(equal("image/png"))
                expect(layer.options![WMSLayerOptionsKey.layers.key] as? String).to(equal("0,1,2,3,4,5,6,7,8,9,10,11,12,13,14"))
                expect(layer.options![WMSLayerOptionsKey.styles.key] as? String).to(equal(""))
                expect(layer.options![WMSLayerOptionsKey.transparent.key] as? Bool).to(beTrue())
                expect(layer.options![WMSLayerOptionsKey.version.key] as? String).to(equal("1.3.0"))
                
                UserDefaults.standard.selectedOnlineLayers = ["1" : [1]]
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(equal(2));
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                
                let selectedOnlineLayers = UserDefaults.standard.selectedOnlineLayers;
                expect(selectedOnlineLayers?["1"]).to(beEmpty());
            }
        }
    }
}
