//
//  ObservationToObservationPolicy.swift
//  MAGE
//
//  Created by Daniel Barela on 3/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationToObservationPolicy: NSEntityMigrationPolicy {

    @objc override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        if let modelVersion = mapping.userInfo?["modelVersion"] as? Int {
            migrateExistingKeysAndValues(forSource: sInstance, in: mapping, manager: manager)

            switch modelVersion {
            case 23:
                migrate22To23(forSource: sInstance, in: mapping, manager: manager)
            default:
                try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
            }
        } else {
            try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        }
    }

    func migrateExistingKeysAndValues(
        forSource sourceInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) {
        // Get the source attribute keys and values
        let sourceAttributeKeys = Array(sourceInstance.entity.attributesByName.keys)
        let sourceAttributeValues = sourceInstance.dictionaryWithValues(forKeys: sourceAttributeKeys)

        // Create the destination Note instance
        let destinationInstance = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!, into: manager.destinationContext)

        // Get the destination attribute keys
        let destinationAttributeKeys = Array(destinationInstance.entity.attributesByName.keys)

        // Set all those attributes of the destination instance which are the same as those of the source instance
        for key in destinationAttributeKeys {
            if let value = sourceAttributeValues[key] {
                destinationInstance.setValue(value, forKey: key)
            }
        }
    }

    func migrate22To23(
        forSource sourceInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) {
        if let observation = sourceInstance as? Observation {
            observation.createObservationLocations(context: manager.destinationContext)
        }
    }
}
