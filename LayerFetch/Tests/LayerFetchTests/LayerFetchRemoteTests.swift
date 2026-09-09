// 
//     
//  LayerFetchRemoteTests.swift
//  Layer
//
// 

import Testing
import APIRouter
import ServerDTO
import Foundation
import TestUtilities
import Layer
import Pipeline
import FetchOperation

@testable import LayerFetch

struct LayerFetchRemoteTests {
    let sut: any LayerFetchRemote
    
    init() {
        sut = LayerFetchRemoteImpl(
            url: URL(string: "https://magetest")!,
            session: TestAPISession()
        )
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/layers",
            responseArray: LayerFetchRemoteTests.layerArray
        )
    )
    func fetchReturnsLayersFromServer() async throws {
        let request = try LayerFetchRouter(
            baseURL: URL(string: "https://magetest")!,
            endpoint: .fetchLayers(eventID: EventID(1))
        ).asURLRequest()
        let layers = try await sut.fetch(urlRequest: request) { progress in
        }
        
        #expect(layers.count == 2)
        
        let first = try #require(layers.first)
        #expect(first.remoteId.rawValue == 1)
        #expect(first.name == "name")
        #expect(first.type == "Imagery")
        #expect(first.layerDescription == "description")
        #expect(first.url == "https://magetest/layer")
        #expect(first.format == "WMS")
        #expect(first.state == "available")
        let firstOptions = try #require(first.options)
        #expect(firstOptions[WMSLayerOptionsKey.format.key] as? String == "image/png")
        #expect(firstOptions[WMSLayerOptionsKey.layers.key] as? String == "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14")
        #expect(firstOptions[WMSLayerOptionsKey.styles.key] as? String == "")
        #expect(firstOptions[WMSLayerOptionsKey.transparent.key] as? Bool == true)
        #expect(firstOptions[WMSLayerOptionsKey.version.key] as? String == "1.3.0")
        
        let second = try #require(layers.last)
        
        #expect(second.remoteId.rawValue == 2)
        #expect(second.name == "name2")
        #expect(second.type == "Imagery")
        #expect(second.layerDescription == "description2")
        #expect(second.url == "https://magetest/layer2")
        #expect(second.format == "WMS")
        #expect(second.state == "available")
        let secondOptions = try #require(first.options)
        #expect(secondOptions[WMSLayerOptionsKey.format.key] as? String == "image/png")
        #expect(secondOptions[WMSLayerOptionsKey.layers.key] as? String == "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14")
        #expect(secondOptions[WMSLayerOptionsKey.styles.key] as? String == "")
        #expect(secondOptions[WMSLayerOptionsKey.transparent.key] as? Bool == true)
        #expect(secondOptions[WMSLayerOptionsKey.version.key] as? String == "1.3.0")
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/layers",
            responseArray: LayerFetchRemoteTests.layerArray
        )
    )
    func fetchReportsDownloadProgress() async throws {
        actor ProgressTracker {
            var receivedProgress = false
            func updateReceived(receivedProgress: Bool) {
                self.receivedProgress = receivedProgress
            }
        }
        
        let tracker = ProgressTracker()
        let request = try LayerFetchRouter(
            baseURL: URL(string: "https://magetest")!,
            endpoint: .fetchLayers(eventID: EventID(1))
        ).asURLRequest()
        
        _ = try await sut.fetch(urlRequest: request) { progress in
            print("Progress \(progress)")
            Task { await tracker.updateReceived(receivedProgress: true) }
        }
        
        await TestUtilities.waitForCondition({
            await tracker.receivedProgress
        }, timeout: 2.0, message: "Tracker did not receive progress")
        
        #expect(await tracker.receivedProgress)
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/layers",
            statusCode: 500
        )
    )
    func fetchThrowsForServerError() async throws {
        let request = try LayerFetchRouter(
            baseURL: URL(string: "https://magetest")!,
            endpoint: .fetchLayers(eventID: EventID(1))
        ).asURLRequest()
        await #expect(throws: Error.self) {
            _ = try await sut.fetch(urlRequest: request) { _ in }
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/layers",
            responseString: "{ invalid json"
        )
    )
    func fetchThrowsForMalformedJSON() async throws {
        let request = try LayerFetchRouter(
            baseURL: URL(string: "https://magetest")!,
            endpoint: .fetchLayers(eventID: EventID(1))
        ).asURLRequest()
        await #expect(throws: Error.self) {
            _ = try await sut.fetch(urlRequest: request) { _ in }
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/layers",
            responseError: URLError(.notConnectedToInternet) as NSError
        )
    )
    func fetchThrowsUnderlyingTransportError() async throws {
        let request = try LayerFetchRouter(
            baseURL: URL(string: "https://magetest")!,
            endpoint: .fetchLayers(eventID: EventID(1))
        ).asURLRequest()
        await #expect(throws: URLError.self) {
            _ = try await sut.fetch(urlRequest: request) { _ in }
        }
    }
    
    nonisolated(unsafe) static let layerArray = [[
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
    ],[
        LayerKey.id.key: 2,
        LayerKey.name.key: "name2",
        LayerKey.type.key: "Imagery",
        LayerKey.description.key: "description2",
        LayerKey.url.key: "https://magetest/layer2",
        LayerKey.format.key: "WMS",
        LayerKey.state.key: "available",
        LayerKey.wms.key: [
            WMSLayerOptionsKey.format.key: "image/png",
            WMSLayerOptionsKey.layers.key: "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14",
            WMSLayerOptionsKey.styles.key: "",
            WMSLayerOptionsKey.transparent.key: true,
            WMSLayerOptionsKey.version.key: "1.3.0"
        ]
    ]]
}
