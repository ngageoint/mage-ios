// 
//     
//  LocationFetchLocalTests.swift
//  MAGE
//
// 



import Testing
import CoreData
import Persistence
import FetchOperation
import ServerDTO
import CodableExtensions
@testable import LocationFetch
import Pipeline

@testable import MAGE

extension CoreDataTests {
    final class LocationFetchLocalTests {
        
        let persistence: PersistenceProtocol
        let context: NSManagedObjectContext
        let local: LocationFetchLocalImpl
        
        init() {
            persistence = PersistenceContext.current!.persistence
            context = persistence.writeContext
            local = LocationFetchLocalImpl(
                persistence: persistence,
                currentUserID: "me"
            )
        }
        
        // MARK: - getLastLocationDate
        
        @Test
        func `returns nil when no locations exist`() async {
            let date = await local.getLastLocationDate(eventId: 1)
            
            #expect(date == nil)
        }
        
        @Test
        func `returns most recent location timestamp`() async throws {
            let older = Location(context: context)
            older.eventId = 1
            older.timestamp = Date(timeIntervalSince1970: 100)
            
            let newer = Location(context: context)
            newer.eventId = 1
            newer.timestamp = Date(timeIntervalSince1970: 200)
            
            try context.save()
            
            let date = await local.getLastLocationDate(eventId: 1)
            
            #expect(date == newer.timestamp)
        }
        
        @Test
        func `ignores locations from other events`() async throws {
            let location = Location(context: context)
            location.eventId = 2
            location.timestamp = Date()
            
            try context.save()
            
            let date = await local.getLastLocationDate(eventId: 1)
            
            #expect(date == nil)
        }
        
        // MARK: - handleChunk
        
        @Test
        func `returns empty result for empty chunk`() async throws {
            let result = try await local.handleChunk(chunk: [])
            
            #expect(result == .empty)
        }
        
        @Test
        func `ignores dto without id`() async throws {
            let dto = UserLocationDTO(locations: [])
            
            let result = try await local.handleChunk(chunk: [dto])
            
            #expect(result == .empty)
        }
        
        @Test
        func `ignores dto without locations`() async throws {
            let dto = UserLocationDTO(id: "user1")
            
            let result = try await local.handleChunk(chunk: [dto])
            
            #expect(result == .empty)
        }
        
        @Test
        func `creates location for existing user without location`() async throws {
            let user = User(context: context)
            user.remoteId = "user1"
            user.lastUpdated = Date()
            
            try context.save()
            
            let dto = makeLocationDTO(userId: "user1")
            
            let result = try await local.handleChunk(chunk: [dto])
            
            #expect(result?.inserted == 1)
            #expect(result?.updated == 0)
            
            context.refresh(user, mergeChanges: true)
            
            #expect(user.location != nil)
        }
        
        @Test
        func `updates existing location`() async throws {
            let user = User(context: context)
            user.remoteId = "user1"
            user.lastUpdated = Date()
            
            let location = Location(context: context)
            location.geometry = SFPoint(xValue: 10, andYValue: 10)
            user.location = location
            
            try context.save()
            
            let dto = makeLocationDTO(
                userId: "user1",
                latitude: 25,
                longitude: 50
            )
            
            let result = try await local.handleChunk(chunk: [dto])
            
            #expect(result?.updated == 1)
            
            context.refresh(location, mergeChanges: true)
            
            #expect(location.coordinate.latitude == 25)
            #expect(location.coordinate.longitude == 50)
        }
        
        @Test
        func `reports missing user when existing user is not populated`() async throws {
            let user = User(context: context)
            user.remoteId = "user1"
            user.lastUpdated = nil
            
            try context.save()
            
            let dto = makeLocationDTO(userId: "user1")
            
            let result = try await local.handleChunk(chunk: [dto])
            
            #expect(result?.missingUserIds == ["user1"])
        }
        
        @Test
        func `creates placeholder user when user information is included`() async throws {
            let dto = makeLocationDTO(userId: "user1")
            
            let result = try await local.handleChunk(chunk: [dto])
            
            #expect(result?.inserted == 1)
            #expect(result?.missingUserIds == ["user1"])
            
            let users = try? context.fetch(User.fetchRequest())
            
            #expect(users?.count == 1)
        }
        
        @Test
        func `ignores current user location`() async throws {
            let dto = makeLocationDTO(userId: "me")
            
            let result = try await local.handleChunk(chunk: [dto])
            
            #expect(result?.ignored == 1)
            #expect(result?.inserted == 0)
            #expect(result?.updated == 0)
        }
        
        // MARK: - save
        
        @Test
        func `save aggregates results`() async throws {
            let user = User(context: context)
            user.remoteId = "user1"
            user.lastUpdated = Date()
            
            try context.save()
            
            var users: [UserLocationDTO] = []
            for i in 1...(local.chunkSize+2) {
                users.append(makeLocationDTO(userId: "user\(i)"))
            }
            
            var progressCalls = 0
            let result = try await local.save(users) { _ in
                progressCalls += 1
            }
            
            #expect(result.updated == 0)
            #expect(result.inserted == users.count)
            #expect(progressCalls == 2)
        }
        
        @Test
        func `save reports final progress`() async throws {
            var progresses: [OperationProgress] = []
            
            _ = try await local.save([]) {
                progresses.append($0)
            }
            
            #expect(progresses.count == 1)
            #expect(progresses.last?.completed == 0)
            #expect(progresses.last?.total == 0)
        }
        
        func makeLocationDTO(
            userId: String,
            latitude: Double = 1,
            longitude: Double = 2
        ) -> UserLocationDTO {
            let response: [AnyHashable: Any] = [
                
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
                        "id": userId
                    ],
                    "locations": [
                        [
                            "geometry": [
                                "type": "Point",
                                "coordinates": [longitude, latitude]
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
                    "id": userId
                ]
            
            return UserLocationDTO.from(jsonObject: response)!
        }
    }
}
