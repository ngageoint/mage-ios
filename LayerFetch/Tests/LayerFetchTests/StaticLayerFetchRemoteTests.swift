// 
//     
//  StaticLayerFetchRemoteTests.swift
//  LayerFetch
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

struct StaticLayerFetchRemoteTests {
    
    let sut: any StaticLayerFetchRemote
    
    init() {
        sut = StaticLayerFetchRemoteImpl(
            url: URL(string: "https://magetest")!,
            session: TestAPISession()
        )
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/layers/2/features",
            responseFile: "staticFeatures.geojson"
        )
    )
    func fetchReturnsLayersFromServer() async throws {
        let request = try LayerFetchRouter(
            baseURL: URL(string: "https://magetest")!,
            endpoint: .fetchStaticLayerData(eventID: EventID(1), layerID: LayerID(2))
        ).asURLRequest()
        let layers = try await sut.fetch(urlRequest: request) { progress in
        }
        
        #expect(layers.count == 1)
        let first = try #require(layers.first)
        #expect(first.features.count == 6)
        
    }
}

