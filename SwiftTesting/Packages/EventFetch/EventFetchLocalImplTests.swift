// 
//     
//  EventFetchLocalImplTests.swift
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
import CodableExtensions
import Event
import User
import Form

@testable import ServerDTO
@testable import EventFetch

extension CoreDataTests {
    struct EventFetchLocalImplTests {
        let persistence: PersistenceProtocol
        let fetchLocal: EventFetchLocalImpl
        
        init() {
            persistence = PersistenceContext.current!.persistence
            fetchLocal = EventFetchLocalImpl(persistence: persistence)
        }
        
        // MARK: - save
        
        @Test
        func `save inserts event`() async throws {
            let result = try await fetchLocal.save(
                [eventDTO],
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            #expect(result.updated == 0)
            #expect(result.deleted == 0)
            
            await persistence.read { context in
                let event = context.fetchFirst(
                    Event.self,
                    key: EventKey.remoteId.key,
                    value: eventDTO.id.rawValue
                )
                
                #expect(event?.remoteId == eventDTO.id.rawValue)
                #expect(event?.name == eventDTO.name)
                #expect(event?.eventDescription == eventDTO.description)
                #expect(
                    event?.maxObservationForms == eventDTO.maxObservationForms.map(NSNumber.init)
                )
                #expect(
                    event?.minObservationForms == eventDTO.minObservationForms.map(NSNumber.init)
                )
            }
        }
        
        @Test
        func `save updates existing event`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = eventDTO.id.rawValue
                event.name = "Original Name"
                
                try? context.obtainPermanentIDs(for: [event])
            }
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)
            
            let result = try await fetchLocal.save(
                [eventDTO],
                progress: { _ in }
            )
            
            #expect(result.inserted == 0)
            #expect(result.updated == 1)
            #expect(result.deleted == 0)
            
            await persistence.read { context in
                let events = context.fetchAll(Event.self)
                
                #expect(events?.count == 1)
                #expect(events?.first?.name == eventDTO.name)
            }
            
        }
        
        @Test
        func `save deletes events not returned by server`() async throws {
            _ = try await persistence.write { context in
                let existingEvent = Event(context: context)
                existingEvent.remoteId = eventDTO.id.rawValue
                existingEvent.name = eventDTO.name
                
                let staleEvent = Event(context: context)
                staleEvent.remoteId = 999
                staleEvent.name = "Stale Event"
                
                try? context.obtainPermanentIDs(for: [existingEvent, staleEvent])
            }
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 2)

            let result = try await fetchLocal.save(
                [eventDTO],
                progress: { _ in }
            )
            
            #expect(result.inserted == 0)
            #expect(result.updated == 1)
            #expect(result.deleted == 1)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Event.self, 1, predicate: NSPredicate(
                    format: "%K == %@",
                    EventKey.remoteId.key,
                    eventDTO.id.rawValue
                ))
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Event.self, 0, predicate: NSPredicate(
                    format: "%K == %@",
                    EventKey.remoteId.key,
                    NSNumber(999)
                ))
        }
        
        @Test
        func `save deletes all existing events when server returns no events`() async throws {
            _ = try await persistence.write { context in
                let firstEvent = Event(context: context)
                firstEvent.remoteId = 1
                
                let secondEvent = Event(context: context)
                secondEvent.remoteId = 2
                try? context.obtainPermanentIDs(for: [firstEvent, secondEvent])
            }
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 2)
            
            let result = try await fetchLocal.save(
                [],
                progress: { _ in }
            )
            
            #expect(result.inserted == 0)
            #expect(result.updated == 0)
            #expect(result.deleted == 2)
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 0)

        }
        
        @Test
        func `save inserts and updates multiple events`() async throws {
            let existingDTO = eventDTO
            let newDTO = EventDTO(
                id: EventID(2),
                name: "Event 2",
                maxObservationForms: 100,
                minObservationForms: 0,
                description: "Event 2 description",
                acl: nil,
                forms: [],
                teams: [],
                layers: [],
                style: nil
            )
            
            _ = try await persistence.write { context in
                let existingEvent = Event(context: context)
                existingEvent.remoteId = existingDTO.id.rawValue
            
                try? context.obtainPermanentIDs(for: [existingEvent])
            }
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)

            let result = try await fetchLocal.save(
                [existingDTO, newDTO],
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            #expect(result.updated == 1)
            #expect(result.deleted == 0)
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 2)
        }
        
        @Test
        func `save applies event ACL`() async throws {
            let result = try await fetchLocal.save(
                [eventDTO],
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(persistence, Event.self, 1, predicate: NSPredicate(
                    format: "%K == %@",
                    EventKey.remoteId.key,
                    eventDTO.id.rawValue
                ))
            
            let expectedACL = eventDTO.acl?
                .mapValues { $0.dictionary }
                .compactMapValues { $0 }
            
            await persistence.read { context in
                let event = context.fetchFirst(
                    Event.self,
                    key: EventKey.remoteId.key,
                    value: eventDTO.id.rawValue
                )
                let eventAcl = event?.acl?
                    .mapValues { ($0 as? Encodable)?.dictionary }
                    .compactMapValues { $0 }
                #expect(TestUtilities
                    .deepCompareDictionaries(
                        dict1: eventAcl!,
                        dict2: expectedACL!
                    ))
            }
            
        }
        
        // MARK: - progress
        
        @Test
        func `save reports final progress`() async throws {
            var progressValues: [OperationProgress] = []
            
            _ = try await fetchLocal.save(
                [eventDTO],
                progress: { progressValues.append($0) }
            )
            
            let progress = try #require(progressValues.last)
            
            #expect(progress.completed == 1)
            #expect(progress.total == 1)
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)
        }
        
        @Test
        func `save reports progress every fifty events`() async throws {
            let dtos = (1...50).map { id in
                EventDTO(
                    id: EventID(NSNumber(value:id)),
                    name: "Event \(id)",
                    maxObservationForms: 100,
                    minObservationForms: 0,
                    description: "Event \(id) description",
                    acl: nil,
                    forms: [],
                    teams: [],
                    layers: [],
                    style: nil
                )
            }
            
            var progressValues: [OperationProgress] = []
            
            _ = try await fetchLocal.save(
                dtos,
                progress: { progressValues.append($0) }
            )
            
            #expect(progressValues.count == 2)
            
            #expect(progressValues[0].completed == 50)
            #expect(progressValues[0].total == 50)
            
            #expect(progressValues[1].completed == 50)
            #expect(progressValues[1].total == 50)
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 50)
        }
        
        let eventDTO = EventDTO(
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
    
}
