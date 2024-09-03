//
//  ObservationCoreDataSourceTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

@testable import MAGE

final class ObservationCoreDataSourceTests: XCTestCase {
    
    var coreDataStack: TestCoreDataStack?
    var context: NSManagedObjectContext?

    override func setUp() {
        coreDataStack = TestCoreDataStack()
        context = coreDataStack!.persistentContainer.newBackgroundContext()
        InjectedValues[\.nsManagedObjectContext] = context
        
//        while (!cleared) {
//            let clearMap = TestHelpers.clearAndSetUpStack()
//            cleared = (clearMap[String(describing: Observation.self)] ?? false) && (clearMap[String(describing: ObservationLocation.self)] ?? false)
//
//            if (!cleared) {
//                cleared = Observation.mr_findAll(in: context)?.count == 0 && ObservationLocation.mr_findAll(in: context)?.count == 0
//            }
//
//            if (!cleared) {
//                Thread.sleep(forTimeInterval: 0.5);
//            }
//
//        }
//
//        let e = XCTNSPredicateExpectation(predicate: NSPredicate(block: { context, change in
//            guard let context = context as? NSManagedObjectContext else {
//                return false
//            }
//            if let count = Observation.mr_findAll(in: context)?.count {
//                return count == 0
//            }
//            return false
//        }), object: context)
//        //        wait(for: [e], timeout: 10)
//
//        let e2 = XCTNSPredicateExpectation(predicate: NSPredicate(block: { context, change in
//            guard let context = context as? NSManagedObjectContext else {
//                return false
//            }
//            if let count = Observation.mr_findAll(in: context)?.count {
//                return count == 0
//            }
//            return false
//        }), object: NSManagedObjectContext.mr_rootSaving())
//        wait(for: [e, e2], timeout: 10)
    }

    override func tearDown() {
        InjectedValues[\.nsManagedObjectContext] = nil
        coreDataStack!.reset()
    }

    func xtestGetObservationMapItemsWithBounds() async {
        Server.setCurrentEventId(1)
        TimeFilter.setObservation(.all)
        MageCoreDataFixtures.addEvent(context: context!, remoteId: 1, name: "Event", formsJsonFile: "multipleGeometryFields")

        let url = Bundle(for: ObservationCoreDataSourceTests.self).url(forResource: "test_marker", withExtension: "png")!

        var baseObservationJson: [AnyHashable : Any] = [:]
        baseObservationJson["important"] = nil;
        baseObservationJson["favoriteUserIds"] = nil;
        baseObservationJson["attachments"] = nil;
        baseObservationJson["lastModified"] = nil;
        baseObservationJson["createdAt"] = nil;
        baseObservationJson["eventId"] = 1;
        baseObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
        baseObservationJson["state"] = [
            "name": "active"
        ]
        baseObservationJson["geometry"] = [
            "coordinates": [-1.1, 2.1],
            "type": "Point"
        ]
        baseObservationJson["properties"] = [
            "timestamp": "2020-06-05T17:21:46.969Z",
            "forms": [[
                "formId":1,
                "field1":[
                    "coordinates": [-1.0, 2.0],
                    "type": "Point"
                ]
            ],
                      [
                        "formId": 2,
                        "field1": [
                            "coordinates": [-6.1, 6.1],
                            "type": "Point"
                        ]
                      ]]
        ];

        let observation1 = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)
        let obs1Id = observation1?.objectID.uriRepresentation()

        baseObservationJson["properties"] = [
            "timestamp": "2020-06-05T17:21:46.969Z",
            "forms": [[
                "formId":1,
                "field1":[
                    "coordinates": [-11.1, 21.1],
                    "type": "Point"
                ]
            ],
                      [
                        "formId": 2,
                        "field1": [
                            "coordinates": [-4.1, 5.1],
                            "type": "Point"
                        ],
                        "field3": [
                            "coordinates": [
                                [1.0, 0.0],
                                [1.0, 1.0]
                            ],
                            "type": "LineString"
                        ]
                      ]]
        ]

        let observation2 = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)
        let obs2Id = observation2?.objectID.uriRepresentation()

        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return }

        await context.perform {
            let observations = context.fetchAll(Observation.self) ?? []
            XCTAssertEqual(observations.count, 2)

            for observation in observations {
                observation.createObservationLocations(context: context)
            }
            try? context.save()
        }

        await context.perform {
            let locations = ObservationLocation.mr_findAll() ?? []
            XCTAssertEqual(locations.count, 7)
        }

        let dataSource = ObservationLocationCoreDataDataSource()

        var minLatitude: Double = 0.0
        var maxLatitude: Double = 0.0
        var minLongitude: Double = 0.0
        var maxLongitude: Double = 0.0

        var items = await dataSource.getMapItems(
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude
        )

        XCTAssertEqual(items.count, 0)

        minLatitude = 0.0
        maxLatitude = 1.1
        minLongitude = 0.9
        maxLongitude = 1.1

        items = await dataSource.getMapItems(
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].observationId, obs2Id)

        minLatitude = 0.0
        maxLatitude = 1.1
        minLongitude = 0.9
        maxLongitude = 1.1

        items = await dataSource.getMapItems(
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].observationId, obs2Id)
    }
}
