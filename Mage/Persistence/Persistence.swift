//
//  Persistence.swift
//  MAGE
//
//  Created by Dan Barela on 9/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import CoreData

private actor PersistenceProviderKey: InjectionKey {
    static var currentValue: Persistence = MagicalRecordPersistence()
}

extension InjectedValues {
    var persistence: Persistence {
        get { Self[PersistenceProviderKey.self] }
        set { Self[PersistenceProviderKey.self] = newValue }
    }
}

protocol Persistence {
    var contextChange: AnyPublisher<Date, Never> { get }
    func getContext() -> NSManagedObjectContext
    func getNewBackgroundContext(name: String?) -> NSManagedObjectContext
    func setupStack()
    func clearAndSetupStack()
    func getRootContext() -> NSManagedObjectContext
}

// TODO: This is temporary while obj-c classes are removed
@objc class PersistenceProvider: NSObject {
    @objc static var instance: PersistenceProvider = PersistenceProvider()

    @objc func getContext() -> NSManagedObjectContext? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        return context
    }
}

class MagicalRecordPersistence: Persistence {
    private static let setupLock = NSLock()
    private static var stackIsInitialized = false
    // Process-wide migration gate: static state prevents duplicate runs across multiple persistence instances.
    private static let createObservationLocationsLock = NSLock()
    private static var createObservationLocationsInProgress = false

    var refreshSubject: PassthroughSubject<Date, Never> = PassthroughSubject<Date, Never>()
    private let observationLocationMigrationVersionKey = "mil.nga.mage.observationLocationMigrationVersion"
    private let observationLocationMigrationVersion = 1
    
    var contextChange: AnyPublisher<Date, Never> {
        refreshSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupStack()
    }

    // MARK: - Public API

    func setupStack() {
        Self.setupLock.lock()
        defer { Self.setupLock.unlock() }

        if Self.stackIsInitialized {
            let context = NSManagedObjectContext.mr_default()
            InjectedValues[\.nsManagedObjectContext] = context
            refreshSubject.send(Date())
            return
        }

        MagicalRecord.setupMageCoreDataStack();
        let context = NSManagedObjectContext.mr_default()
        InjectedValues[\.nsManagedObjectContext] = context
        refreshSubject.send(Date())
        MagicalRecord.setLoggingLevel(.verbose);
        Self.stackIsInitialized = true
        createObservationLocationsIfNeeded()
    }

    func getContext() -> NSManagedObjectContext {
        return NSManagedObjectContext.mr_default()
    }

    func getRootContext() -> NSManagedObjectContext {
        NSManagedObjectContext.mr_rootSaving()
    }

    func getNewBackgroundContext(name: String?) -> NSManagedObjectContext {
        let rootSavingContext = NSManagedObjectContext.mr_rootSaving();
        let localContext = NSManagedObjectContext.mr_context(withParent: rootSavingContext);
        if let name = name {
            localContext.mr_setWorkingName(name)
        }
        return localContext
    }
    
    func clearAndSetupStack() {
        MagicalRecord.deleteAndSetupMageCoreDataStack()
        let context = NSManagedObjectContext.mr_default()
        InjectedValues[\.nsManagedObjectContext] = context
        
        refreshSubject.send(Date())
        MagicalRecord.setLoggingLevel(.verbose)
//        NSManagedObject.mr_setDefaultBatchSize(20);

        Self.setupLock.lock()
        Self.stackIsInitialized = true
        Self.setupLock.unlock()
    }

    // MARK: - Migration Orchestration

    private func createObservationLocationsIfNeeded() {
        let defaults = UserDefaults.standard
        guard shouldRunObservationLocationMigration(defaults: defaults) else {
            return
        }

        guard Self.beginObservationLocationMigrationRun() else {
            MageLogger.db.log("createObservationLocationsIfNeeded() run already in progress.")
            return
        }

        let backgroundContext = getNewBackgroundContext(name: "createObservationLocationsIfNeeded")
        backgroundContext.perform { [weak self] in
            defer { Self.endObservationLocationMigrationRun() }
            guard let self = self else { return }
            self.runObservationLocationMigration(defaults: defaults, context: backgroundContext)
        }
    }

    private func runObservationLocationMigration(defaults: UserDefaults, context: NSManagedObjectContext) {
        do {
            let preMigrationSnapshot = try observationLocationMigrationSnapshot(in: context)
            MageLogger.db.log(
                """
                Observation location migration start:
                store=\(preMigrationSnapshot.storeDescription, privacy: .public),
                totalObservations=\(preMigrationSnapshot.totalObservationCount, privacy: .public),
                totalLocations=\(preMigrationSnapshot.totalLocationCount, privacy: .public),
                primaryLocations=\(preMigrationSnapshot.primaryLocationCount, privacy: .public)
                """
            )

            guard preMigrationSnapshot.totalObservationCount > 0 else {
                MageLogger.db.log("Observation location migration deferred: no observations in store yet.")
                return
            }

            let missingPrimaryObservations = try missingPrimaryLocationObservations(in: context)
            MageLogger.db.log(
                "Observation location migration scan: candidateMissingPrimary=\(missingPrimaryObservations.count, privacy: .public)"
            )

            guard !missingPrimaryObservations.isEmpty else {
                completeOrDeferObservationLocationMigrationWhenNoCandidates(
                    snapshot: preMigrationSnapshot,
                    defaults: defaults
                )
                return
            }

            let sampleObservationIDs = missingPrimaryObservations.prefix(10).map {
                $0.remoteId ?? $0.objectID.uriRepresentation().absoluteString
            }.joined(separator: ",")
            MageLogger.db.log("Observation location migration candidates sample: \(sampleObservationIDs, privacy: .public)")

            createObservationLocations(for: missingPrimaryObservations, in: context)

            let postMigrationSnapshot = try observationLocationMigrationSnapshot(in: context)
            MageLogger.db.log(
                """
                Observation location migration finished:
                attempted=\(missingPrimaryObservations.count, privacy: .public),
                postTotalLocations=\(postMigrationSnapshot.totalLocationCount, privacy: .public),
                postPrimaryLocations=\(postMigrationSnapshot.primaryLocationCount, privacy: .public)
                """
            )
            markObservationLocationMigrationComplete(defaults: defaults)
        } catch {
            MageLogger.db.error("Observation location migration failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Migration State

    private struct ObservationLocationMigrationSnapshot {
        let storeDescription: String
        let totalObservationCount: Int
        let totalLocationCount: Int
        let primaryLocationCount: Int
    }

    private static func beginObservationLocationMigrationRun() -> Bool {
        createObservationLocationsLock.lock()
        defer { createObservationLocationsLock.unlock() }

        guard !createObservationLocationsInProgress else {
            return false
        }
        createObservationLocationsInProgress = true
        return true
    }

    private static func endObservationLocationMigrationRun() {
        createObservationLocationsLock.lock()
        createObservationLocationsInProgress = false
        createObservationLocationsLock.unlock()
    }

    private func shouldRunObservationLocationMigration(defaults: UserDefaults) -> Bool {
        defaults.integer(forKey: observationLocationMigrationVersionKey) < observationLocationMigrationVersion
    }

    private func markObservationLocationMigrationComplete(defaults: UserDefaults) {
        defaults.set(observationLocationMigrationVersion, forKey: observationLocationMigrationVersionKey)
    }

    private func observationLocationMigrationSnapshot(in context: NSManagedObjectContext) throws -> ObservationLocationMigrationSnapshot {
        let totalCountRequest: NSFetchRequest<Observation> = Observation.fetchRequest()
        return ObservationLocationMigrationSnapshot(
            storeDescription: storeDescription(context: context),
            totalObservationCount: try context.count(for: totalCountRequest),
            totalLocationCount: try countObservationLocations(in: context),
            primaryLocationCount: try countObservationLocations(
                in: context,
                fieldName: Observation.PRIMARY_OBSERVATION_GEOMETRY
            )
        )
    }

    private func completeOrDeferObservationLocationMigrationWhenNoCandidates(
        snapshot: ObservationLocationMigrationSnapshot,
        defaults: UserDefaults
    ) {
        if snapshot.primaryLocationCount >= snapshot.totalObservationCount {
            markObservationLocationMigrationComplete(defaults: defaults)
            MageLogger.db.log("Observation location migration complete: all observations already have primary locations.")
        } else {
            MageLogger.db.log(
                """
                Observation location migration deferred:
                unable to identify missing observations while primaryLocations < totalObservations.
                migration will retry next launch.
                """
            )
        }
    }

    private func createObservationLocations(for observations: [Observation], in context: NSManagedObjectContext) {
        for observation in observations {
            observation.createObservationLocations(context: context)
        }

        if context.hasChanges {
            context.mr_saveToPersistentStoreAndWait()
            DispatchQueue.main.async {
                self.refreshSubject.send(Date())
            }
        }
    }

    // MARK: - Query Helpers

    private func missingPrimaryLocationObservations(in context: NSManagedObjectContext) throws -> [Observation] {
        let primaryField = Observation.PRIMARY_OBSERVATION_GEOMETRY

        let subqueryPredicate = NSPredicate(
            format: "SUBQUERY(locations, $loc, $loc.fieldName == %@).@count == 0",
            primaryField
        )

        let subqueryMatches = try fetchObservations(in: context, predicate: subqueryPredicate)

        MageLogger.db.log(
            """
            Observation location migration predicate diagnostics:
            SUBQUERY-predicate matches=\(subqueryMatches.count, privacy: .public)
            """
        )

        let subqueryCandidates = uniqueObservations(from: subqueryMatches)
        if !subqueryCandidates.isEmpty {
            return subqueryCandidates
        }

        let allObservations = try fetchObservations(in: context, predicate: nil)
        let inMemoryMatches = allObservations.filter { observation in
            !(observation.locations?.contains(where: { $0.fieldName == primaryField }) ?? false)
        }
        MageLogger.db.log(
            "Observation location migration in-memory fallback matches=\(inMemoryMatches.count, privacy: .public)"
        )
        return uniqueObservations(from: inMemoryMatches)
    }

    private func fetchObservations(
        in context: NSManagedObjectContext,
        predicate: NSPredicate?
    ) throws -> [Observation] {
        let request: NSFetchRequest<Observation> = Observation.fetchRequest()
        request.fetchBatchSize = 250
        request.predicate = predicate
        return try context.fetch(request)
    }

    private func uniqueObservations(from observations: [Observation]) -> [Observation] {
        var seen: Set<NSManagedObjectID> = []
        var result: [Observation] = []
        for observation in observations {
            if seen.insert(observation.objectID).inserted {
                result.append(observation)
            }
        }
        return result
    }

    private func countObservationLocations(in context: NSManagedObjectContext, fieldName: String? = nil) throws -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ObservationLocation")
        if let fieldName = fieldName {
            request.predicate = NSPredicate(format: "fieldName == %@", fieldName)
        }
        return try context.count(for: request)
    }

    private func storeDescription(context: NSManagedObjectContext) -> String {
        guard let stores = context.persistentStoreCoordinator?.persistentStores, !stores.isEmpty else {
            return "no-persistent-stores"
        }
        return stores.compactMap { store in
            let url = store.url?.path ?? "unknown-url"
            return "\(store.type):\(url)"
        }.joined(separator: ";")
    }
}
