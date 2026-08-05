//
//  PersistenceModelLoader.swift
//  MAGE
//
//  Created by Daniel Barela on 8/5/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//

import Persistence

@objc(MAGEPersistenceModel)
public final class PersistenceModelLoader: NSObject {

    @objc
    public static func managedObjectModel() -> NSManagedObjectModel {
        PersistenceModel.managedObjectModel
    }
}
