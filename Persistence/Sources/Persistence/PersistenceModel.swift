//
//  PersistenceModel.swift
//  Persistence
//
//  Created by Daniel Barela on 8/5/26.
//

@preconcurrency import CoreData

public enum PersistenceModel {
    public static let managedObjectModel: NSManagedObjectModel = {
        guard let url = Bundle.module.url(
            forResource: "mage-ios-sdk",
            withExtension: "momd"
        ) else {
            fatalError("Could not locate MAGE.momd")
        }

        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Could not load managed object model")
        }

        return model
    }()
}
