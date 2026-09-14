// 
//     
//  TeamFetchLocalImplTests.swift
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

@testable import ServerDTO
@testable import EventFetch

extension CoreDataTests {

    struct TeamFetchLocalImplTests{
        
        let persistence: PersistenceProtocol
        private let fetchLocal: TeamFetchLocalImpl
        
        init() {
            persistence = PersistenceContext.current!.persistence
            fetchLocal = TeamFetchLocalImpl(
                persistence: persistence
            )
        }
        
        @Test
        func `save inserts new team`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = 1
                try? context.obtainPermanentIDs(for: [event])
            }
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)
            
            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: [
                    TeamDTO.from(jsonObject: [
                        "id": "teamabc",
                        "name": "Animal",
                        "description": "Animal team",
                        "teamEventId": 1,
                        "userIds": []
                    ])!
                ]
            )
            
            let result = try await fetchLocal.save(
                [dto],
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            #expect(result.updated == 0)
            #expect(result.totalChanged == 1)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    persistence,
                    Team.self,
                    1,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        TeamKey.remoteId.key,
                        "teamabc"
                    )
                )
            
            let team = try #require(await persistence.read { context in
                context.fetchFirst(
                    Team.self,
                    key: TeamKey.remoteId.key,
                    value: "teamabc"
                ).map { TeamModel.init(from: $0) }
            })
            
            #expect(team.name == "Animal")
        }
        
        @Test
        func `save updates existing team associated with event`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = 1
                
                let team = Team(context: context)
                team.remoteId = "teamabc"
                team.name = "Old name"
                event.addToTeams(team)
                try? context.obtainPermanentIDs(for: [event, team])
            }
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    persistence,
                    Team.self,
                    1,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        TeamKey.remoteId.key,
                        "teamabc"
                    )
                )

            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: [
                    TeamDTO.from(jsonObject: [
                        "id": "teamabc",
                        "name": "New name",
                        "description": "Updated team",
                        "teamEventId": 1,
                        "userIds": []
                    ])!
                ]
            )
            
            let result = try await fetchLocal.save(
                [dto],
                progress: { _ in }
            )
            
            #expect(result.inserted == 0)
            #expect(result.updated == 1)
            #expect(result.totalChanged == 1)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    persistence,
                    Team.self,
                    1,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        TeamKey.name.key,
                        "New name"
                    )
                )
            
            try await persistence.read { context in
                let event = try #require(context.fetchFirst(Event.self, key: EventKey.remoteId.key, value: 1))
                #expect(event.teams?.count == 1)
                #expect(event.teams?.first?.name == "New name")
            }
        }
        
        @Test
        func `save updates existing team found outside event relationship`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = 1
                
                let team = Team(context: context)
                team.remoteId = "teamabc"
                team.name = "Old name"
                try? context.obtainPermanentIDs(for: [event, team])
            }
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    persistence,
                    Team.self,
                    1,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        TeamKey.remoteId.key,
                        "teamabc"
                    )
                )
            
            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: [
                    TeamDTO.from(jsonObject: [
                        "id": "teamabc",
                        "name": "New name",
                        "description": "Updated team",
                        "teamEventId": 1,
                        "userIds": []
                    ])!
                ]
            )
            
            let result = try await fetchLocal.save(
                [dto],
                progress: { _ in }
            )
            
            #expect(result.inserted == 0)
            #expect(result.updated == 1)
            #expect(result.totalChanged == 1)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    persistence,
                    Team.self,
                    1,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        TeamKey.name.key,
                        "New name"
                    )
                )
            
            try await persistence.read { context in
                let event = try #require(context.fetchFirst(Event.self, key: EventKey.remoteId.key, value: 1))
                #expect(event.teams?.count == 1)
                #expect(event.teams?.first?.name == "New name")
            }
        }
        
        @Test
        func `save skips team when event does not exist`() async throws {
            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: [
                    TeamDTO.from(jsonObject: [
                        "id": "teamabc",
                        "name": "Animal",
                        "description": "Animal team",
                        "teamEventId": 1,
                        "userIds": []
                    ])!
                ]
            )
            
            let result = try await fetchLocal.save(
                [dto],
                progress: { _ in }
            )
            
            #expect(result == .empty)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    persistence,
                    Team.self,
                    0,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        TeamKey.remoteId.key,
                        "teamabc"
                    )
                )
        }
        
        @Test
        func `save creates new users and associates them with team`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = 1
                
                try? context.obtainPermanentIDs(for: [event,])
            }
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)
            
            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: [
                    TeamDTO.from(jsonObject: [
                        "id": "teamabc",
                        "name": "Animal",
                        "description": "Animal team",
                        "teamEventId": 1,
                        "userIds": ["userabc", "userdef"]
                    ])!
                ]
            )
            
            let result = try await fetchLocal.save(
                [dto],
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            #expect(result.updated == 0)
            
            await PersistenceTestUtilities
                .waitForCountOfEntity(
                    persistence,
                    Team.self,
                    1,
                    predicate: NSPredicate(
                        format: "%K == %@",
                        TeamKey.remoteId.key,
                        "teamabc"
                    )
                )
            
            try await persistence.read { context in
                let event = try #require(context.fetchFirst(Event.self, key: EventKey.remoteId.key, value: 1))
                #expect(event.teams?.count == 1)
                #expect(event.teams?.first?.users?.count == 2)
                
                let userIDs = Set(
                    event.teams?.first?.users?.compactMap(\.remoteId) ?? []
                )
                
                #expect(userIDs == ["userabc", "userdef"])
            }
        }
        
        @Test
        func `save reuses existing users`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = 1
                
                let user = User(context: context)
                user.remoteId = "userabc"
                try? context.obtainPermanentIDs(for: [event, user])
            }
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, User.self, 1)

            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: [
                    TeamDTO.from(jsonObject: [
                        "id": "teamabc",
                        "name": "Animal",
                        "description": "Animal team",
                        "teamEventId": 1,
                        "userIds": ["userabc"]
                    ])!
                ]
            )
            
            let result = try await fetchLocal.save(
                [dto],
                progress: { _ in }
            )
            
            #expect(result.inserted == 1)
            #expect(result.updated == 0)
            
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Team.self, 1)

            let team = try #require(await persistence.read { context in
                context.fetchFirst(
                    Team.self,
                    key: TeamKey.remoteId.key,
                    value: "teamabc"
                ).map { TeamModel.init(from: $0) }
            })
            
            #expect(team.users?.count == 1)
            #expect(team.users?.first?.remoteId == "userabc")
        }
        
        @Test
        func `save does not create users when userIds is empty`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = 1

                try? context.obtainPermanentIDs(for: [event])
            }
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)
            
            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: [
                    TeamDTO.from(jsonObject: [
                        "id": "teamabc",
                        "name": "Animal",
                        "description": "Animal team",
                        "teamEventId": 1,
                        "userIds": []
                    ])!
                ]
            )
            
            _ = try await fetchLocal.save(
                [dto],
                progress: { _ in }
            )
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Team.self, 1)

            let team = try #require(await persistence.read { context in
                context.fetchFirst(
                    Team.self,
                    key: TeamKey.remoteId.key,
                    value: "teamabc"
                ).map { TeamModel.init(from: $0) }
            })
            
            #expect(team.users?.count == 0)
        }
        
        @Test
        func `save reports final progress`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = 1
                
                try? context.obtainPermanentIDs(for: [event])
            }
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)

            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: [
                    TeamDTO.from(jsonObject: [
                        "id": "teamabc",
                        "name": "Animal",
                        "description": "Animal team",
                        "teamEventId": 1,
                        "userIds": []
                    ])!
                ]
            )
            
            var progressValues: [OperationProgress] = []
            
            _ = try await fetchLocal.save(
                [dto],
                progress: {
                    progressValues.append($0)
                }
            )
            
            let progress = try #require(progressValues.last)
            
            #expect(progress.completed == 1)
            #expect(progress.total == 1)
        }
        
        @Test
        func `save reports progress every five changed teams`() async throws {
            _ = try await persistence.write { context in
                let event = Event(context: context)
                event.remoteId = 1
                
                try? context.obtainPermanentIDs(for: [event])
            }
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 1)
            
            let teams = (1...6).map { index in
                TeamDTO.from(jsonObject: [
                    "id": "team\(index)",
                    "name": "Team \(index)",
                    "description": "Team \(index)",
                    "teamEventId": 1,
                    "userIds": []
                ])!
            }
            
            let dto = EventTeamDTO(
                eventID: EventID(1),
                teamDTO: teams
            )
            
            var progressValues: [OperationProgress] = []
            
            let result = try await fetchLocal.save(
                [dto],
                progress: {
                    progressValues.append($0)
                }
            )
            
            #expect(result.totalChanged == 6)
            #expect(progressValues.count == 2)
            
            #expect(progressValues[0].completed == 5)
            #expect(progressValues[0].total == 1)
            
            #expect(progressValues[1].completed == 6)
            #expect(progressValues[1].total == 1)
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
    
}
