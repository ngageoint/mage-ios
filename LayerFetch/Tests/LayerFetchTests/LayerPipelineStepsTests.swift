import Foundation
import Testing
import TestUtilities
@testable import FetchOperation
@testable import Pipeline
@testable import ServerDTO
@testable import LayerFetch

struct LayerPipelineStepsTests {

    struct LayerPipelineStepEventLayerSave {
        @Test
        func `save layers stores save result`() async throws {
            
            let importer = MockLayerImporter()
            importer.saveResult = LayerSaveResult(
                inserted: 1,
                updated: 0,
                deleted: 0
            )
            
            let context = MockEventLayerPipelineContext(
                eventToLayerDTO: [
                    EventToLayerDTO(
                        eventID: EventID(1),
                        layerDTO: []
                    )
                ]
            )
            
            let step = PipelineStep<MockEventLayerPipelineContext>
                .saveLayers(layerImporter: importer)
            
            let result = try await step.perform(
                context
            ) { _ in }
            
            #expect(result.layerSaveResult?.inserted == 1)
        }
        
        @Test
        func `save layers saves layers for each event`() async throws {
            
            let importer = MockLayerImporter()
            
            let context = MockEventLayerPipelineContext(
                eventToLayerDTO: [
                    EventToLayerDTO(
                        eventID: EventID(1),
                        layerDTO: []
                    ),
                    EventToLayerDTO(
                        eventID: EventID(2),
                        layerDTO: []
                    )
                ]
            )
            
            let step = PipelineStep<MockEventLayerPipelineContext>
                .saveLayers(layerImporter: importer)
            
            _ = try await step.perform(
                context
            ) { _ in }
            
            #expect(importer.saveCalls == 2)
            #expect(importer.eventIDs == [
                EventID(1),
                EventID(2)
            ])
        }
        
        @Test
        func `save layers combines save results`() async throws {
            
            let importer = MockLayerImporter()
            importer.saveResults = [
                LayerSaveResult(
                    inserted: 1,
                    updated: 2,
                    deleted: 3
                ),
                LayerSaveResult(
                    inserted: 4,
                    updated: 5,
                    deleted: 6
                )
            ]
            
            let context = MockEventLayerPipelineContext(
                eventToLayerDTO: [
                    EventToLayerDTO(
                        eventID: EventID(1),
                        layerDTO: []
                    ),
                    EventToLayerDTO(
                        eventID: EventID(2),
                        layerDTO: []
                    )
                ]
            )
            
            let step = PipelineStep<MockEventLayerPipelineContext>
                .saveLayers(layerImporter: importer)
            
            let result = try await step.perform(
                context
            ) { _ in }
            
            #expect(result.layerSaveResult?.inserted == 5)
            #expect(result.layerSaveResult?.updated == 7)
            #expect(result.layerSaveResult?.deleted == 9)
        }
        
        @Test
        func `save layers throws when importer throws`() async throws {
            
            let importer = MockLayerImporter()
            importer.error = TestError.failure
            
            let context = MockEventLayerPipelineContext(
                eventToLayerDTO: [
                    EventToLayerDTO(
                        eventID: EventID(1),
                        layerDTO: []
                    )
                ]
            )
            
            let step = PipelineStep<MockEventLayerPipelineContext>
                .saveLayers(layerImporter: importer)
            
            await #expect(throws: TestError.self) {
                try await step.perform(
                    context
                ) { _ in }
            }
        }
    }
    
    struct LayerPipelineStepLayerSave {
        @Test
        func `save layers stores save result`() async throws {
            
            let importer = MockLayerImporter()
            importer.saveResult = LayerSaveResult(
                inserted: 1,
                updated: 0,
                deleted: 0
            )
            
            let context = MockLayerPipelineContext(
                eventID: EventID(1),
                dto: []
            )
            
            let step = PipelineStep<MockLayerPipelineContext>
                .saveLayers(layerImporter: importer)
            
            let result = try await step.perform(
                context
            ) { _ in }
            
            #expect(result.layerSaveResult?.inserted == 1)
        }
        
        @Test
        func `save layers saves layers for each event`() async throws {
            
            let importer = MockLayerImporter()
            
            let context = MockLayerPipelineContext(
                eventID: EventID(1),
                dto: []
            )
            
            let step = PipelineStep<MockLayerPipelineContext>
                .saveLayers(layerImporter: importer)
            
            _ = try await step.perform(
                context
            ) { _ in }
            
            #expect(importer.saveCalls == 1)
            #expect(importer.eventIDs == [
                EventID(1)
            ])
        }
        
        @Test
        func `save layers combines save results`() async throws {
            
            let importer = MockLayerImporter()
            importer.saveResults = [
                LayerSaveResult(
                    inserted: 1,
                    updated: 2,
                    deleted: 3
                )
            ]
            
            let context = MockLayerPipelineContext(
                eventID: EventID(1),
                dto: []
            )
            
            let step = PipelineStep<MockLayerPipelineContext>
                .saveLayers(layerImporter: importer)
            
            let result = try await step.perform(
                context
            ) { _ in }
            
            #expect(result.layerSaveResult?.inserted == 1)
            #expect(result.layerSaveResult?.updated == 2)
            #expect(result.layerSaveResult?.deleted == 3)
        }
        
        @Test
        func `save layers throws when importer throws`() async throws {
            
            let importer = MockLayerImporter()
            importer.error = TestError.failure
            
            let context = MockLayerPipelineContext(
                eventID: EventID(1),
                dto: []
            )
            
            let step = PipelineStep<MockLayerPipelineContext>
                .saveLayers(layerImporter: importer)
            
            await #expect(throws: TestError.self) {
                try await step.perform(
                    context
                ) { _ in }
            }
        }
    }
    
    struct LayerPipelineStepDownloadStaticLayerData {
        @Test
        func `download static layer data`() async throws {
            let remote = MockStaticLayerFetchRemote()
            remote.featureCollection = [TestUtilities
                .loadJSON(
                    filename: "staticFeatures",
                    fileExtension: "geojson",
                    type: StaticLayerFeatureCollectionDTO.self
                )!]
            
            let context = MockStaticFeatureCollectionPipelineContext(
                eventID: EventID(1),
                layerID: LayerID(2),
                urlRequest: try! LayerFetchRouter(
                    baseURL: URL(string:"https://magetest")!,
                    endpoint: .fetchStaticLayerData(eventID: EventID(1), layerID: LayerID(2))
                ).asURLRequest()
            )
            
            let step = PipelineStep<MockStaticFeatureCollectionPipelineContext>
                .downloadStaticLayerData(remote: remote)
            let context2 = try await step.perform(context) { _ in }
            
            #expect(context2.staticLayerFeatureCollectionDTO?.features.count == 6)
        }
    }
    
    struct LayerPipelineStepSaveStaticLayerData {
        @Test
        func `save static layer data`() async throws {
            let local = MockStaticLayerFetchLocal()
            local.result = .init(
                saveCount: 6,
                iconsToFetch: [
                    StaticLayerIconLocation(
                        url: URL(string: "https://example.com/icon.png")!,
                        layerID: LayerID(2),
                        featureID: StaticLayerFeatureID("featureid")
                    )
                ]
            )
            var context = MockStaticFeatureCollectionPipelineContext(
                eventID: EventID(1),
                layerID: LayerID(2),
                urlRequest: try! LayerFetchRouter(
                    baseURL: URL(string:"https://magetest")!,
                    endpoint: .fetchStaticLayerData(eventID: EventID(1), layerID: LayerID(2))
                ).asURLRequest()
            )
            context.staticLayerFeatureCollectionDTO = TestUtilities
                .loadJSON(
                    filename: "staticFeatures",
                    fileExtension: "geojson",
                    type: StaticLayerFeatureCollectionDTO.self
                )!
            let step = PipelineStep<MockStaticFeatureCollectionPipelineContext>
                .saveStaticLayerData(local: local)
            let context2 = try await step.perform(context) { _ in }
            
            #expect(context2.staticLayerSaveResult?.saveCount == 6)
            #expect(context2.staticLayerSaveResult?.iconsToFetch.count == 1)
        }
    }
    
    struct LayerPipelineStepSaveStaticLayerIcons {
        @Test
        func `save static layer icons`() async throws {
            let fetch = MockStaticLayerIconFetch()
            var context = MockStaticFeatureCollectionPipelineContext(
                eventID: EventID(1),
                layerID: LayerID(2),
                urlRequest: try! LayerFetchRouter(
                    baseURL: URL(string:"https://magetest")!,
                    endpoint: .fetchStaticLayerData(eventID: EventID(1), layerID: LayerID(2))
                ).asURLRequest()
            )
            context.staticLayerSaveResult = .init(
                saveCount: 6,
                iconsToFetch: [StaticLayerIconLocation(url: URL(string: "https://example.com/icon.png")!, layerID: LayerID(2), featureID: StaticLayerFeatureID("featureid"))]
            )
            let step = PipelineStep<MockStaticFeatureCollectionPipelineContext>
                .saveStaticLayerIcons(fetcher: fetch)
            let context2 = try await step.perform(context) { _ in }
            
            #expect(fetch.called == true)
            #expect(fetch.iconsToFetch.count == 1)
        }
    }
}

struct MockStaticFeatureCollectionPipelineContext: StaticLayerFeatureCollectionDTOContext, URLRequestContext, EventIDContext, LayerIDContext, StaticLayerSaveResultContext {
    let eventID: EventID

    let layerID: LayerID

    var staticLayerSaveResult: LayerFetch.StaticLayerSaveResult?

    var staticLayerFeatureCollectionDTO: StaticLayerFeatureCollectionDTO?

    var urlRequest: URLRequest?

    
    init(
        eventID: EventID,
        layerID: LayerID,
        staticLayerFeatureCollectionDTO: StaticLayerFeatureCollectionDTO? = nil,
        urlRequest: URLRequest? = nil
    ) {
        self.eventID = eventID
        self.layerID = layerID
        self.staticLayerFeatureCollectionDTO = staticLayerFeatureCollectionDTO
        self.urlRequest = urlRequest
    }
}


struct MockEventLayerPipelineContext: EventToLayerContext, LayerSaveResultContext {
    
    init(
        eventToLayerDTO: [EventToLayerDTO],
        layerSaveResult: LayerSaveResult? = nil
    ) {
        self.eventToLayerDTO = eventToLayerDTO
        self.layerSaveResult = layerSaveResult
    }
    
    var eventToLayerDTO: [EventToLayerDTO]
    
    var layerSaveResult: LayerSaveResult?
}

struct MockLayerPipelineContext: DTOContext, LayerSaveResultContext, EventIDContext {
    
    init(
        eventID: EventID,
        dto: [MapLayerDTO],
        layerSaveResult: LayerSaveResult? = nil
    ) {
        self.eventID = eventID
        self.dto = dto
        self.layerSaveResult = layerSaveResult
    }
    
    var eventID: EventID
    var dto: [MapLayerDTO]
    
    var layerSaveResult: LayerSaveResult?
}


final class MockLayerImporter: LayerImporter, @unchecked Sendable {
    
    var saveResult: LayerSaveResult = .empty
    var saveResults: [LayerSaveResult] = []
    var saveCalls = 0
    var eventIDs: [EventID] = []
    var error: Error?
    
    func synchronizeLayers(
        _ dto: [MapLayerDTO],
        eventID: EventID,
        progress: @escaping OperationProgressHandler
    ) async throws -> LayerSaveResult {
        saveCalls += 1
        eventIDs.append(eventID)
        
        if let error {
            throw error
        }
        
        if !saveResults.isEmpty {
            return saveResults.removeFirst()
        }
        
        return saveResult
    }
}

final class MockStaticLayerFetchRemote: StaticLayerFetchRemote, @unchecked Sendable {
    var featureCollection: [StaticLayerFeatureCollectionDTO] = []
    func fetch(urlRequest: URLRequest?, progress: OperationProgressHandler) async throws -> [StaticLayerFeatureCollectionDTO] {
        return featureCollection
    }
}

final class MockStaticLayerFetchLocal: StaticLayerFetchLocal, @unchecked Sendable {
    var result: StaticLayerSaveResult = .init(saveCount: 0, iconsToFetch: [])
    func save(_ dto: StaticLayerFeatureCollectionDTO, eventID: EventID, layerID: LayerID, progress: @escaping OperationProgressHandler) async throws -> StaticLayerSaveResult {
        result
    }
}

final class MockStaticLayerIconFetch: StaticLayerIconFetch, @unchecked Sendable {
    var called = false
    var iconsToFetch: [StaticLayerIconLocation] = []
    func fetch(iconsToFetch: [StaticLayerIconLocation], progress: @escaping OperationProgressHandler) async throws {
        called = true
        self.iconsToFetch = iconsToFetch
    }
}


enum TestError: Error {
    case failure
    case test
}
