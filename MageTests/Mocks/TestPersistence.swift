//
//  TestPersistence.swift
//  MAGETests
//
//  Created by Dan Barela on 9/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class TestPersistence: Persistence {
    var refreshSubject: PassthroughSubject<NSManagedObjectContext?, Never> = PassthroughSubject<NSManagedObjectContext?, Never>()
    
    var contextChange: AnyPublisher<NSManagedObjectContext?, Never> {
        refreshSubject.eraseToAnyPublisher()
    }
    
    
    // this is static to only load one model because even when the data store is reset
    // it keeps the model around :shrug: but resetting does clear all data
    static let momd = NSManagedObjectModel.mergedModel(from: [.main])
    var managedObjectModel: NSManagedObjectModel?
    
    var persistentContainer: NSPersistentContainer!
    
    func setupPersistentContainer() {
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        description.shouldAddStoreAsynchronously = false
        let bundle: Bundle = .main
        let container = NSPersistentContainer(name: "mage-ios-sdk", managedObjectModel: TestPersistence.momd!)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        persistentContainer = container
    }
    
    init() {
        setupPersistentContainer()
    }
    
    func getContext() -> NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func getNewBackgroundContext(name: String?) -> NSManagedObjectContext {
        let background = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        let background = persistentContainer.newBackgroundContext()
        background.parent = rootContext
        return background
    }
    
    func setupStack() {
        setupPersistentContainer()
        InjectedValues[\.nsManagedObjectContext] = persistentContainer.viewContext
        refreshSubject.send(InjectedValues[\.nsManagedObjectContext])
    }
    
    func clearAndSetupStack() {
        do {
            for currentStore in persistentContainer.persistentStoreCoordinator.persistentStores {
                try persistentContainer.persistentStoreCoordinator.remove(currentStore)
                if let currentStoreURL = currentStore.url {
                    try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: currentStoreURL, type: .sqlite)
                    
                }
            }
        } catch {
            print("Exception destroying \(error)")
        }
        setupPersistentContainer()
        InjectedValues[\.nsManagedObjectContext] = persistentContainer.viewContext
        refreshSubject.send(InjectedValues[\.nsManagedObjectContext])
    }
    
    lazy var rootContext: NSManagedObjectContext = {
        persistentContainer.newBackgroundContext()
    }()
        
    func getRootContext() -> NSManagedObjectContext {
        rootContext
    }
    
    
}

class TestCoreDataStack: NSObject {
    // this is static to only load one model because even when the data store is reset
    // it keeps the model around :shrug: but resetting does clear all data
    static let momd = NSManagedObjectModel.mergedModel(from: [.main])
    var managedObjectModel: NSManagedObjectModel?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        description.shouldAddStoreAsynchronously = false
        let bundle: Bundle = .main
        let container = NSPersistentContainer(name: "mage-ios-sdk", managedObjectModel: TestCoreDataStack.momd!)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    func reset() {
        do {
            for currentStore in persistentContainer.persistentStoreCoordinator.persistentStores {
                try persistentContainer.persistentStoreCoordinator.remove(currentStore)
                if let currentStoreURL = currentStore.url {
                    try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: currentStoreURL, type: .sqlite)
                    
                }
            }
        } catch {
            print("Exception destroying \(error)")
        }
    }
}
