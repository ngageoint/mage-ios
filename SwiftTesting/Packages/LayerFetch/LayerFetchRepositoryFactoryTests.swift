// 
//     
//  LayerFetchRepositoryFactoryTests.swift
//  MAGE
//
// 


import Testing
import Persistence
import SendableExtensions
import FetchOperation
import Pipeline
import Layer
import LayerFetch
import TestUtilities
import CoreData
import APIRouter
import Alamofire

@testable import ServerDTO
@testable import LayerFetch

extension CoreDataTests {
    struct LayerFetchRepositoryFactoryTests {
        let persistence: PersistenceProtocol
        let context: NSManagedObjectContext
        let session: TokenAPISession
        
        init() {
            persistence = PersistenceContext.current!.persistence
            context = persistence.writeContext
            session = TestAPISession()
        }
                
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/layers",
                responseArray: LayerFetchRepositoryFactoryTests.layerArray
            )
        )
        func `fetch layers`() async throws {
            let repository = LayerFetchRepositoryFactory.fetchLayers(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )
            
            let operation = repository.startFetch(
                LayerFetchRequest(eventID: EventID(1))
            )
            
            let result: [MapLayerDTO] = try #require(
                try? await operation.value()
            )
            #expect(result.count == 2)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Layer.self, 2)
        }
        
        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/layers/2/features",
                responseFile: "staticFeatures.geojson"
            ),
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/testkmlicon.png",
                responseFile: "icon27.png",
                ignoreSpecialHeader: true,
                callCount: 4
            )
        )
        func `fetch static layer data`() async throws {
            let _ = try await persistence.write { context in
                let layer = StaticLayer(context: context)
                layer.remoteId = LayerID(2).rawValue
                layer.eventId = EventID(1).rawValue
                try context.obtainPermanentIDs(for: [layer])
            }
            
            let repository = LayerFetchRepositoryFactory.staticLayerData(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )
            
            let operation = repository.startFetch(
                StaticLayerDataFetchRequest(eventID: EventID(1), layerID: LayerID(2))
            )
            
            let result: StaticLayerRepositoryFetchResult = try #require(
                try? await operation.value()
            )
            #expect(result.dto?.features.count == 6)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Layer.self, 1)
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
}
