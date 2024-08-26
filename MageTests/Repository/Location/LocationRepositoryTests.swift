//
//  LocationRepositoryTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine
import Nimble

@testable import MAGE

final class LocationRepositoryTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable> = Set()
    let localDataSource = LocationStaticLocalDataSource()

    override func setUp() {
        InjectedValues[\.locationLocalDataSource] = localDataSource
    }
    
    override func tearDown() {
        cancellables.removeAll()
    }
    
    func testGetLocation() async {
        localDataSource.locationModels = [
            LocationModel(
                locationUri: URL(string: "magetest://location/1")!
            ),
            LocationModel(
                locationUri: URL(string: "magetest://location/2")!
            )
        ]
                
        let locationRepostory = LocationRepository()
        
        let location = await locationRepostory.getLocation(locationUri: URL(string: "magetest://location/1")!)
        XCTAssertNotNil(location)
        XCTAssertEqual(location?.locationUri, URL(string: "magetest://location/1"))
    }
    
    func testObserveLocation() {
        let model = LocationModel(
            locationUri: URL(string: "magetest://location/1")!,
            timestamp: Date(timeIntervalSince1970: 100000)
        )
        localDataSource.locationModels = [
            model
        ]
        
        var first: Bool = false
        var second: Bool = false
        
        let locationRepository = LocationRepository()
        locationRepository.observeLocation(locationUri: URL(string: "magetest://location/1")!)?
            .sink(receiveValue: { model in
                if model.timestamp == Date(timeIntervalSince1970: 100000) {
                    first = true
                }
                if model.timestamp == Date(timeIntervalSince1970: 200000) {
                    second = true
                }
            })
            .store(in: &cancellables)
        
        expect(first).toEventually(beTrue())
        
        localDataSource.updateLocation(locationUri: URL(string: "magetest://location/1")!, model: LocationModel(
            locationUri: URL(string: "magetest://location/1")!,
            timestamp: Date(timeIntervalSince1970: 200000)
        ))
        
        expect(second).toEventually(beTrue())
    }
    
    func testObserveLatest() {
        var first: Bool = false
        
        let locationRepository = LocationRepository()
        locationRepository.observeLatestFiltered()?
            .sink(receiveValue: { model in
                if model == Date(timeIntervalSince1970: 100000) {
                    first = true
                }
            })
            .store(in: &cancellables)
        
        localDataSource.setLatest(date: Date(timeIntervalSince1970: 100000))
        
        expect(first).toEventually(beTrue())
    }
    
    func testLocationsPublisher() {
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
        let locationRepository = LocationRepository()
        
        let model = LocationModel(
            locationUri: URL(string: "magetest://location/1")!,
            timestamp: Date(timeIntervalSince1970: 100000)
        )
        localDataSource.locationModels = [
            model
        ]

        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, locationRepository] in
            locationRepository.locations(
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
        localDataSource.locationModels += [
            LocationModel(
                locationUri: URL(string: "magetest://location/2")!,
                timestamp: Date(timeIntervalSince1970: 200000)
            )
        ]

        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows.count).toEventually(equal(2))
    }
    
    func testRefreshPublisher() {
        var repository = LocationRepository()
        
        var published = false
        
        UserDefaults.standard.locationTimeFilter = .all
        UserDefaults.standard.locationTimeFilterUnit = .Hours
        UserDefaults.standard.locationTimeFilterNumber = 1

        repository.refreshPublisher?.sink(receiveValue: { value in
            published = true
        })
        .store(in: &cancellables)
        
        expect(published).to(beFalse())
        
        UserDefaults.standard.locationTimeFilter = .lastMonth
        expect(published).toEventually(beTrue())
        
        published = false
        UserDefaults.standard.locationTimeFilterUnit = .Days
        expect(published).toEventually(beTrue())
        
        published = false
        UserDefaults.standard.locationTimeFilterNumber = 2
        expect(published).toEventually(beTrue())
    }
}
