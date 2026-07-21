//
//  ManagedObjectModelRegistry.swift
//  Persistence
//
//  Created by Daniel Barela on 6/18/26.
//

import CoreData

public actor ManagedObjectModelRegistry {
    public static let shared = ManagedObjectModelRegistry()

    private var cache: [URL: NSManagedObjectModel] = [:]

    public func model(at url: URL) -> NSManagedObjectModel {
        if let cached = cache[url] {
            return cached
        }

        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Unable to load model")
        }

        cache[url] = model
        return model
    }
}
