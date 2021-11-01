//
//  MageInitializer.m
//  MAGE
//
//  Created by Daniel Barela on 6/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

@objc class MageInitializer: NSObject {
    
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
    
    @objc public static func setupCoreData() {
        MagicalRecord.setupMageCoreDataStack();
        MagicalRecord.setLoggingLevel(.verbose);
    }

    @objc public static func clearAndSetupCoreData() {
        MagicalRecord.deleteAndSetupMageCoreDataStack();
        MagicalRecord.setLoggingLevel(.verbose);
    }
    
    @discardableResult
    @objc public static func clearServerSpecificData() -> [String: Bool] {
        let localContext: NSManagedObjectContext = NSManagedObjectContext.mr_default();
        
        var cleared = [
            String(describing: Attachment.self): Attachment.mr_truncateAll(in: localContext),
            String(describing: Event.self): Event.mr_truncateAll(in: localContext),
            String(describing: Feed.self): Feed.mr_truncateAll(in: localContext),
            String(describing: FeedItem.self): FeedItem.mr_truncateAll(in: localContext),
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
