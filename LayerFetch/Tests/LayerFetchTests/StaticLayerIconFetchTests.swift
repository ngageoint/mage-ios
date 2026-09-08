// 
//     
//  StaticLayerIconFetchTests.swift
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

struct StaticLayerIconFetchTests {
    
    let sut: any StaticLayerIconFetch
    
    init() {
        sut = StaticLayerIconFetchImpl()
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/testkmlicon.png",
            responseFile: "icon27.png",
            ignoreSpecialHeader: true
        )
    )
    func fetchReturnsLayersFromServer() async throws {
        let uuid = UUID()
        let icons: [StaticLayerIconLocation] = [
            .init(
                url: URL(string: "https://magetest/testkmlicon.png")!,
                layerID: LayerID(2),
                featureID: StaticLayerFeatureID(
                    "feature\(uuid.uuidString)"
                )
            )
        ]
        
        let featureIconRelativePath = "featureIcons/\(icons.first!.layerID.rawValue)/\(icons.first!.featureID.rawValue)"
        let featureIconPath = "\(getDocumentsDirectory())/\(featureIconRelativePath)"
        
        try? FileManager.default.removeItem(atPath: featureIconPath)
        
        try await sut.fetch(iconsToFetch: icons) { progress in
            
        }
        
        #expect(FileManager.default.fileExists(atPath: featureIconPath))
        try? FileManager.default.removeItem(atPath: featureIconPath)
    }
    
    func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
    
}
