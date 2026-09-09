//
//  StaticLayer.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import ServerDTO
import Layer
import Persistence

extension StaticLayer {
    
    public var features: [[AnyHashable: Any]]? {
        get {
            return data?["features"] as? [[AnyHashable: Any]]
        }
    }
    
    static func featureName(feature: [AnyHashable : Any]) -> String? {
        return (feature["properties"] as? [AnyHashable : Any])?["name"] as? String
    }
    
    static func featureDescription(feature: [AnyHashable : Any]) -> String? {
        return (feature["properties"] as? [AnyHashable : Any])?["description"] as? String
    }
    
    static func featureTimestamp(feature: [AnyHashable : Any]) -> Date? {
        guard let timestamp = (feature["properties"] as? [AnyHashable : Any])?["timestamp"] as? String else {
            return nil
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withTime, .withColonSeparatorInTime, .withTimeZone];
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
        let lastModifiedDate = formatter.date(from: timestamp) ?? Date();
        return lastModifiedDate
    }
    
    static func featureType(feature: [AnyHashable : Any]) -> String? {
        return (feature["geometry"] as? [AnyHashable : Any])?["type"] as? String
    }
    
    static func featureCoordinates(feature: [AnyHashable : Any]) -> [Any]? {
        return (feature["geometry"] as? [AnyHashable : Any])?["coordinates"] as? [Any]
    }
    
    static func featureFillOpacity(feature: [AnyHashable : Any]) -> Double {
        return (feature as NSDictionary).value(forKeyPath: "properties.style.polyStyle.color.opacity") as? Double ?? 255.0
    }
    
    static func featureFillColor(feature: [AnyHashable : Any]) -> String {
        return (feature as NSDictionary).value(forKeyPath: "properties.style.polyStyle.color.rgb") as? String ?? "#000000"
    }
    
    func featureLineOpacity(feature: [AnyHashable : Any]) -> Double {
        return (feature as NSDictionary).value(forKeyPath: "properties.style.lineStyle.color.opacity") as? Double ?? 255.0
    }
    
    static func featureLineColor(feature: [AnyHashable : Any]) -> String {
        return (feature as NSDictionary).value(forKeyPath: "properties.style.lineStyle.color.rgb") as? String ?? "#000000"
    }
    
    static func featureLineWidth(feature: [AnyHashable : Any]) -> Double {
        let width = (feature as NSDictionary).value(forKeyPath: "properties.style.lineStyle.width")
        if let doubleWidth = width as? Double {
            return doubleWidth
        } else if let stringWidth = width as? String {
            return Double(stringWidth) ?? 1.0
        }
        return 1.0
    }
    
    @objc public static let StaticLayerLoaded = "mil.nga.giat.mage.static.layer.loaded";
    
    @objc public static func createOrUpdate(json: [AnyHashable : Any], eventId: NSNumber, context: NSManagedObjectContext) {
        guard let remoteLayerId = Layer.layerId(json: json) else {
            return;
        }
        
        var l = StaticLayer.mr_findFirst(with: NSPredicate(format:"(\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@)", remoteLayerId, eventId), in: context);
        if l == nil {
            l = StaticLayer.mr_createEntity(in: context);
            l?.populate(json, eventId: eventId);
            l?.loaded = NSNumber(floatLiteral: OFFLINE_LAYER_NOT_DOWNLOADED);
            NSLog("Inserting layer with id: \(l?.remoteId ?? -1) into event \(eventId)")
        } else {
            NSLog("Updating layer with id: \(l?.remoteId ?? -1) into event \(eventId)")
            l?.populate(json, eventId: eventId);
        }
        guard let l = l else {
            return;
        }
        NSLog("layer loaded \(l.name ?? "unkonwn")? \(l.loaded ?? -1.0)")
    }
    
    @objc public static func fetchStaticLayerData(eventId: NSNumber, staticLayer: StaticLayer) {
        Task {
            try await DependencyContainer.shared.useCaseFactory
                .resolve(.StaticLayerDataFetchUseCase)
                .execute(eventID: EventID(eventId), layerID: staticLayer.remoteId.map(LayerID.init))
        }
    }
    
    @objc public func removeStaticLayerData() {
        MagicalRecord.save { [weak self] context in
            guard let localLayer = self?.mr_(in: context) else {
                return;
            }
            localLayer.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED);
            localLayer.data = nil
        } completion: { contextDidSave, error in
        }
    }
}
