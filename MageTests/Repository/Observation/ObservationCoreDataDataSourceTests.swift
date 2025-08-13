//
//  ObservationCoreDataDataSourceTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/27/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine
import Nimble

@testable import MAGE

final class ObservationCoreDataDataSourceTests: MageCoreDataTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetLastObservationDateNoObservationsFromOtherUsers() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [observation, user])
            try? context.save()
        }
        
        let localDataSource = ObservationCoreDataDataSource()
        let lastObservation = localDataSource.getLastObservation(eventId: 1)
        
        XCTAssertNil(lastObservation)
        
        let lastDate = localDataSource.getLastObservationDate(eventId: 1)
        XCTAssertNil(lastDate)
    }
    
    func testGetLastObservationDateNoObservationsInEvent() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [observation, user])
            try? context.save()
        }
        
        let localDataSource = ObservationCoreDataDataSource()
        let lastObservation = localDataSource.getLastObservation(eventId: 2)
        
        XCTAssertNil(lastObservation)
        
        let lastDate = localDataSource.getLastObservationDate(eventId: 1)
        XCTAssertNil(lastDate)
    }
    
    func testGetLastObservationDate() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let user2 = User(context: context)
            user2.name = "Bob"
            user2.remoteId = "user2"
            user2.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            let observation2 = Observation(context: context)
            observation2.remoteId = "2"
            observation2.eventId = 1
            observation2.user = user2
            observation2.lastModified = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [observation, observation2, user, user2])
            try? context.save()
        }
        
        let localDataSource = ObservationCoreDataDataSource()
        let lastObservation = localDataSource.getLastObservation(eventId: 1)
        
        XCTAssertNotNil(lastObservation)
        XCTAssertEqual(lastObservation?.remoteId, "2")
        
        let lastDate = localDataSource.getLastObservationDate(eventId: 1)
        XCTAssertNotNil(lastDate)
        XCTAssertEqual(lastDate, Date(timeIntervalSince1970: 10000))
    }
    
    func testGetLastObservationDateSortedProperly() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let user2 = User(context: context)
            user2.name = "Bob"
            user2.remoteId = "user2"
            user2.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            let observation2 = Observation(context: context)
            observation2.remoteId = "2"
            observation2.eventId = 1
            observation2.user = user2
            observation2.lastModified = Date(timeIntervalSince1970: 10000)
            
            let observation3 = Observation(context: context)
            observation3.remoteId = "3"
            observation3.eventId = 1
            observation3.user = user2
            observation3.lastModified = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [observation, observation2, observation3, user, user2])
            try? context.save()
        }
        
        let localDataSource = ObservationCoreDataDataSource()
        let lastObservation = localDataSource.getLastObservation(eventId: 1)
        
        XCTAssertNotNil(lastObservation)
        XCTAssertEqual(lastObservation?.remoteId, "3")
        
        let lastDate = localDataSource.getLastObservationDate(eventId: 1)
        XCTAssertNotNil(lastDate)
        XCTAssertEqual(lastDate, Date(timeIntervalSince1970: 20000))
    }
    
    func testGetObservation() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let user2 = User(context: context)
            user2.name = "Bob"
            user2.remoteId = "user2"
            user2.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            let observation2 = Observation(context: context)
            observation2.remoteId = "2"
            observation2.eventId = 1
            observation2.user = user2
            observation2.lastModified = Date(timeIntervalSince1970: 10000)
            
            let observation3 = Observation(context: context)
            observation3.remoteId = "3"
            observation3.eventId = 1
            observation3.user = user2
            observation3.lastModified = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [observation, observation2, observation3, user, user2])
            try? context.save()
        }
        
        let localDataSource = ObservationCoreDataDataSource()
        let observation = await localDataSource.getObservation(remoteId: "1")
        
        XCTAssertNotNil(observation)
        XCTAssertEqual(observation?.remoteId, "1")
        
        let observationByUri = await localDataSource.getObservation(observationUri: observation?.observationId)
        
        XCTAssertNotNil(observationByUri)
        XCTAssertEqual(observationByUri?.remoteId, "1")

        let nilObservation = await localDataSource.getObservation(remoteId: nil)
        XCTAssertNil(nilObservation)
        
        let nilObservation2 = await localDataSource.getObservation(observationUri: nil)
        XCTAssertNil(nilObservation2)
    }
    
    func testObservationsPublisher() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        enum State {
            case loading
            case loaded(rows: [URIItem])
            case failure(error: Error)

            fileprivate var rows: [URIItem] {
                if case let .loaded(rows: rows) = self {
                    return rows
                } else {
                    return []
                }
            }
        }
        enum TriggerId: Hashable {
            case reload
            case loadMore
        }
        var state: State = .loading

        let trigger = Trigger()
        let localDataSource = ObservationCoreDataDataSource()

        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [observation, user])
            try? context.save()
        }
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.observationTimeFilterKey = .all
        
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.observations(
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map {
                return State.loaded(rows: $0)
            }
            .catch { error in
                XCTFail()
                return Just(State.failure(error: error))
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { recieve in
            switch(state, recieve) {
            case (.loaded, .loaded):
                state = recieve
            default:
                state = recieve
            }
        }
        .store(in: &cancellables)

        expect(state.rows.count).toEventually(equal(1))

        // insert another item
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: "remoteId", value: "user1")
            
            let observation = Observation(context: context)
            observation.remoteId = "2"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [observation])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows.count).toEventually(equal(2))
    }
    
    func testObservationsPublisherLoadMore() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        enum State {
            case loading
            case loaded(rows: [URIItem])
            case failure(error: Error)

            fileprivate var rows: [URIItem] {
                if case let .loaded(rows: rows) = self {
                    return rows
                } else {
                    return []
                }
            }
        }
        enum TriggerId: Hashable {
            case reload
            case loadMore
        }
        var state: State = .loading

        let trigger = Trigger()
        let localDataSource = ObservationCoreDataDataSource()
        localDataSource.fetchLimit = 1
        
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [observation, user])
            try? context.save()
        }
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.observationTimeFilterKey = .all
        
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.observations(
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map {
                return State.loaded(rows: $0)
            }
            .catch { error in
                XCTFail()
                return Just(State.failure(error: error))
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { recieve in
            switch(state, recieve) {
            case (.loaded, .loaded):
                state = recieve
            default:
                state = recieve
            }
        }
        .store(in: &cancellables)

        expect(state.rows.count).toEventually(equal(1))

        // insert another item
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: "remoteId", value: "user1")
            
            let observation = Observation(context: context)
            observation.remoteId = "2"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [observation])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.loadMore)
        expect(state.rows.count).toEventually(equal(2))
    }
    
    func testObservationsForUserPublisher() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        enum State {
            case loading
            case loaded(rows: [URIItem])
            case failure(error: Error)

            fileprivate var rows: [URIItem] {
                if case let .loaded(rows: rows) = self {
                    return rows
                } else {
                    return []
                }
            }
        }
        enum TriggerId: Hashable {
            case reload
            case loadMore
        }
        var state: State = .loading

        let trigger = Trigger()
        let localDataSource = ObservationCoreDataDataSource()
        
        var userUri: URL?
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let user2 = User(context: context)
            user2.name = "Bob"
            user2.remoteId = "user2"
            user2.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            let observation2 = Observation(context: context)
            observation2.remoteId = "2"
            observation2.eventId = 1
            observation2.user = user2
            observation2.lastModified = Date(timeIntervalSince1970: 10000)
            
            let observation3 = Observation(context: context)
            observation3.remoteId = "3"
            observation3.eventId = 1
            observation3.user = user2
            observation3.lastModified = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [observation, observation2, user, user2])
            userUri = user2.objectID.uriRepresentation()
            try? context.save()
        }
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.observationTimeFilterKey = .all
        
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.userObservations(
                userUri: userUri!,
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map {
                return State.loaded(rows: $0)
            }
            .catch { error in
                XCTFail()
                return Just(State.failure(error: error))
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { recieve in
            switch(state, recieve) {
            case (.loaded, .loaded):
                state = recieve
            default:
                state = recieve
            }
        }
        .store(in: &cancellables)

        expect(state.rows.count).toEventually(equal(2))

        // insert another item
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: "remoteId", value: "user1")
            let user2 = context.fetchFirst(User.self, key: "remoteId", value: "user2")
            
            let observation = Observation(context: context)
            observation.remoteId = "4"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 20000)
            
            let observation2 = Observation(context: context)
            observation2.remoteId = "5"
            observation2.eventId = 1
            observation2.user = user2
            observation2.lastModified = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [observation, observation2])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows.count).toEventually(equal(3))
    }
    
    func testObservationsForUserPublisherLoadMore() throws {
        try XCTSkipIf(persistence is MagicalRecordPersistence, "Magical record fails to use fetch offset properly")
        
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        enum State {
            case loading
            case loaded(rows: [URIItem])
            case failure(error: Error)

            fileprivate var rows: [URIItem] {
                if case let .loaded(rows: rows) = self {
                    return rows
                } else {
                    return []
                }
            }
        }
        enum TriggerId: Hashable {
            case reload
            case loadMore
        }
        var state: State = .loading

        let trigger = Trigger()
        let localDataSource = ObservationCoreDataDataSource()
        localDataSource.fetchLimit = 2
        
        var userUri: URL?
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = false
            
            let user2 = User(context: context)
            user2.name = "Bob"
            user2.remoteId = "user2"
            user2.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 20001)
            observation.timestamp = Date(timeIntervalSince1970: 20001)
            
            let observation2 = Observation(context: context)
            observation2.remoteId = "2"
            observation2.eventId = 1
            observation2.user = user2
            observation2.lastModified = Date(timeIntervalSince1970: 20000)
            observation2.timestamp = Date(timeIntervalSince1970: 20000)
            
            let observation3 = Observation(context: context)
            observation3.remoteId = "3"
            observation3.eventId = 1
            observation3.user = user2
            observation3.lastModified = Date(timeIntervalSince1970: 10003)
            observation3.timestamp = Date(timeIntervalSince1970: 10003)
            
            try? context.obtainPermanentIDs(for: [observation, observation2, user, user2])
            userUri = user2.objectID.uriRepresentation()
            try? context.save()
        }
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.observationTimeFilterKey = .all
        
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.userObservations(
                userUri: userUri!,
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map {
                return State.loaded(rows: $0)
            }
            .catch { error in
                XCTFail()
                return Just(State.failure(error: error))
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { recieve in
            switch(state, recieve) {
            case (.loaded, .loaded):
                state = recieve
            default:
                state = recieve
            }
        }
        .store(in: &cancellables)

        expect(state.rows.count).toEventually(equal(2))

        // insert another item
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: "remoteId", value: "user1")
            let user2 = context.fetchFirst(User.self, key: "remoteId", value: "user2")
            
            let observation = Observation(context: context)
            observation.remoteId = "4"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10002)
            observation.timestamp = Date(timeIntervalSince1970: 10002)
            
            let observation2 = Observation(context: context)
            observation2.remoteId = "5"
            observation2.eventId = 1
            observation2.user = user2
            observation2.lastModified = Date(timeIntervalSince1970: 10001)
            observation2.timestamp = Date(timeIntervalSince1970: 10001)
            
            try? context.obtainPermanentIDs(for: [observation, observation2])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.loadMore)
        expect(state.rows.count).toEventually(equal(3))
    }
    
    func testObserveObservation() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        
        var observationUri: URL?
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [observation, user])
            observationUri = observation.objectID.uriRepresentation()
            try? context.save()
        }
        
        let localDataSource = ObservationCoreDataDataSource()
                
        let uri = try! XCTUnwrap(observationUri)
        var first = false
        var second = false
        
        localDataSource.observeObservation(observationUri: uri)?
            .sink(receiveValue: { model in
                if model.lastModified == Date(timeIntervalSince1970: 10000) {
                    first = true
                }
                if model.lastModified == Date(timeIntervalSince1970: 20000) {
                    second = true
                }
            })
            .store(in: &cancellables)
        
        expect(first).toEventually(beTrue())
        
        context.performAndWait {
            let observation = context.fetchFirst(Observation.self, key: "remoteId", value: "1")
            observation?.lastModified = Date(timeIntervalSince1970: 20000)
            try? context.save()
        }
        
        expect(second).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5))
    }
    
    func testObserveObservationFavorites() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        
        var observationUri: URL?
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let user2 = User(context: context)
            user2.name = "Bob"
            user2.remoteId = "user2"
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            let favorite = ObservationFavorite(context: context)
            favorite.observation = observation
            favorite.favorite = true
            favorite.userId = "user1"
            
            try? context.obtainPermanentIDs(for: [observation, user, favorite])
            observationUri = observation.objectID.uriRepresentation()
            try? context.save()
        }
        
        let localDataSource = ObservationCoreDataDataSource()
        
        let uri = try! XCTUnwrap(observationUri)
        var first = false
        var second = false
        
        localDataSource.observeObservationFavorites(observationUri: uri)?
            .sink(receiveValue: { model in
                if model.favoriteUsers?.count == 1 {
                    first = true
                }
                if model.favoriteUsers?.count == 2 {
                    second = true
                }
            })
            .store(in: &cancellables)
        
        expect(first).toEventually(beTrue())
        
        context.performAndWait {
            let observation = context.fetchFirst(Observation.self, key: "remoteId", value: "1")
            
            let favorite = ObservationFavorite(context: context)
            favorite.observation = observation
            favorite.favorite = true
            favorite.userId = "user2"
            
            try? context.save()
        }
        
        expect(second).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5))
    }
    
    func testObservationFilteredCountPublisher() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        let localDataSource = ObservationCoreDataDataSource()

        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [observation, user])
            try? context.save()
        }
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.observationTimeFilterKey = .all
        
        var count = 0
        
        localDataSource.observeFilteredCount()?
            .sink(receiveValue: { filteredCount in
                count = filteredCount
            })
            .store(in: &cancellables)

        expect(count).toEventually(equal(1))

        // insert another item
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: "remoteId", value: "user1")
            
            let observation = Observation(context: context)
            observation.remoteId = "2"
            observation.eventId = 1
            observation.user = user
            observation.lastModified = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [observation])
            try? context.save()
        }
        
        expect(count).toEventually(equal(2))
    }
    
}
