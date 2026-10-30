//
//  RecentEventsTests.swift
//  MAGE
//

import Testing
import Persistence
import CoreData

@testable import MAGE

extension CoreDataTests {
    struct RecentEventsTests {
        let persistence: PersistenceProtocol

        init() {
            persistence = PersistenceContext.current!.persistence
        }

        @Test @MainActor
        func `recent events are ordered by the user's recent event ids`() async throws {
            _ = try await persistence.write { context in
                let user = User(context: context)
                user.remoteId = "userabc"
                user.recentEventIds = [3, 1, 2]
                for id in [1, 2, 3] {
                    let event = Event(context: context)
                    event.remoteId = NSNumber(value: id)
                    event.name = "Event \(id)"
                }
                try? context.obtainPermanentIDs(for: Array(context.insertedObjects))
            }
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, Event.self, 3)
            await PersistenceTestUtilities.waitForCountOfEntity(persistence, User.self, 1)
            UserDefaults.standard.currentUserId = "userabc"

            let dataSource = EventTableDataSource()
            dataSource.refreshEventData()

            #expect(dataSource.recentEvents.map { $0.remoteId } == [3, 1, 2])
        }

        @Test
        func `adding a recent event moves it to the front`() async throws {
            await persistence.read { context in
                let user = User(context: context)
                user.recentEventIds = [3, 1, 2]

                user.addRecentEvent(eventId: 2)
                #expect(user.recentEventIds == [2, 3, 1])

                user.addRecentEvent(eventId: 4)
                #expect(user.recentEventIds == [4, 2, 3, 1])

                context.rollback()
            }
        }
    }
}
