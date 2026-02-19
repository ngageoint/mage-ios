//
//  ObservationToObservationPolicyTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/22/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import CoreData
import ExceptionCatcher

@testable import MAGE

final class ObservationToObservationPolicyTests: XCTestCase {
    private let modelName = "mage-ios-sdk"
    private let modelVersionFormat = "mage-ios-sdk %@"
    private let realV22FixtureRelativePath = "Migration/real-v22/mage-v22-simple-event"
    private var temporaryStoreURLs: [URL] = []
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryStoreURLs {
            removeSQLiteArtifacts(at: url)
        }
        temporaryStoreURLs.removeAll()
        for directoryURL in temporaryDirectories {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        temporaryDirectories.removeAll()
        try super.tearDownWithError()
    }

    func testBundled22To23MappingModelHashMismatchThrows() throws {
        let sourceURL = createTemporaryStoreURL(name: "mapping-mismatch-source")
        let destinationURL = createTemporaryStoreURL(name: "mapping-mismatch-destination")

        let sourceModel = try createSeededModel22Store(at: sourceURL)
        let destinationModel = try objectModel(version: "23")
        let mappingModel = try model22To23MappingModel()
        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)

        XCTAssertThrowsError(
            try runMigration(
                manager: migrationManager,
                sourceURL: sourceURL,
                destinationURL: destinationURL,
                mappingModel: mappingModel
            )
        ) { error in
            XCTAssertTrue(
                error.localizedDescription.contains("Mismatch between mapping and source/destination models"),
                "Unexpected migration error: \(error.localizedDescription)"
            )
        }
    }

    func testAutomaticMigrationWithInferMappingSkipsCustomPolicy() throws {
        let sourceURL = createTemporaryStoreURL(name: "migration-auto-source")
        _ = try createSeededModel22Store(at: sourceURL)

        let destinationModel = try objectModel(version: "23")
        let options: [AnyHashable: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]

        let destinationCoordinator = try addStore(model: destinationModel, url: sourceURL, options: options)
        let locations = try fetchObservationLocations(coordinator: destinationCoordinator)

        XCTAssertEqual(
            locations.count,
            0,
            "App-style inferred migration does not invoke ObservationToObservationPolicy, so ObservationLocation rows are never created."
        )
    }

    func testNormalizedMappingWithoutModelVersionSkipsCustomPolicy() throws {
        let sourceURL = createTemporaryStoreURL(name: "normalized-no-modelversion-source")
        let destinationURL = createTemporaryStoreURL(name: "normalized-no-modelversion-destination")

        let sourceModel = try createSeededModel22Store(at: sourceURL)
        let destinationModel = try objectModel(version: "23")
        let mappingModel = try normalizedModel22To23Mapping(sourceModel: sourceModel, destinationModel: destinationModel)

        for entityMapping in mappingModel.entityMappings where entityMapping.sourceEntityName == "Observation" {
            entityMapping.userInfo = nil
        }

        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        try runMigration(
            manager: migrationManager,
            sourceURL: sourceURL,
            destinationURL: destinationURL,
            mappingModel: mappingModel
        )

        let destinationCoordinator = try addStore(model: destinationModel, url: destinationURL, options: nil)
        let locations = try fetchObservationLocations(coordinator: destinationCoordinator)

        XCTAssertEqual(locations.count, 0)
    }

    func testRealV22FixtureAutomaticMigrationLeavesObservationLocationsMissing() throws {
        let storeURL = try copyRealV22FixtureStoreToTemporaryLocation()
        let sourceModel = try objectModel(version: "22")
        let sourceCoordinator = try addStore(model: sourceModel, url: storeURL, options: nil)
        let sourceObservationCount = try countEntities(named: "Observation", coordinator: sourceCoordinator)
        XCTAssertGreaterThan(sourceObservationCount, 0, "Fixture has no observations; cannot validate migration behavior.")
        if let store = sourceCoordinator.persistentStores.first {
            try sourceCoordinator.remove(store)
        }

        let destinationModel = try objectModel(version: "23")
        let options: [AnyHashable: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        let destinationCoordinator = try addStore(model: destinationModel, url: storeURL, options: options)
        let locationCount = try countEntities(named: "ObservationLocation", coordinator: destinationCoordinator)

        XCTAssertEqual(
            locationCount,
            0,
            "Expected app-style inferred migration to skip ObservationToObservationPolicy for this fixture."
        )
    }

    func testRealV22FixtureSubqueryFindsMissingLocationsAndMigrationCreatesThem() throws {
        let storeURL = try copyRealV22FixtureStoreToTemporaryLocation()
        let sourceModel = try objectModel(version: "22")
        let sourceCoordinator = try addStore(model: sourceModel, url: storeURL, options: nil)
        let sourceObservationCount = try countEntities(named: "Observation", coordinator: sourceCoordinator)
        XCTAssertGreaterThan(sourceObservationCount, 0, "Fixture has no observations; cannot validate migration behavior.")
        if let store = sourceCoordinator.persistentStores.first {
            try sourceCoordinator.remove(store)
        }

        let destinationModel = try objectModel(version: "23")
        let options: [AnyHashable: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        let destinationCoordinator = try addStore(model: destinationModel, url: storeURL, options: options)

        let noneMatches = try countObservationsMissingPrimaryWithNonePredicate(coordinator: destinationCoordinator)
        let subqueryMatches = try countObservationsMissingPrimaryWithSubqueryPredicate(coordinator: destinationCoordinator)

        XCTAssertEqual(noneMatches, 0, "NONE predicate does not match missing to-many relationships in this migrated fixture.")
        XCTAssertGreaterThan(subqueryMatches, 0, "SUBQUERY should detect observations missing primary locations.")

        _ = try migrateMissingPrimaryLocations(coordinator: destinationCoordinator)

        let postSubqueryMatches = try countObservationsMissingPrimaryWithSubqueryPredicate(coordinator: destinationCoordinator)
        XCTAssertEqual(postSubqueryMatches, 0, "Migration should eliminate all observations missing primary locations.")
    }

    private func runMigration(
        manager: NSMigrationManager,
        sourceURL: URL,
        destinationURL: URL,
        mappingModel: NSMappingModel
    ) throws {
        try ExceptionCatcher.catch {
            try manager.migrateStore(
                from: sourceURL,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mappingModel,
                toDestinationURL: destinationURL,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )
        }
    }

    private func normalizedModel22To23Mapping(
        sourceModel: NSManagedObjectModel,
        destinationModel: NSManagedObjectModel
    ) throws -> NSMappingModel {
        let mappingModel = try model22To23MappingModel()
        for entityMapping in mappingModel.entityMappings {
            if let sourceEntityName = entityMapping.sourceEntityName,
               let sourceHash = sourceModel.entityVersionHashesByName[sourceEntityName] {
                entityMapping.sourceEntityVersionHash = sourceHash
            }

            let destinationEntityName = entityMapping.destinationEntityName ?? entityMapping.sourceEntityName
            if let destinationEntityName,
               let destinationHash = destinationModel.entityVersionHashesByName[destinationEntityName] {
                entityMapping.destinationEntityVersionHash = destinationHash
            }

            if entityMapping.sourceEntityName == "Observation" {
                entityMapping.entityMigrationPolicyClassName = NSStringFromClass(ObservationToObservationPolicy.self)
            }
        }
        return mappingModel
    }

    private func createTemporaryStoreURL(name: String) -> URL {
        let fileName = "ObservationMigration-\(name)-\(UUID().uuidString).sqlite"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        temporaryStoreURLs.append(url)
        return url
    }

    private func removeSQLiteArtifacts(at storeURL: URL) {
        let fileManager = FileManager.default
        let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")

        try? fileManager.removeItem(at: storeURL)
        try? fileManager.removeItem(at: walURL)
        try? fileManager.removeItem(at: shmURL)
    }

    private func objectModel(version: String) throws -> NSManagedObjectModel {
        let versionedModelName = String(format: modelVersionFormat, version)
        let bundles = [Bundle.main, Bundle(for: ObservationToObservationPolicyTests.self)]

        for bundle in bundles {
            if let momdURL = bundle.url(forResource: modelName, withExtension: "momd"),
               let momdBundle = Bundle(url: momdURL),
               let momURL = momdBundle.url(forResource: versionedModelName, withExtension: "mom"),
               let model = NSManagedObjectModel(contentsOf: momURL) {
                return model
            }
        }

        throw TestError.missingModel(version: version)
    }

    private func model22To23MappingModel() throws -> NSMappingModel {
        let bundles = [Bundle.main, Bundle(for: ObservationToObservationPolicyTests.self)]

        for bundle in bundles {
            if let cdmURL = bundle.url(forResource: "Model22To23", withExtension: "cdm"),
               let model = NSMappingModel(contentsOf: cdmURL) {
                return model
            }
            if let xmlURL = bundle.url(forResource: "Model22To23", withExtension: "xcmappingmodel"),
               let model = NSMappingModel(contentsOf: xmlURL) {
                return model
            }
        }

        throw TestError.missingMappingModel
    }

    @discardableResult
    private func createSeededModel22Store(at sourceURL: URL) throws -> NSManagedObjectModel {
        let sourceModel = try objectModel(version: "22")
        let coordinator = try addStore(model: sourceModel, url: sourceURL, options: nil)

        try insertLegacyObservation(coordinator: coordinator)

        if let store = coordinator.persistentStores.first {
            try coordinator.remove(store)
        }
        return sourceModel
    }

    private func addStore(
        model: NSManagedObjectModel,
        url: URL,
        options: [AnyHashable: Any]?
    ) throws -> NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        _ = try coordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: url,
            options: options
        )
        return coordinator
    }

    private func insertLegacyObservation(coordinator: NSPersistentStoreCoordinator) throws {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        var caughtError: Error?
        context.performAndWait {
            do {
                guard let entity = NSEntityDescription.entity(forEntityName: "Observation", in: context) else {
                    throw TestError.missingEntity("Observation")
                }

                let observation = NSManagedObject(entity: entity, insertInto: context)
                observation.setValue("legacy-observation-1", forKey: "remoteId")
                observation.setValue(NSNumber(value: 1), forKey: "eventId")
                observation.setValue(NSNumber(value: true), forKey: "dirty")
                observation.setValue(Date(), forKey: "timestamp")
                observation.setValue(SFGeometryUtils.encode(SFPoint(x: -104.9, andY: 39.6)), forKey: "geometryData")

                try context.save()
            } catch {
                caughtError = error
            }
        }

        if let caughtError {
            throw caughtError
        }
    }

    private func fetchObservationLocations(
        coordinator: NSPersistentStoreCoordinator
    ) throws -> [ObservationLocation] {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        var locations: [ObservationLocation] = []
        var caughtError: Error?
        context.performAndWait {
            do {
                let request = NSFetchRequest<ObservationLocation>(entityName: "ObservationLocation")
                request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
                locations = try context.fetch(request)
            } catch {
                caughtError = error
            }
        }

        if let caughtError {
            throw caughtError
        }
        return locations
    }

    private func countEntities(
        named entityName: String,
        coordinator: NSPersistentStoreCoordinator,
        predicate: NSPredicate? = nil
    ) throws -> Int {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        var count = 0
        var caughtError: Error?
        context.performAndWait {
            do {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                request.predicate = predicate
                count = try context.count(for: request)
            } catch {
                caughtError = error
            }
        }

        if let caughtError {
            throw caughtError
        }
        return count
    }

    private func countObservationsMissingPrimaryWithNonePredicate(
        coordinator: NSPersistentStoreCoordinator
    ) throws -> Int {
        let predicate = NSPredicate(
            format: "NONE locations.fieldName == %@",
            Observation.PRIMARY_OBSERVATION_GEOMETRY
        )
        return try countEntities(named: "Observation", coordinator: coordinator, predicate: predicate)
    }

    private func countObservationsMissingPrimaryWithSubqueryPredicate(
        coordinator: NSPersistentStoreCoordinator
    ) throws -> Int {
        let predicate = NSPredicate(
            format: "SUBQUERY(locations, $loc, $loc.fieldName == %@).@count == 0",
            Observation.PRIMARY_OBSERVATION_GEOMETRY
        )
        return try countEntities(named: "Observation", coordinator: coordinator, predicate: predicate)
    }

    private func migrateMissingPrimaryLocations(
        coordinator: NSPersistentStoreCoordinator
    ) throws -> Int {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        var created = 0
        var caughtError: Error?
        context.performAndWait {
            do {
                let request = NSFetchRequest<Observation>(entityName: "Observation")
                request.fetchBatchSize = 250
                request.predicate = NSPredicate(
                    format: "SUBQUERY(locations, $loc, $loc.fieldName == %@).@count == 0",
                    Observation.PRIMARY_OBSERVATION_GEOMETRY
                )
                let observations = try context.fetch(request)
                created = observations.count
                for observation in observations {
                    observation.createObservationLocations(context: context)
                }
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                caughtError = error
            }
        }

        if let caughtError {
            throw caughtError
        }
        return created
    }

    private func copyRealV22FixtureStoreToTemporaryLocation() throws -> URL {
        let fixtureDirectoryURL = repositoryRootURL()
            .appendingPathComponent(realV22FixtureRelativePath, isDirectory: true)
        let fixtureStoreURL = fixtureDirectoryURL.appendingPathComponent("Mage.sqlite")
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fixtureStoreURL.path) else {
            throw XCTSkip("Real fixture missing at \(fixtureStoreURL.path)")
        }

        let destinationDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ObservationMigration-RealFixture-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
        temporaryDirectories.append(destinationDirectoryURL)

        let destinationStoreURL = destinationDirectoryURL.appendingPathComponent("Mage.sqlite")
        let suffixes = ["", "-wal", "-shm"]
        for suffix in suffixes {
            let actualSourceURL: URL
            if suffix.isEmpty {
                actualSourceURL = fixtureStoreURL
            } else {
                actualSourceURL = URL(fileURLWithPath: fixtureStoreURL.path + suffix)
            }
            if fileManager.fileExists(atPath: actualSourceURL.path) {
                let destinationURL = URL(fileURLWithPath: destinationStoreURL.path + suffix)
                try fileManager.copyItem(at: actualSourceURL, to: destinationURL)
            }
        }

        temporaryStoreURLs.append(destinationStoreURL)
        return destinationStoreURL
    }

    private func repositoryRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private enum TestError: Error {
    case missingEntity(String)
    case missingModel(version: String)
    case missingMappingModel
}
