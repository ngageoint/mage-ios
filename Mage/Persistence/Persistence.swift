//
//  Persistence.swift
//  MAGE
//
//  Created by Dan Barela on 9/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

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
    var refreshSubject: PassthroughSubject<Date, Never> = PassthroughSubject<Date, Never>()
    
    var contextChange: AnyPublisher<Date, Never> {
        refreshSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupStack()
    }
    
    func setupStack() {
        MagicalRecord.setupMageCoreDataStack();
        let context = NSManagedObjectContext.mr_default()
        InjectedValues[\.nsManagedObjectContext] = context
        refreshSubject.send(Date())
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
        let context = NSManagedObjectContext.mr_default()
        InjectedValues[\.nsManagedObjectContext] = context
        
        refreshSubject.send(Date())
        MagicalRecord.setLoggingLevel(.verbose)
//        NSManagedObject.mr_setDefaultBatchSize(20);
    }
}
