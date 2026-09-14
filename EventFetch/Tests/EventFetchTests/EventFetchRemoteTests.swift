import Testing
import APIRouter
import ServerDTO
import Foundation
import TestUtilities
import Layer
import Pipeline
import FetchOperation

@testable import EventFetch

struct EventFetchRemoteTests {
    let sut: any EventFetchRemote
    
    init() {
        sut = EventFetchRemoteImpl(
            url: URL(string: "https://magetest")!,
            session: TestAPISession()
        )
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events",
            responseArray: [EventFetchRemoteTests.eventDTO.dictionary!]
        )
    )
    func fetchReturnsEventsFromServer() async throws {
        let events = try await sut.fetch() { progress in
        }
        
        #expect(events.count == 1)
        
        let first = try #require(events.first)
        #expect(first.id.rawValue == 1)
        #expect(first.name == "Event 1")
        #expect(first.maxObservationForms == 100)
        #expect(first.minObservationForms == 0)
        #expect(first.description == "Event description")
        #expect(first.forms?.count == 1)
        #expect(first.teams?.count == 1)
        #expect(first.layers?.count == 1)
        #expect(first.style != nil)
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events",
            responseArray: [EventFetchRemoteTests.eventDTO.dictionary!]
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
        _ = try await sut.fetch() { progress in
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
            path: "/api/events",
            statusCode: 500
        )
    )
    func fetchThrowsForServerError() async throws {
        await #expect(throws: Error.self) {
            _ = try await sut.fetch() { _ in }
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events",
            responseString: "{ invalid json"
        )
    )
    func fetchThrowsForMalformedJSON() async throws {
        await #expect(throws: Error.self) {
            _ = try await sut.fetch() { _ in }
        }
    }
    
    @Test(
        .httpStub(
            method: .get,
            scheme: "https",
            host: "magetest",
            path: "/api/events",
            responseError: URLError(.notConnectedToInternet) as NSError
        )
    )
    func fetchThrowsUnderlyingTransportError() async throws {
        await #expect(throws: URLError.self) {
            _ = try await sut.fetch() { _ in }
        }
    }
    
    static let eventDTO = EventDTO(
        id: EventID(1),
        name: "Event 1",
        maxObservationForms: 100,
        minObservationForms: 0,
        description: "Event description",
        acl: ["userabc": ACLDTO(role: "MANAGER", permissions: ["read", "update"], userId: UserID("userabc"))],
        forms: [
            EventFormDTO(
                id: EventFormID(1),
                primaryFeedField: "field0",
                secondaryFeedField: "field1",
                primaryField: "field1",
                variantField: "field0",
                name: "Form 1",
                userFields: nil,
                archived: false,
                min: nil,
                max: nil,
                color: "#000000",
                isDefault: false,
                fields: [
                    EventFormFieldDTO.from(jsonObject: [
                        "name": "field0",
                        "id": 0,
                        "required": false,
                        "type": "dropdown",
                        "title": "Animal Type",
                        "allowedAttachmentTypes": [],
                        "choices": [
                            [
                                "value": 0,
                                "id": 1,
                                "title": "Turtle"
                            ],
                            [
                                "value": 1,
                                "id": 2,
                                "title": "Turkey"
                            ]
                        ]
                    ])!,
                    EventFormFieldDTO.from(jsonObject: [
                        "name": "field1",
                        "id": 0,
                        "required": false,
                        "type": "dropdown",
                        "title": "Color",
                        "allowedAttachmentTypes": [],
                        "choices": [
                            [
                                "value": 0,
                                "id": 1,
                                "title": "Red"
                            ],
                            [
                                "value": 1,
                                "id": 2,
                                "title": "Blue"
                            ],
                            [
                                "value": 1,
                                "id": 2,
                                "title": "Green"
                            ]
                        ]
                    ])!
                ],
                style: StyleDTO.from(jsonObject: [
                    "fill": "#5278A2",
                    "fillOpacity": 0.2,
                    "stroke": "#5278A2",
                    "strokeOpacity": 1,
                    "strokeWidth": 2,
                    "Turtle": [
                        "fill": "#5278a2",
                        "fillOpacity": 0.2,
                        "stroke": "#214166",
                        "strokeOpacity": 1,
                        "strokeWidth": 2,
                        "Red": [
                            "fill": "#ff0033",
                            "fillOpacity": 0.2,
                            "stroke": "#ff0026",
                            "strokeOpacity": 1,
                            "strokeWidth": 2
                        ]
                    ],
                    "Turkey": [
                        "fill": "#a37651",
                        "fillOpacity": 0.2,
                        "stroke": "#64a351",
                        "strokeOpacity": 1,
                        "strokeWidth": 2,
                        "Red": [
                            "fill": "#a37651",
                            "fillOpacity": 0.2,
                            "stroke": "#a3508e",
                            "strokeOpacity": 1,
                            "strokeWidth": 2
                        ],
                        "Blue": [
                            "fill": "#a3509c",
                            "fillOpacity": 0.2,
                            "stroke": "#f0ea30",
                            "strokeOpacity": 1,
                            "strokeWidth": 2
                        ],
                        "Green": [
                            "fill": "#d4731e",
                            "fillOpacity": 0.2,
                            "stroke": "#f0faed",
                            "strokeOpacity": 1,
                            "strokeWidth": 2
                        ]
                    ]
                ])
            )
        ],
        teams: [TeamDTO.from(jsonObject: [
            "name": "Animal",
            "description": "This team belongs specifically to event 'Animal' and cannot be deleted.",
            "teamEventId": 1,
            "acl": [
                "userghi": [
                    "role": "MANAGER",
                    "permissions": [
                        "read",
                        "update"
                    ]
                ],
                "userdef": [
                    "role": "OWNER",
                    "permissions": [
                        "read",
                        "update",
                        "delete"
                    ]
                ],
                "userabc": [
                    "role": "OWNER",
                    "permissions": [
                        "read",
                        "update",
                        "delete"
                    ]
                ]
            ],
            "userIds": [
            ],
            "id": "teamabc"
        ])!],
        layers: [
            MapLayerDTO(
                remoteId: LayerID(1),
                name: "Layer 1",
                type: "Imagery",
                url: "https://example.com",
                format: "XYZ"
            )
        ],
        style: StyleDTO(
            strokeWidth: 1.0, strokeOpacity: 1.0, stroke: "#000000", fillOpacity: 1.0, fill: "#ffffff", fieldStyles: nil
        )
    )
}
