// 
//     
//  LocationFetchRemoteTests.swift
//  MAGE
//
//

import Testing
import Foundation
import Alamofire
import FetchOperation
import ServerDTO
import APIRouter
import TestUtilities
@testable import LocationFetch
@testable import Pipeline

@testable import MAGE

struct LocationFetchRemoteTests {
    
    let sut: LocationFetchRemote
    
    init() {
        sut = LocationFetchRemote(
            url: URL(string: "https://magetest")!,
            session: TokenAPISessionImpl(
                baseURL: URL(string: "https://magetest")!,
                loginType: "local",
                additionalHeaders: [
                    HTTPStubTrait.HeaderKey:
                        Test.current?.id.description ?? ""
                ]
            ),
            eventID: EventID(1)
        )
    }
    
    // MARK: - fetch
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/locations/users",
            responseArray: [
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
        )
    )
    func `fetch decodes locations`() async throws {
        var progressEvents: [OperationProgress] = []
        
        let locations = try await sut.fetch {
            progressEvents.append($0)
        }
        
        #expect(!locations.isEmpty)
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/locations/users",
            expectedQueryParameters: [
                "limit" : "1"
            ],
            responseArray: []
        )
    )
    func `fetch does not send last location date`() async throws {
        _ = try await sut.fetch { _ in }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/locations/users",
            expectedQueryParameters: [
                "limit" : "1",
                "startDate": "1970-01-01T02:46:40.000Z"
            ],
            responseArray: []
        )
    )
    func `fetch sends last location date`() async throws {
        let date = Date(timeIntervalSince1970: 10000)
        _ = try await sut.fetch(urlRequest: LocationFetchRouter(
            baseURL: URL(string:"https://magetest")!,
            endpoint: .fetchLocations(
                eventId: 1,
                lastLocationDate: date
            )
        ).urlRequest!) { _ in }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/locations/users",
            responseString: "Internal Server Error",
            statusCode: 500
        )
    )
    func `fetch throws server error`() async {
        await #expect(throws: Error.self) {
            try await sut.fetch { _ in }
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/locations/users",
            responseString: "not json"
        )
    )
    func `fetch throws decoding error`() async {
        await #expect(throws: Error.self) {
            try await sut.fetch { _ in }
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/locations/users",
            responseArray: [
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
        )
    )
    func `fetch reports download progress`() async throws {
        var progressEvents: [OperationProgress] = []
        
        _ = try await sut.fetch {
            progressEvents.append($0)
        }
        
        #expect(!progressEvents.isEmpty)
        
        for progress in progressEvents {
            #expect(progress.completed >= 0)
            #expect(progress.total >= progress.completed)
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events/1/locations/users",
            responseError: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet
            )
        )
    )
    func `fetch propagates transport error`() async {
        await #expect(throws: Error.self) {
            try await sut.fetch { _ in }
        }
    }
}
