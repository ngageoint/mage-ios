//
//  StaticLayerLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 6/24/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
private struct StaticLayerLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: StaticLayerLocalDataSource = StaticLayerCoreDataDataSource()
}

extension InjectedValues {
    var staticLayerLocalDataSource: StaticLayerLocalDataSource {
        get { Self[StaticLayerLocalDataSourceProviderKey.self] }
        set { Self[StaticLayerLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol StaticLayerLocalDataSource {
    func getStaticLayer(remoteId: NSNumber?, eventId: NSNumber?) -> StaticLayer?
    func getStaticLayer(remoteId: NSNumber?) -> StaticLayer?
}

class StaticLayerCoreDataDataSource: CoreDataDataSource, StaticLayerLocalDataSource, ObservableObject {
    
    func getStaticLayer(remoteId: NSNumber?, eventId: NSNumber?) -> StaticLayer? {
        guard let remoteId = remoteId, let eventId = eventId else {
            return nil
        }
        return StaticLayer.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", remoteId, eventId), in: NSManagedObjectContext.mr_default())
    }
    
    func getStaticLayer(remoteId: NSNumber?) -> StaticLayer? {
        guard let remoteId = remoteId else {
            return nil
        }
        return StaticLayer.mr_findFirst(byAttribute: "remoteId", withValue: remoteId, in: NSManagedObjectContext.mr_default())
    }
}
