//
//  ObservationToObservationPolicyTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/22/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import Combine
import OHHTTPStubs

@testable import MAGE

class MageInjectionTestCase: XCTestCase {
    var cancellables: Set<AnyCancellable> = Set()
    
    override func setUp() {
        defaultObservationInjection()
        defaultImportantInjection()
        defaultObservationFavoriteInjection()
        defaultEventInjection()
        defaultUserInjection()
        defaultFormInjection()
        defaultAttachmentInjection()
        defaultRoleInjection()
        defaultLocationInjection()
        defaultObservationImageInjection()
        defaultStaticLayerInjection()
        defaultGeoPackageInjection()
        defaultFeedItemInjection()
        defaultObservationLocationInjection()
        defaultObservationIconInjection()
        
        clearAndSetUpStack()
    }
    
    override func tearDown() {
        clearAndSetUpStack()
        cancellables.removeAll()
        HTTPStubs.removeAllStubs();
    }
    
    func clearAndSetUpStack() {
        TestHelpers.clearDocuments();
        TestHelpers.clearImageCache();
        TestHelpers.resetUserDefaults();
    }
    
    func defaultObservationInjection() {
        InjectedValues[\.observationRepository] = ObservationRepositoryImpl()
        InjectedValues[\.observationLocalDataSource] = ObservationCoreDataDataSource()
        InjectedValues[\.observationRemoteDataSource] = ObservationRemoteDataSource()
    }
    
    func defaultImportantInjection() {
        InjectedValues[\.observationImportantRepository] = ObservationImportantRepositoryImpl()
        InjectedValues[\.observationImportantLocalDataSource] = ObservationImportantCoreDataDataSource()
        InjectedValues[\.observationImportantRemoteDataSource] = ObservationImportantRemoteDataSource()
    }
    
    func defaultObservationFavoriteInjection() {
        InjectedValues[\.observationFavoriteRepository] = ObservationFavoriteRepositoryImpl()
        InjectedValues[\.observationFavoriteLocalDataSource] = ObservationFavoriteCoreDataDataSource()
        InjectedValues[\.observationFavoriteRemoteDataSource] = ObservationFavoriteRemoteDataSource()
    }
    
    func defaultEventInjection() {
        InjectedValues[\.eventRepository] = EventRepositoryImpl()
        InjectedValues[\.eventLocalDataSource] = EventCoreDataDataSource()
    }
    
    func defaultUserInjection() {
        InjectedValues[\.userRepository] = UserRepositoryImpl()
        InjectedValues[\.userLocalDataSource] = UserCoreDataDataSource()
        InjectedValues[\.userRemoteDataSource] = UserRemoteDataSourceImpl()
    }
    
    func defaultFormInjection() {
        InjectedValues[\.formRepository] = FormRepositoryImpl()
        InjectedValues[\.formLocalDataSource] = FormCoreDataDataSource()
    }
    
    func defaultAttachmentInjection() {
        InjectedValues[\.attachmentRepository] = AttachmentRepositoryImpl()
        InjectedValues[\.attachmentLocalDataSource] = AttachmentCoreDataDataSource()
    }
    
    func defaultRoleInjection() {
        InjectedValues[\.roleRepository] = RoleRepositoryImpl()
        InjectedValues[\.roleLocalDataSource] = RoleCoreDataDataSource()
    }
    
    func defaultLocationInjection() {
        InjectedValues[\.locationRepository] = LocationRepositoryImpl()
        InjectedValues[\.locationLocalDataSource] = LocationCoreDataDataSource()
    }
    
    func defaultObservationImageInjection() {
        InjectedValues[\.observationImageRepository] = ObservationImageRepositoryImpl()
    }
    
    func defaultStaticLayerInjection() {
        InjectedValues[\.staticLayerRepository] = StaticLayerRepository()
        InjectedValues[\.staticLayerLocalDataSource] = StaticLayerCoreDataDataSource()
    }
    
    func defaultGeoPackageInjection() {
        if !(InjectedValues[\.geoPackageRepository] is GeoPackageRepositoryImpl) {
            InjectedValues[\.geoPackageRepository] = GeoPackageRepositoryImpl()
        }
    }
    
    func defaultFeedItemInjection() {
        InjectedValues[\.feedItemRepository] = FeedItemRepositoryImpl()
        InjectedValues[\.feedItemLocalDataSource] = FeedItemStaticLocalDataSource()
    }
    
    func defaultObservationLocationInjection() {
        InjectedValues[\.observationLocationRepository] = ObservationLocationRepositoryImpl()
        InjectedValues[\.observationLocationLocalDataSource] = ObservationLocationCoreDataDataSource()
    }
    
    func defaultObservationIconInjection() {
        InjectedValues[\.observationIconRepository] = ObservationIconRepository()
        InjectedValues[\.observationIconLocalDataSource] = ObservationIconCoreDataDataSource()
    }
}

class MageCoreDataTestCase: MageInjectionTestCase {
    var coreDataStack: TestPersistence!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        coreDataStack = TestPersistence()
        InjectedValues[\.persistence] = coreDataStack
        context = coreDataStack!.getContext()
        InjectedValues[\.nsManagedObjectContext] = context
    }
    
    override func tearDown() {
        super.tearDown()
        coreDataStack!.clearAndSetupStack()
        InjectedValues[\.nsManagedObjectContext] = nil
        context = nil
    }
}

final class ObservationToObservationPolicyTests: MageCoreDataTestCase {

    override func setUp() {
        super.setUp()
        var cleared = false;
//        while (!cleared) {
//            let clearMap = TestHelpers.clearAndSetUpStack()
//            cleared = (clearMap[String(describing: Observation.self)] ?? false) && (clearMap[String(describing: ObservationLocation.self)] ?? false)
//
//            if (!cleared) {
//                cleared = Observation.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0 && ObservationLocation.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0
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
//        }), object: NSManagedObjectContext.mr_default())
////        wait(for: [e], timeout: 10)
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
        super.tearDown()
    }

    private let storeType = NSSQLiteStoreType
    private let modelName = "mage-ios-sdk"
    private let modelNameVersionFormatString = "mage-ios-sdk %@"

    private func storeURL(_ version: String) -> URL? {
        let storeURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())\(version).sqlite" )
        return storeURL
    }

    private func createObjectModel(_ version: String) -> NSManagedObjectModel? {
        let bundle = Bundle.main
        let managedObjectModelURL = bundle.url(forResource: modelName, withExtension: "momd")
        let managedObjectModelURLBundle = Bundle(url: managedObjectModelURL!)
        let modelVersionName = String(format: modelNameVersionFormatString, version)
        let managedObjectModelVersionURL = managedObjectModelURLBundle!.url(forResource: modelVersionName, withExtension: "mom")
        return NSManagedObjectModel(contentsOf: managedObjectModelVersionURL!)
    }

    private func createStore(_ version: String) -> NSPersistentStoreCoordinator {
        let model = createObjectModel(version)
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        try! storeCoordinator.addPersistentStore(ofType: storeType,
                                                 configurationName: nil,
                                                 at: storeURL(version),
                                                 options: nil)
        return storeCoordinator
    }

    private func migrateStore(fromVersionMOM: String, toVersionMOM: String) {
        let store = createStore(fromVersionMOM)

        NSPersistentStoreCoordinator.mr_setDefaultStoreCoordinator(store)
        NSManagedObjectContext.mr_initializeDefaultContext(with: store)


        let nextVersionObjectModel = createObjectModel(toVersionMOM)!
        let mappingModel = NSMappingModel(from: [Bundle.main], forSourceModel: store.managedObjectModel, destinationModel: nextVersionObjectModel)!
        let migrationManager = NSMigrationManager(sourceModel: store.managedObjectModel, destinationModel: nextVersionObjectModel)
        do {
            try migrationManager.migrateStore(from: store.persistentStores.first!.url!,
                                              sourceType: storeType,
                                              options: nil,
                                              with: mappingModel,
                                              toDestinationURL: storeURL(toVersionMOM)!,
                                              destinationType: NSSQLiteStoreType,
                                              destinationOptions: nil)
        } catch {
            print("Error: \(error)")
            XCTAssertNil(error)
        }
        try! FileManager.default.removeItem(at: storeURL(toVersionMOM)!)
        try! FileManager.default.removeItem(at: storeURL(fromVersionMOM)!)
    }

    func testMigratingStores() {



    }


    func xtestMigration22To23() {
        let fromVersionMOM = "22"
        let toVersionMOM = "23"

        let store = createStore(fromVersionMOM)

//        NSPersistentStoreCoordinator.mr_setDefaultStoreCoordinator(store)
//        NSManagedObjectContext.mr_initializeDefaultContext(with: store)
//
//        // insert observations
//        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "multipleGeometryFields")
//
//        let url = Bundle(for: ObservationTests.self).url(forResource: "test_marker", withExtension: "png")!
//
//        var baseObservationJson: [AnyHashable : Any] = [:]
//        baseObservationJson["important"] = nil;
//        baseObservationJson["favoriteUserIds"] = nil;
//        baseObservationJson["attachments"] = nil;
//        baseObservationJson["lastModified"] = nil;
//        baseObservationJson["createdAt"] = nil;
//        baseObservationJson["eventId"] = 1;
//        baseObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
//        baseObservationJson["state"] = [
//            "name": "active"
//        ]
//        baseObservationJson["geometry"] = [
//            "coordinates": [-1.1, 2.1],
//            "type": "Point"
//        ]
//        baseObservationJson["properties"] = [
//            "timestamp": "2020-06-05T17:21:46.969Z",
//            "forms": [[
//                "formId":1,
//                "field1":[
//                    "coordinates": [-1.1, 2.1],
//                    "type": "Point"
//                ]
//            ],
//            [
//                "formId": 2,
//                "field1": [
//                    "coordinates": [-4.1, 5.1],
//                    "type": "Point"
//                ]
//            ]]
//        ];
//
//        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)
//
//        baseObservationJson["properties"] = [
//            "timestamp": "2020-06-05T17:21:46.969Z",
//            "forms": [[
//                "formId":1,
//                "field1":[
//                    "coordinates": [-1.1, 2.1],
//                    "type": "Point"
//                ]
//            ],
//              [
//                "formId": 2,
//                "field1": [
//                    "coordinates": [-4.1, 5.1],
//                    "type": "Point"
//                ],
//                "field3": [
//                    "coordinates": [
//                        [100.0, 0.0],
//                        [101.0, 1.0]
//                    ],
//                    "type": "LineString"
//                ]
//              ]]
//        ]
//
//        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)

        // let core data do the migration
        let nextVersionObjectModel = createObjectModel(toVersionMOM)!

//        NSMappingModel *mappingModel = [NSMappingModel
//                                        mappingModelFromBundles:@[[NSBundle bundleForClass:[MyTestClass class]]]
//                                        forSourceModel:version1Model destinationModel:version2Model];

//        let mappingModel = NSMappingModel(from: [Bundle.main], forSourceModel: store.managedObjectModel, destinationModel: nextVersionObjectModel)!

//        let mappingModel = NSMappingModel(from: [Bundle(for: ObservationToObservationPolicyTests.self)], forSourceModel: store.managedObjectModel, destinationModel: nextVersionObjectModel)!

//        let mappingModel = NSMappingModel(from: nil, forSourceModel: store.managedObjectModel, destinationModel: nextVersionObjectModel)!

//        NSString *mappingModelPath = [[NSBundle mainBundle] pathForResource:@"mappingModel10" ofType:@"cdm"];
//        NSLog(@"mapping model path:%@", mappingModelPath);
//        NSURL *mappingModelUrl = [NSURL fileURLWithPath:mappingModelPath];
//        NSMappingModel *mappingModel = [[NSMappingModel alloc] initWithContentsOfURL:mappingModelUrl];

        do {

            let mappingModelUrl = Bundle.main.url(forResource: "Model22To23", withExtension: "cdm")!
            let mappingModel = NSMappingModel(contentsOf: mappingModelUrl)

            var newEntityMappings: [NSEntityMapping] = mappingModel?.entityMappings ?? []
            for entityMapping in newEntityMappings {
//                var newMapping = entityMapping
                if let sourceEntityName = entityMapping.sourceEntityName {
                    print("BEGIN ---- \(sourceEntityName) -----")
                    print("Entity Mapping is: \n \(entityMapping)")
                    print("entity mapping sourceEntityVersionHash \(entityMapping.sourceEntityVersionHash?.testDescription)")
                    print("store entityVersionHash \(store.managedObjectModel.entityVersionHashesByName[sourceEntityName]?.testDescription)")
                    entityMapping.sourceEntityVersionHash = store.managedObjectModel.entityVersionHashesByName[sourceEntityName]

                    print("entity mapping destinationEntityVersionHash \(entityMapping.destinationEntityVersionHash?.testDescription)")
                    print("store destinationEntityVersionHash \(nextVersionObjectModel.entityVersionHashesByName[sourceEntityName]?.testDescription)")
                    entityMapping.destinationEntityVersionHash = nextVersionObjectModel.entityVersionHashesByName[sourceEntityName]
                    print("Now entity Mapping is: \n\(entityMapping)")
                    print("Are they they same? \(entityMapping == entityMapping)")
                    print("END ---- \(sourceEntityName) -----")
                } else {
                    print("entitymapping: \(entityMapping)")
                }
//                newEntityMappings.append(newMapping)
            }
            mappingModel?.entityMappings = newEntityMappings

            let migrationManager = NSMigrationManager(sourceModel: store.managedObjectModel, destinationModel: nextVersionObjectModel)
            try migrationManager.migrateStore(from: store.persistentStores.first!.url!,
                                              sourceType: storeType,
                                              options: nil,
                                              with: mappingModel,
                                              toDestinationURL: storeURL(toVersionMOM)!,
                                              destinationType: storeType,
                                              destinationOptions: nil)
        } catch {
            print("Error: \(error)")
            XCTAssertNil(error)
        }

        // verify the migration worked

        try! FileManager.default.removeItem(at: storeURL(toVersionMOM)!)
        try! FileManager.default.removeItem(at: storeURL(fromVersionMOM)!)

//        let context = NSManagedObjectContext.mr_default()
//        context.perform {
//            let migration = ObservationToObservationPolicy()
//
//            let observations = context.fetchAll(Observation.self) ?? []
//            XCTAssertEqual(observations.count, 2)
//
//            let mapping = NSEntityMapping()
//            for observation in observations {
//                migration.createDestinationInstances(forSource: observation, in: mapping, manager: )
//            }
//        }
    }

    func xtestMigration22To23Two() async {
//        let fromVersionMOM = "22"
//        let toVersionMOM = "23"
//
//        let store = createStore(fromVersionMOM)
//
//        NSPersistentStoreCoordinator.mr_setDefaultStoreCoordinator(store)
//        NSManagedObjectContext.mr_initializeDefaultContext(with: store)

        // insert observations
        MageCoreDataFixtures.addEvent(context: context, remoteId: 1, name: "Event", formsJsonFile: "multipleGeometryFields")

        let url = Bundle(for: ObservationToObservationPolicyTests.self).url(forResource: "test_marker", withExtension: "png")!

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
                    "coordinates": [-1.1, 2.1],
                    "type": "Point"
                ]
            ],
                      [
                        "formId": 2,
                        "field1": [
                            "coordinates": [-4.1, 5.1],
                            "type": "Point"
                        ]
                      ]]
        ];

        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)

        baseObservationJson["properties"] = [
            "timestamp": "2020-06-05T17:21:46.969Z",
            "forms": [[
                "formId":1,
                "field1":[
                    "coordinates": [-1.1, 2.1],
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
                                [100.0, 0.0],
                                [101.0, 1.0]
                            ],
                            "type": "LineString"
                        ]
                      ]]
        ]

        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)

        let context = NSManagedObjectContext.mr_default()
        await context.perform {
            let migration = ObservationToObservationPolicy()

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

    }
}
