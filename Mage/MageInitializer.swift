//
//  MageInitializer.swift
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
        let request = NSFetchRequest<Event>(entityName: "Event")
        if let events = try? localContext.fetch(request) {
            for event in events {
                UserDefaults.standard.removeObject(forKey: "selectedFeeds-\(event.remoteId ?? -1)")
            }
        }
        UserDefaults.standard.removeObject(forKey: "selectedStaticLayers")
        UserDefaults.standard.removeObject(forKey: "selectedOnlineLayers")
        
        var cleared = [
            String(describing: Attachment.self): localContext.truncateAll(Attachment.self),
            String(describing: Event.self): localContext.truncateAll(Event.self),
            String(describing: Feed.self): localContext.truncateAll(Feed.self),
            String(describing: FeedItem.self): localContext.truncateAll(FeedItem.self),
            String(describing: Form.self): localContext.truncateAll(Form.self),
            String(describing: FormJson.self): localContext.truncateAll(FormJson.self),
            String(describing: GPSLocation.self): localContext.truncateAll(GPSLocation.self),
            String(describing: Location.self): localContext.truncateAll(Location.self),
            String(describing: Observation.self): localContext.truncateAll(Observation.self),
            String(describing: ObservationFavorite.self): localContext.truncateAll(ObservationFavorite.self),
            String(describing: ObservationImportant.self): localContext.truncateAll(ObservationImportant.self),
            String(describing: Role.self): localContext.truncateAll(Role.self),
            String(describing: Server.self): localContext.truncateAll(Server.self),
            String(describing: Team.self): localContext.truncateAll(Team.self),
            String(describing: User.self): localContext.truncateAll(User.self)
        ];
        
        // we want to keep the GeoPackages around that were imported, those all have an event of -1
        cleared[String(describing: Layer.self)] = Layer.mr_deleteAll(matching: NSPredicate(format: "eventId != -1"), in: localContext)

        
        localContext.mr_saveToPersistentStoreAndWait();
        
        return cleared;
    }
}
