//
//  Persistence.swift
//  MAGE
//
//  Created by Dan Barela on 9/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct PersistenceProviderKey: InjectionKey {
    static var currentValue: Persistence = MagicalRecordPersistence()
}

extension InjectedValues {
    var persistence: Persistence {
        get { Self[PersistenceProviderKey.self] }
        set { Self[PersistenceProviderKey.self] = newValue }
    }
}

protocol Persistence {
    func getContext() -> NSManagedObjectContext
    func getNewBackgroundContext(name: String?) -> NSManagedObjectContext
    func setupStack()
    func clearAndSetupStack()
    func getRootContext() -> NSManagedObjectContext
}

class MagicalRecordPersistence: Persistence {
    
    func setupStack() {
        MagicalRecord.setupMageCoreDataStack();
        InjectedValues[\.nsManagedObjectContext] = NSManagedObjectContext.mr_default()
        MagicalRecord.setLoggingLevel(.verbose);
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
        InjectedValues[\.nsManagedObjectContext] = NSManagedObjectContext.mr_default()
        MagicalRecord.setLoggingLevel(.verbose)
    }
}
