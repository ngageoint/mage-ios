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
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        if let events = try? localContext.fetch(fetchRequest) {
            for event in events {
                UserDefaults.standard.removeObject(forKey: "selectedFeeds-\(event.remoteId ?? -1)")
            }
        }
        UserDefaults.standard.removeObject(forKey: "selectedStaticLayers")
        UserDefaults.standard.removeObject(forKey: "selectedOnlineLayers")
        
        func batchDelete<T: NSManagedObject>(_ entityClass: T.Type, predicate: NSPredicate? = nil, context: NSManagedObjectContext) -> Bool {
            let fetchRequest = T.fetchRequest()
            if let predicate = predicate {
                fetchRequest.predicate = predicate
            }
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try context.execute(deleteRequest)
                return true
            } catch {
                NSLog("Could not batch delete \(T.self): \(error)")
                return false
            }
        }
        var cleared = [
            String(describing: Attachment.self): batchDelete(Attachment.self, context: localContext),
            String(describing: Event.self): batchDelete(Event.self, context: localContext),
            String(describing: Feed.self): batchDelete(Feed.self, context: localContext),
            String(describing: FeedItem.self): batchDelete(FeedItem.self, context: localContext),
            String(describing: Form.self): batchDelete(Form.self, context: localContext),
            String(describing: FormJson.self): batchDelete(FormJson.self, context: localContext),
            String(describing: GPSLocation.self): batchDelete(GPSLocation.self, context: localContext),
            String(describing: Location.self): batchDelete(Location.self, context: localContext),
            String(describing: Observation.self): batchDelete(Observation.self, context: localContext),
            String(describing: ObservationFavorite.self): batchDelete(ObservationFavorite.self, context: localContext),
            String(describing: ObservationImportant.self): batchDelete(ObservationImportant.self, context: localContext),
            String(describing: Role.self): batchDelete(Role.self, context: localContext),
            String(describing: Server.self): batchDelete(Server.self, context: localContext),
            String(describing: Team.self): batchDelete(Team.self, context: localContext),
            String(describing: User.self): batchDelete(User.self, context: localContext)
        ]
        cleared[String(describing: Layer.self)] = batchDelete(Layer.self, predicate: NSPredicate(format: "eventId != -1"), context: localContext)
        try? localContext.save()
        
        return cleared;
    }
}
