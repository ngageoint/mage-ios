//
//  MageInitializer.m
//  MAGE
//
//  Created by Daniel Barela on 6/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import os

enum MageLogger {
    static let network = Logger(subsystem: "mil.nga.mage", category: "networking")
    static let ui = Logger(subsystem: "mil.nga.mage", category: "ui")
    static let db = Logger(subsystem: "mil.nga.mage", category: "database")
    static let misc = Logger(subsystem: "mil.nga.mage", category: "misc")
    static let auth = Logger(subsystem: "mil.nga.mage", category: "authentication")
}

@objc class MageInitializer: NSObject {
    @Injected(\.geoPackageRepository)
    static var geoPackageRepository: GeoPackageRepository
    
    @Injected(\.persistence)
    static var persistence: Persistence
    
    @objc static func cleanupGeoPackages() {
        Task {
            await geoPackageRepository.cleanupBackgroundGeoPackages()
        }
    }
    
    @objc static func getBaseMap() -> BaseMapOverlay? {
        geoPackageRepository.getBaseMap()
    }
    
    @objc static func getDarkBaseMap() -> BaseMapOverlay? {
        geoPackageRepository.getDarkBaseMap()
    }
    
    @objc public static func initializePreferences() {
        
        guard let sdkPreferencesFile = Bundle.main.url(forResource: "preferences-sdk", withExtension: "plist"), let sdkPreferences = NSDictionary(contentsOf: sdkPreferencesFile) as? [String : Any] else {
            return;
        }
        
        guard let defaultPreferencesFile = Bundle.main.url(forResource: "preferences", withExtension: "plist"), let defaultPreferences = NSDictionary(contentsOf: defaultPreferencesFile) as? [String : Any] else {
            return;
        }
        var allPreferences: [String : Any] = sdkPreferences;
        allPreferences.merge(defaultPreferences){(_, new) in new}
        
        UserDefaults.standard.register(defaults: allPreferences)
    }
    
    @objc public static func setupCoreData() -> NSManagedObjectContext {
        persistence.setupStack()
        return persistence.getContext()
    }

    @objc public static func clearAndSetupCoreData() -> NSManagedObjectContext {
        persistence.clearAndSetupStack()
        return persistence.getContext()
    }
    
    @discardableResult
    @objc public static func clearServerSpecificData() -> [String: Bool] {
        @Injected(\.nsManagedObjectContext)
        var localContext: NSManagedObjectContext?
        
        guard let localContext = localContext else { return [:] }
        
        // clear server specific selected layers
        if let events = Event.mr_findAll(in:localContext) as? [Event] {
            for event in events {
                UserDefaults.standard.removeObject(forKey: "selectedFeeds-\(event.remoteId ?? -1)")
            }
        }
        UserDefaults.standard.removeObject(forKey: "selectedStaticLayers")
        UserDefaults.standard.removeObject(forKey: "selectedOnlineLayers")
        
        var cleared = [
            String(describing: Attachment.self): Attachment.mr_truncateAll(in: localContext),
            String(describing: Event.self): Event.mr_truncateAll(in: localContext),
            String(describing: Feed.self): Feed.mr_truncateAll(in: localContext),
            String(describing: FeedItem.self): FeedItem.mr_truncateAll(in: localContext),
            String(describing: Form.self): Form.mr_truncateAll(in: localContext),
            String(describing: FormJson.self): FormJson.mr_truncateAll(in: localContext),
            String(describing: GPSLocation.self): GPSLocation.mr_truncateAll(in: localContext),
            String(describing: Location.self): Location.mr_truncateAll(in: localContext),
            String(describing: Observation.self): Observation.mr_truncateAll(in: localContext),
            String(describing: ObservationFavorite.self): ObservationFavorite.mr_truncateAll(in: localContext),
            String(describing: ObservationImportant.self): ObservationImportant.mr_truncateAll(in: localContext),
            String(describing: Role.self): Role.mr_truncateAll(in: localContext),
            String(describing: Server.self): Server.mr_truncateAll(in: localContext),
            String(describing: Team.self): Team.mr_truncateAll(in: localContext),
            String(describing: User.self): User.mr_truncateAll(in: localContext)
        ];
        
        // we want to keep the GeoPackages around that were imported, those all have an event of -1
        cleared[String(describing: Layer.self)] = Layer.mr_deleteAll(matching: NSPredicate(format: "eventId != -1"), in: localContext)
        
        localContext.mr_saveToPersistentStoreAndWait();
        
        return cleared;
    }
}
