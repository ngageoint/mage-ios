// 
//     
//  LocationFetchRepositoryFactoryTests.swift
//  MAGE
//
// 



import Foundation
import CoreData
import Testing
import Alamofire
import ServerDTO
import FetchOperation
import Persistence
import APIRouter
import LocationFetch
import TestUtilities
@testable import MAGE
@testable import Pipeline

extension CoreDataTests {
    final class LocationFetchRepositoryFactoryTests {

        let persistence: PersistenceProtocol
        let context: NSManagedObjectContext
        let session: TokenAPISession

        init() {
            persistence = PersistenceContext.current!.persistence
            context = persistence.writeContext
            session = TokenAPISessionImpl(
                baseURL: URL(string: "https://magetest")!,
                loginType: "local",
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            )
        }

        // MARK: - createFetchRepository

        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/locations/users",
                responseArray: LocationFetchRepositoryFactoryTests.oneLocationArray
            )
        )
        func `fetch downloads and saves locations`() async throws {
            let repository = LocationFetchRepositoryFactory.createFetchRepository(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )

            let operation = repository.startFetch(
                LocationFetchRequest(eventID: EventID(1), currentUserID: "user1")
            )

            let result: LocationRepositoryFetchResult = try #require(
                try? await operation.value()
            )
            #expect(result.inserts == 1)
            #expect(!result.dto.isEmpty)
        }

        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/locations/users",
                responseArray: LocationFetchRepositoryFactoryTests.oneLocationArray
            )
        )
        func `fetch emits preparing downloading and saving states`() async throws {
            let repository = LocationFetchRepositoryFactory.createFetchRepository(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )

            let operation = repository.startFetch(
                LocationFetchRequest(eventID: EventID(1), currentUserID: "user1")
            )

            var phases: [PipelineOperationPhase] = []

            for try await event in operation.events() {
                print("event is \(event)")
                if case let .stateChanged(state) = event {
                    if let phase = state.metadata?.phase {
                        phases.append(phase)
                    }
                }
            }

            #expect(phases.contains(.preparing))
            #expect(phases.contains(.downloading))
            #expect(phases.contains(.saving))
        }

        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/locations/users",
                expectedQueryParameters: [
                    "limit": "1"
                ],
                responseArray: LocationFetchRepositoryFactoryTests.oneLocationArray
            )
        )
        func `fetch omits last location date when no locations exist`() async throws {
            let repository = LocationFetchRepositoryFactory.createFetchRepository(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )

            let operation = repository.startFetch(
                LocationFetchRequest(eventID: EventID(1), currentUserID: "user1")
            )
            for try await _ in operation.events() { }
        }

        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/locations/users",
                expectedQueryParameters: [
                    "limit": "1",
                    "startDate": "1970-01-01T02:46:40.000Z"
                ],
                responseArray: LocationFetchRepositoryFactoryTests.oneLocationArray
            )
        )
        func `fetch includes newest location date`() async throws {
            let date = Date(timeIntervalSince1970: 10000)
            let result = try await persistence.write { context in
                let location = Location(context: context)
                try context.obtainPermanentIDs(for: [location])
                location.eventId = 1
                location.timestamp = date
            }
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Location.self, 1)

            let repository = LocationFetchRepositoryFactory.createFetchRepository(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )

            let operation = repository.startFetch(
                LocationFetchRequest(eventID: EventID(1), currentUserID: "user1")
            )
            for try await _ in operation.events() { }
        }

        @Test(
            .httpStub(
                method: .get,
                scheme: "https",
                host: "magetest",
                path: "/api/events/1/locations/users",
                responseString: "Server Error",
                statusCode: 500
            )
        )
        func `fetch propagates remote failure`() async {
            let repository = LocationFetchRepositoryFactory.createFetchRepository(
                url: URL(string: "https://magetest")!,
                session: session,
                persistence: persistence
            )

            let operation = repository.startFetch(
                LocationFetchRequest(eventID: EventID(1), currentUserID: "user1")
            )
            await #expect(throws: Error.self) {
                for try await _ in operation.events() { }
            }
        }
        
        static let oneLocationArray = [
            [
                "userId": [
                    "iconUrl": "https://example.com/image.png",
                    "icon": [
                        "text": "FB",
                        "color": "#3b5998"
                    ],
                    "displayName": "Fred",
                    "phones": [[
                        "number": "07739555555"
                    ]],
                    "id": "userabc"
                ],
                "locations": [
                    [
                        "geometry": [
                            "type": "Point",
                            "coordinates": [-104.3678, 40.1085]
                        ],
                        "userId": "userabc",
                        "eventId": 1,
                        "teamIds": [
                            "teamabc"
                        ],
                        "type": "Feature",
                        "properties": [
                            "accuracy": 5,
                            "system_name": "iOS",
                            "bearing": -1,
                            "provider": "gps",
                            "millis": 1764.7355,
                            "system_version": "26.0",
                            "device_name": "iPhone 17 Pro",
                            "verticalAccuracy": -1,
                            "timestamp": "2025-12-03T21:58:51.000Z",
                            "device_model": "iPhone",
                            "mage_version": "1.0.0-Set by build phase script",
                            "speed": 0,
                            "altitude": 0,
                            "battery_state": "Unknown",
                            "battery_level": -100,
                            "deviceId": "deviceid"
                        ],
                        "_id": "locationid"
                    ]
                ],
                "user": [
                    "displayName": "Fred",
                    "phones": [[
                        "number": "07739555555"
                    ]],
                    "id": "userabc",
                    "iconUrl": "https://example.com/image.png",
                    "icon": [
                        "text": "FB",
                        "color": "#3b5998"
                    ]
                ],
                "id": "userabc"
            ]
        ]
    }
}
