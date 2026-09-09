// 
//     
//  LayerImporterImplTests.swift
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

@testable import ServerDTO
@testable import LayerFetch

extension CoreDataTests {
    struct LayerImporterImplTests {
        
        let persistence: PersistenceProtocol
        let context: NSManagedObjectContext
        private let importer: LayerImporterImpl

        init() {
            persistence = PersistenceContext.current!.persistence
            context = persistence.writeContext
            importer = LayerImporterImpl(
                persistence: persistence
            )
        }
        // MARK: - synchronizeLayers(_:eventID:progress:)
        
        @Test
        func `synchronizeLayers inserts feature layer`() async throws {
            let dto = MapLayerDTO(
                remoteId: LayerID(1),
                name: "Feature",
                type: "Feature"
            )
            
            let result = try await importer.synchronizeLayers(
                [dto],
                eventID: EventID(1),
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            
            let (remoteId, eventId) = try await persistence.read { context in
                let layer = try context.fetchFirst(
                    StaticLayer.self,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        LayerKey.remoteId.key,
                        NSNumber(1)
                    )
                )
                return (layer?.remoteId, layer?.eventId)
            }
            
            
            #expect(remoteId?.int64Value == 1)
            #expect(eventId?.int64Value == 1)
        }
        
        @Test
        func `synchronizeLayers inserts geopackage layer`() async throws {
            let dto = MapLayerDTO(
                remoteId: LayerID(2),
                name: "GeoPackage",
                type: "GeoPackage"
            )
            
            let result = try await importer.synchronizeLayers(
                [dto],
                eventID: EventID(1),
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            
            let (remoteId, eventId) = try await persistence.read { context in
                let layer = try context.fetchFirst(
                    Layer.self,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        LayerKey.remoteId.key,
                        NSNumber(2)
                    )
                )
                return (layer?.remoteId, layer?.eventId)
            }
                        
            #expect(remoteId?.int64Value == 2)
            #expect(eventId?.int64Value == 1)
        }
        
        @Test
        func `synchronizeLayers inserts imagery layer`() async throws {
            let dto = MapLayerDTO(
                remoteId: LayerID(3),
                name: "Imagery",
                type: "Imagery"
            )
            
            let result = try await importer.synchronizeLayers(
                [dto],
                eventID: EventID(1),
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            
            let remoteId = try await persistence.read { context in
                try context.fetchFirst(
                    ImageryLayer.self,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        LayerKey.remoteId.key,
                        NSNumber(3)
                    )
                )?.remoteId
            }
            
            
            #expect(remoteId?.int64Value == 3)
        }
        
        @Test
        func `synchronizeLayers updates existing layer`() async throws {
            try await persistence.write { context in
                let layer = Layer(context: context)
                layer.remoteId = 1
                layer.eventId = 1
                layer.name = "Old"
            }
            
            let dto = MapLayerDTO(
                remoteId: LayerID(1),
                name: "Updated",
                type: "GeoPackage"
            )
            
            let result = try await importer.synchronizeLayers(
                [dto],
                eventID: EventID(1),
                progress: { _ in }
            )
            
            #expect(result.updated == 1)
            #expect(result.inserted == 0)
            
            let fetched = try await persistence.read { context in
                try context.fetchFirst(
                    Layer.self,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        LayerKey.remoteId.key,
                        NSNumber(1)
                    )
                )?.name
            }
            
            #expect(fetched == "Updated")
        }
        
        @Test
        func `synchronizeLayers deletes layers not returned by server`() async throws {
            try await persistence.write { context in
                let deleted = Layer(context: context)
                deleted.remoteId = 1
                deleted.eventId = 1
                
                let kept = Layer(context: context)
                kept.remoteId = 2
                kept.eventId = 1
            }
            
            let dto = MapLayerDTO(
                remoteId: LayerID(2),
                type: "GeoPackage"
            )
            
            let result = try await importer.synchronizeLayers(
                [dto],
                eventID: EventID(1),
                progress: { _ in }
            )
            
            #expect(result.deleted == 1)
            
            let deletedLayer = try await persistence.read { context in
                try context.fetchFirst(
                    Layer.self,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        LayerKey.remoteId.key,
                        NSNumber(1)
                    )
                )?.remoteId
            }
            
            #expect(deletedLayer == nil)
        }
        
        @Test
        func `synchronizeLayers does not delete layers from other events`() async throws {
            try await persistence.write { context in
                let layer = Layer(context: context)
                layer.remoteId = 1
                layer.eventId = 2
            }
            
            let result = try await importer.synchronizeLayers(
                [],
                eventID: EventID(1),
                progress: { _ in }
            )
            
            #expect(result.deleted == 0)
            
            let layer = try await persistence.read { context in
                try context.fetchFirst(
                    Layer.self,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        LayerKey.remoteId.key,
                        NSNumber(1)
                    )
                )?.remoteId
            }
            
            #expect(layer != nil)
        }
        
        @Test
        func `synchronizeLayers preserves geopackage download state across events`() async throws {
            try await persistence.write { context in
                let existing = Layer(context: context)
                existing.remoteId = 10
                existing.eventId = 1
                existing.loaded = true
            }
            
            let dto = MapLayerDTO(
                remoteId: LayerID(10),
                type: "GeoPackage"
            )
            
            _ = try await importer.synchronizeLayers(
                [dto],
                eventID: EventID(2),
                progress: { _ in }
            )
            
            let fetched = try await persistence.read { context in
                try context.fetchFirst(
                    Layer.self,
                    predicate: NSPredicate(
                        format: "%K == %@ AND %K == %@",
                        LayerKey.remoteId.key,
                        NSNumber(10),
                        LayerKey.eventId.key,
                        NSNumber(2)
                    )
                )?.loaded
            }
            
            #expect(fetched == true)
        }
        
        @Test
        func `synchronizeLayers reports progress`() async throws {
            let dto = (1...6).map {
                MapLayerDTO(
                    remoteId: LayerID($0),
                    type: "GeoPackage"
                )
            }
            
            final class ProgressCollector: @unchecked Sendable {
                private let lock = NSLock()
                private(set) var progress: [OperationProgress] = []
                
                func append(_ progress: OperationProgress) {
                    lock.lock()
                    defer { lock.unlock() }
                    
                    self.progress.append(progress)
                }
            }
            
            let collector = ProgressCollector()
            
            _ = try await importer.synchronizeLayers(
                dto,
                eventID: EventID(1),
                progress: {
                    collector.append($0)
                }
            )
            
            let progress = collector.progress
            
            #expect(progress.count == 2)
            #expect(progress.first?.completed == 5)
            #expect(progress.last?.completed == 6)
        }
        
        @Test
        func `synchronizeLayers handles empty dto`() async throws {
            let result = try await importer.synchronizeLayers(
                [],
                eventID: EventID(1),
                progress: { _ in }
            )
            
            #expect(result.inserted == 0)
            #expect(result.updated == 0)
            #expect(result.deleted == 0)
        }
    }
}
