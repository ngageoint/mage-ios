//
//  BottomSheetRepositoryTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine

@testable import MAGE

final class BottomSheetRepositoryTests: XCTestCase {
    
    var userRepository = UserRepositoryMock()
    var feedItemRepository = FeedItemRepositoryMock()
    var observationLocationRepository = ObservationLocationRepositoryMock()
    var geoPackageRepositoryMock = GeoPackageRepositoryMock()
    
    var cancellables: Set<AnyCancellable> = Set()
    
    override func setUp() {
        InjectedValues[\.observationLocationRepository] = observationLocationRepository
        InjectedValues[\.userRepository] = userRepository
        InjectedValues[\.feedItemRepository] = feedItemRepository
        InjectedValues[\.geoPackageRepository] = geoPackageRepositoryMock
    }
    
    override func tearDown() {
        cancellables.removeAll()
    }

    func testSettingItemKey() {
        observationLocationRepository.list = [
            ObservationMapItem(
                observationId: URL(string: "magetest://observation/1"),
                observationLocationId: URL(string: "magetest://observationLocation/1")
            )
        ]
        
        let bottomSheetRepository = BottomSheetRepository()
        
        XCTAssertTrue((bottomSheetRepository.bottomSheetItems ?? []).isEmpty)
        
        let expectation = XCTestExpectation(description: "Adds 1 bottom sheet item")
        
        bottomSheetRepository.$bottomSheetItems
            .dropFirst()
            .compactMap { $0 }
            .sink(receiveValue: {
                XCTAssertEqual($0.count, 1)
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        bottomSheetRepository.setItemKeys(itemKeys: [DataSources.observation.key: ["magetest://observationLocation/1"]])
        wait(for: [expectation], timeout: 1)
        
    }
    
    func testSettingItemKeys() {
        observationLocationRepository.list = [
            ObservationMapItem(
                observationId: URL(string: "magetest://observation/1"),
                observationLocationId: URL(string: "magetest://observationLocation/1")
            ),
            ObservationMapItem(
                observationId: URL(string: "magetest://observation/1"),
                observationLocationId: URL(string: "magetest://observationLocation/2")
            )
        ]
        
        userRepository.users = [
            UserModel(userId: URL(string: "magetest://user/1"))
        ]
        
        feedItemRepository.items = [
            FeedItemModel(feedItemId: URL(string: "magetest://feedItem/1")!, coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        ]
        
        geoPackageRepositoryMock.items = [
            GeoPackageFeatureItem(featureId: 1, geoPackageName: "name", featureRowData: nil, layerName: "layer", tableName: "table")
        ]
        
        
        let bottomSheetRepository = BottomSheetRepository()
        
        XCTAssertTrue((bottomSheetRepository.bottomSheetItems ?? []).isEmpty)
        
        var shouldClear = false
        
        let expectation = XCTestExpectation(description: "Adds 6 bottom sheet items")
        let clearExpectation = XCTestExpectation(description: "Clears list")
        
        bottomSheetRepository.$bottomSheetItems
            .dropFirst()
            .sink(receiveValue: {
                if !shouldClear {
                    XCTAssertEqual($0?.count, 6)
                    expectation.fulfill()
                } else {
                    XCTAssertNil($0)
                    clearExpectation.fulfill()
                }
            })
            .store(in: &cancellables)
        
        bottomSheetRepository.setItemKeys(
            itemKeys: [
                DataSources.observation.key: [
                    "magetest://observationLocation/1",
                    "magetest://observationLocation/2"
                ],
                DataSources.user.key: [
                    "magetest://user/1"
                ],
                DataSources.feedItem.key: [
                    "magetest://feedItem/1"
                ],
                DataSources.geoPackage.key: [
                    GeoPackageFeatureKey(geoPackageName: "name", featureId: 1, layerName: "layer", tableName: "table").toKey()
                ],
                DataSources.featureItem.key: [
                    FeatureItem(featureId: 2).toKey()
                ]
            ]
        )
        wait(for: [expectation], timeout: 1)
        
        // clear the list
        shouldClear = true
        bottomSheetRepository.setItemKeys(itemKeys: nil)
        wait(for: [clearExpectation], timeout: 1)
    }
}
