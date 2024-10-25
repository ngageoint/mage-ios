//
//  LocationCoreDataDataSourceTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine
import Nimble

@testable import MAGE

final class LocationCoreDataDataSourceTests: MageCoreDataTestCase {

    func testGetLocation() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3678, andY: 40.1085))
            location.remoteId = "location1"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [location, user])
            try? context.save()
        }
        
        let localDataSource = LocationCoreDataDataSource()
        
        var locationUri: URL?
        
        context.performAndWait {
            let locations = context.fetchAll(Location.self)
            locationUri = locations?[0].objectID.uriRepresentation()
        }
        
        let uri = try! XCTUnwrap(locationUri)
        
        guard let model = await localDataSource.getLocation(uri: uri) else {
            XCTFail("No Location found")
            return
        }
        
        XCTAssertEqual(model.locationUri, uri)
        XCTAssertEqual(model.location!.coordinate.latitude, 40.1085, accuracy: 0.00001)
        XCTAssertEqual(model.location!.coordinate.longitude, -104.3678, accuracy: 0.00001)
        XCTAssertEqual(model.coordinate!.latitude, 40.1085, accuracy: 0.00001)
        XCTAssertEqual(model.coordinate!.longitude, -104.3678, accuracy: 0.00001)
        XCTAssertEqual(model.timestamp, Date(timeIntervalSince1970: 10000))
        XCTAssertEqual(model.eventId, 1)
        
        XCTAssertEqual(model.userModel?.remoteId, "user1")
    }
    
    func testObserveLocation() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3678, andY: 40.1085))
            location.remoteId = "location1"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [location, user])
            try? context.save()
        }
        
        let localDataSource = LocationCoreDataDataSource()
        
        var locationUri: URL?
        
        context.performAndWait {
            let locations = context.fetchAll(Location.self)
            locationUri = locations?[0].objectID.uriRepresentation()
        }
        
        let uri = try! XCTUnwrap(locationUri)
        var first = false
        var second = false
        
        localDataSource.observeLocation(locationUri: uri)?
            .sink(receiveValue: { model in
                if model.timestamp == Date(timeIntervalSince1970: 10000) {
                    first = true
                }
                if model.timestamp == Date(timeIntervalSince1970: 20000) {
                    second = true
                }
            })
            .store(in: &cancellables)
        
        expect(first).toEventually(beTrue())
        
        context.performAndWait {
            let location = context.fetchFirst(Location.self, key: "remoteId", value: "location1")
            location?.timestamp = Date(timeIntervalSince1970: 20000)
            try? context.save()
        }
        
        expect(second).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5))
    }
    
    func testObserveLatestFiltered() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.locationTimeFilter = .all
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3678, andY: 40.1085))
            location.remoteId = "location1"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [location, user])
            try? context.save()
        }
        
        let localDataSource = LocationCoreDataDataSource()
        
        var first = false
        var second = false
        
        localDataSource.observeLatestFiltered()?
            .sink(receiveValue: { model in
                if model == Date(timeIntervalSince1970: 10000) {
                    first = true
                }
                if model == Date(timeIntervalSince1970: 20000) {
                    second = true
                }
            })
            .store(in: &cancellables)
        
        expect(first).toEventually(beTrue())
        
        context.performAndWait {
            let location = context.fetchFirst(Location.self, key: "remoteId", value: "location1")
            location?.timestamp = Date(timeIntervalSince1970: 20000)
            try? context.save()
        }
        
        expect(second).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5))
    }
    
    func testLocationsPublisher() {
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
        let localDataSource = LocationCoreDataDataSource()

        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3678, andY: 40.1085))
            location.remoteId = "location1"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [location, user])
            try? context.save()
        }
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.locationTimeFilter = .all
        
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.locations(
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
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3679, andY: 40.1086))
            location.remoteId = "location2"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [location])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows.count).toEventually(equal(2))
    }
    
    func testLocationsPublisherLodMore() {
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
        let localDataSource = LocationCoreDataDataSource()
        localDataSource.fetchLimit = 1

        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3678, andY: 40.1085))
            location.remoteId = "location1"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [location, user])
            try? context.save()
        }
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.locationTimeFilter = .all
        
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.locations(
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
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3679, andY: 40.1086))
            location.remoteId = "location2"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [location])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.loadMore)
        expect(state.rows.count).toEventually(equal(2))
        
    }
    
    func testLocationsPublisherWithUsers() {
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
        let localDataSource = LocationCoreDataDataSource()
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.locationTimeFilter = .all
        
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3678, andY: 40.1085))
            location.remoteId = "location1"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 10000)
            
            let user2 = User(context: context)
            user2.name = "Bob"
            user2.remoteId = "user2"
            user2.currentUser = true
            
            let location2 = Location(context: context)
            location2.type = "Feature"
            location2.eventId = 1
            location2.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location2.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3678, andY: 40.1085))
            location2.remoteId = "location2"
            location2.user = user2
            location2.timestamp = Date(timeIntervalSince1970: 10000)
            
            try? context.obtainPermanentIDs(for: [location, user, location2, user2])
            try? context.save()
        }

        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.locations(
                userIds: ["user2"],
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
            let user = context.fetchFirst(User.self, key: "remoteId", value: "user2")
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3679, andY: 40.1086))
            location.remoteId = "location2"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [location])
            try? context.save()
        }
        
        var locationUri: URL?
        context.performAndWait {
            let location = context.fetchFirst(Location.self, key: "remoteId", value: "location2")
            locationUri = location?.objectID.uriRepresentation()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows[0].id).toEventually(equal(locationUri?.absoluteString))
        expect(state.rows.count).toEventually(equal(1))
    }
    
    func testLocationsPublisherLodMoreWithUsers() {
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
        let localDataSource = LocationCoreDataDataSource()
        localDataSource.fetchLimit = 1
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.locationTimeFilter = .all
        
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3678, andY: 40.1085))
            location.remoteId = "location1"
            location.user = user
            location.timestamp = Date(timeIntervalSince1970: 10000)

            try? context.obtainPermanentIDs(for: [location, user])
            try? context.save()
        }

        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.locations(
                userIds: ["user1", "user2"],
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
            let user2 = User(context: context)
            user2.name = "Bob"
            user2.remoteId = "user2"
            user2.currentUser = true
            
            let location = Location(context: context)
            location.type = "Feature"
            location.eventId = 1
            location.properties =  [
                "timestamp": "2020-07-14T19:07:36.000Z",
                "accuracy": 266.16473,
                "altitude": 1696.56640625,
                "battery_level": "100",
                "bearing": 0,
                "provider": "gps",
                "speed": 0,
                "deviceId": "deviceabc"
            ]
            location.geometryData = SFGeometryUtils.encode(SFPoint(x: -104.3679, andY: 40.1086))
            location.remoteId = "location2"
            location.user = user2
            location.timestamp = Date(timeIntervalSince1970: 20000)
            
            try? context.obtainPermanentIDs(for: [user2, location])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.loadMore)
        expect(state.rows.count).toEventually(equal(2))
        
    }
}
