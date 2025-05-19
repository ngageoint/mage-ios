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
    static var currentValue: Persistence = CoreDataPersistence()
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

class CoreDataPersistence: Persistence {
    var refreshSubject: PassthroughSubject<Date, Never> = PassthroughSubject<Date, Never>()
    private var persistentContainer: NSPersistentContainer?
    
    var contextChange: AnyPublisher<Date, Never> {
        refreshSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupStack()
    }
    
    func setupStack() {
        let container = NSPersistentContainer(name: "Mage")
        
        // Configure SQLite store with WAL journal mode
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        
        // Add SQLite pragmas for WAL mode
        let sqliteOptions = [
            "journal_mode": "WAL"
        ]
        description.setOption(sqliteOptions as NSDictionary, forKey: NSSQLitePragmasOption)
        
        // Add migration options
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        // Add file protection
        #if os(iOS)
        description.setOption(FileProtectionType.completeUnlessOpen.rawValue as NSString, forKey: NSPersistentStoreFileProtectionKey)
        #endif
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Prevent MAGE database from being backed up
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            do {
                try (storeURL.deletingLastPathComponent() as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
            } catch {
                print("Error excluding database from backup: \(error)")
            }
        }
        
        self.persistentContainer = container
        InjectedValues[\.nsManagedObjectContext] = container.viewContext
        refreshSubject.send(Date())
    }
    
    func getContext() -> NSManagedObjectContext {
        return persistentContainer?.viewContext ?? NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    }
    
    func getRootContext() -> NSManagedObjectContext {
        return persistentContainer?.newBackgroundContext() ?? NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }
    
    func getNewBackgroundContext(name: String?) -> NSManagedObjectContext {
        let backgroundContext = persistentContainer?.newBackgroundContext() ?? NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = getRootContext()
        
        if let name = name {
            backgroundContext.name = name
        }
        
        return backgroundContext
    }
    
    func clearAndSetupStack() {
        guard let container = persistentContainer else { return }
        
        // Remove existing stores
        for store in container.persistentStoreCoordinator.persistentStores {
            do {
                try container.persistentStoreCoordinator.remove(store)
                if let storeURL = store.url {
                    try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
                }
            } catch {
                print("Error removing store: \(error)")
            }
        }
        
        // Reset the container
        persistentContainer = nil
        
        // Setup the stack again
        setupStack()
    }
}
