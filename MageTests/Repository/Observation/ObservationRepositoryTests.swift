//
//  ObservationRepositoryTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/27/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine
import Nimble

@testable import MAGE

final class ObservationRepositoryTests: XCTestCase {

    var cancellables: Set<AnyCancellable> = Set()
    var localDataSource: ObservationStaticLocalDataSource!
    var remoteDataSource: ObservationRemoteDataSourceMock!

    override func setUp() {
        localDataSource = ObservationStaticLocalDataSource()
        InjectedValues[\.observationLocalDataSource] = localDataSource
        remoteDataSource = ObservationRemoteDataSourceMock()
        InjectedValues[\.observationRemoteDataSource] = remoteDataSource
    }
    
    override func tearDown() {
        cancellables.removeAll()
    }
    
    func testRefreshPublisher() {
        let repository = ObservationRepository()
        
        var published = false
        
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.observationTimeFilterKey = .all
        UserDefaults.standard.observationTimeFilterUnitKey = .Hours
        UserDefaults.standard.observationTimeFilterNumberKey = 1

        repository.refreshPublisher?.sink(receiveValue: { value in
            published = true
        })
        .store(in: &cancellables)
        
        expect(published).to(beFalse())
        
        UserDefaults.standard.observationTimeFilterKey = .lastMonth
        expect(published).toEventually(beTrue())
        
        published = false
        UserDefaults.standard.observationTimeFilterUnitKey = .Days
        expect(published).toEventually(beTrue())
        
        published = false
        UserDefaults.standard.observationTimeFilterNumberKey = 2
        expect(published).toEventually(beTrue())
        
        published = false
        NotificationCenter.default.post(Notification(name: .MAGEFormFetched, object: EventModel(remoteId: 1)))
        expect(published).toEventually(beTrue())
    }
    
    func testObserveFilteredCount() {
        
        var count: Int = 0
        
        let repository = ObservationRepository()
        repository.observeFilteredCount()?
            .sink(receiveValue: { publishedCount in
                count = publishedCount
            })
            .store(in: &cancellables)
        
        localDataSource.list.append(
            ObservationModel(
                observationId: URL(string: "magetest://observation/1"),
                eventId: 1
            )
        )
        
        expect(count).toEventually(equal(1))
    }
    
    func testPublisher() {
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
        let repository = ObservationRepository()
        
        let model = ObservationModel(
            observationId: URL(string: "magetest://observation/1")!,
            eventId: 1
        )
        localDataSource.list.append(model)

        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, repository] in
            repository.observations(
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map { State.loaded(rows: $0) }
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
        localDataSource.list.append(
            ObservationModel(
                observationId: URL(string: "magetest://observation/2")!,
                eventId: 1
            )
        )

        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows.count).toEventually(equal(2))
    }

    func testObservationUserPublisher() {
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
        let repository = ObservationRepository()
        
        let model = ObservationModel(
            observationId: URL(string: "magetest://observation/1")!,
            eventId: 1,
            userId: URL(string: "magetest://user/1")
        )
        localDataSource.list.append(model)
        localDataSource.list.append(ObservationModel(
            observationId: URL(string: "magetest://observation/2")!,
            eventId: 1,
            userId: URL(string: "magetest://user/2")
        ))

        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, repository] in
            repository.userObservations(
                userUri: URL(string: "magetest://user/1")!,
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map { State.loaded(rows: $0) }
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
        localDataSource.list.append(
            ObservationModel(
                observationId: URL(string: "magetest://observation/3")!,
                eventId: 1,
                userId: URL(string: "magetest://user/1")
            )
        )

        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows.count).toEventually(equal(2))
    }
    
    func testObserveObservation() {
        localDataSource.list = [
            ObservationModel(
                observationId: URL(string: "magetest://observation/1")!,
                eventId: 1,
                userId: URL(string: "magetest://user/1"),
                lastModified: Date(timeIntervalSince1970: 100000)
            )
        ]
        
        var lastModified: Date = Date(timeIntervalSince1970: 0)
        
        let repository = ObservationRepository()
        repository.observeObservation(observationUri: URL(string: "magetest://observation/1")!)?
            .sink(receiveValue: { model in
                lastModified = model.lastModified!
            })
            .store(in: &cancellables)
        
        expect(lastModified).toEventually(equal(Date(timeIntervalSince1970: 100000)))
        
        localDataSource.updateObservation(
            observationUri: URL(string: "magetest://observation/1")!,
            model: ObservationModel(
                observationId: URL(string: "magetest://observation/1")!,
                eventId: 1,
                userId: URL(string: "magetest://user/1"),
                lastModified: Date(timeIntervalSince1970: 200000)
            )
        )
        
        expect(lastModified).toEventually(equal(Date(timeIntervalSince1970: 200000)))
    }
    
    func testGetObservation() async {
        localDataSource.list = [
            ObservationModel(
                observationId: URL(string: "magetest://observation/1")!,
                remoteId: "1",
                eventId: 1,
                userId: URL(string: "magetest://user/1"),
                lastModified: Date(timeIntervalSince1970: 100000)
            ),
            ObservationModel(
                observationId: URL(string: "magetest://observation/2")!,
                remoteId: "2",
                eventId: 1,
                userId: URL(string: "magetest://user/2"),
                lastModified: Date(timeIntervalSince1970: 100000)
            )
        ]
        
        let repository = ObservationRepository()
        let observation = await repository.getObservation(remoteId: "1")
        XCTAssertNotNil(observation)
        XCTAssertEqual(observation?.remoteId, "1")
        
        let observationByUri = await repository.getObservation(observationUri: URL(string:"magetest://observation/1"))
        XCTAssertNotNil(observationByUri)
        XCTAssertEqual(observationByUri?.remoteId, "1")
    }
    
    func testFetchObservations() async {
        localDataSource.list = [
            ObservationModel(
                observationId: URL(string: "magetest://observation/1")!,
                remoteId: "1",
                eventId: 1,
                userId: URL(string: "magetest://user/1"),
                lastModified: Date(timeIntervalSince1970: 100000)
            )
        ]
        
        let repository = ObservationRepository()
        
        remoteDataSource.fetchResponseToSend = [["remoteId": "1"]]
        UserDefaults.standard.currentEventId = 1
        let inserted = await repository.fetchObservations()
        
        XCTAssertEqual(inserted, 1)
        XCTAssertNotNil(remoteDataSource.fetchDate)
        XCTAssertEqual(remoteDataSource.fetchDate, Date(timeIntervalSince1970: 100000))
        XCTAssertNotNil(remoteDataSource.fetchEvent)
        XCTAssertEqual(remoteDataSource.fetchEvent, 1)
    }
    
    func testObserveObservationFavorites() {
        UserDefaults.standard.currentUserId = "user1"
        
        localDataSource.observationFavorites[URL(string: "magetest://observation/1")!] = ObservationFavoritesModel(
            observationId: URL(string: "magetest://observation/1"),
            favoriteUsers: ["user1"]
        )
        
        var first = false
        var second = false
        
        let repository = ObservationRepository()
        
        repository.observeObservationFavorites(observationUri: URL(string: "magetest://observation/1"))?
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
        
        localDataSource.addFavoriteToObservation(
            observationUri: URL(string: "magetest://observation/1")!,
            userRemoteId: "user2"
        )

        expect(second).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5))
    }

}
