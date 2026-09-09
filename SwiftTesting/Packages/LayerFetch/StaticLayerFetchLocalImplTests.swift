import Testing
import Persistence
import SendableExtensions
import FetchOperation
import Pipeline
import Layer
import LayerFetch
import TestUtilities
import CoreData

@testable import ServerDTO
@testable import LayerFetch

extension CoreDataTests {
    struct StaticLayerFetchLocalImplTests {
        
        let persistence: PersistenceProtocol
        let context: NSManagedObjectContext
        private let local: StaticLayerFetchLocalImpl
        
        init() {
            persistence = PersistenceContext.current!.persistence
            context = persistence.writeContext
            local = StaticLayerFetchLocalImpl(
                persistence: persistence
            )
        }
        
        @Test
        func `test`() async throws {
            let _ = try await persistence.write { context in
                let layer = StaticLayer(context: context)
                layer.remoteId = LayerID(2).rawValue
                layer.eventId = EventID(1).rawValue
                try context.obtainPermanentIDs(for: [layer])
            }
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, StaticLayer.self, 1)
            
            let dto = try #require(TestUtilities.loadJSON(
                filename: "staticFeatures",
                fileExtension: "geojson",
                type: StaticLayerFeatureCollectionDTO.self
            ))
            let result = try await local.save(
                dto,
                eventID: EventID(1),
                layerID: LayerID(2)
            ) { progress in
                
            }
            
            #expect(result.saveCount == 6)
            #expect(result.iconsToFetch.count == 4)
            let first = try #require(result.iconsToFetch.first)
            #expect(first.url.absoluteString == "https://magetest/testkmlicon.png")
        }
        
    }
}
