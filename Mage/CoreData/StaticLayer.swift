//
//  StaticLayer.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

@objc public class StaticLayer : Layer {
    
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
        let lastModifiedDate = Date.ISO8601FormatStyle.gmtZeroDate(from: timestamp) ?? Date();
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
    
    @objc public static func operationToFetchStaticLayerData(layer: StaticLayer, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let manager = MageSessionManager.shared(), let layerId = layer.remoteId, let eventId = layer.eventId, let baseURL = MageServer.baseURL() else {
            return nil;
        }
        
        try? layer.managedObjectContext?.obtainPermanentIDs(for: [layer])
        context?.performAndWait {
            let localLayer = context?.object(with: layer.objectID) as? StaticLayer
            localLayer?.downloading = true
            try? context?.save()
        }
        
        let url = baseURL.appendingPathComponent("/api/events/\(eventId)/layers/\(layerId)/features")
        let task = manager.get_TASK(url.absoluteString, parameters: nil, progress: nil) { task, responseObject in
            guard let context = context else { return }
            context.performAndWait {
                guard var dictionaryResponse = responseObject as? [AnyHashable : Any],
                      let localLayer = try? context.fetchFirst(StaticLayer.self, predicate: NSPredicate(format: "\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@", layerId, eventId)),
                      let localLayerId = localLayer.remoteId
                else {
                    return;
                }
                NSLog("fetched static features for \(localLayer.name ?? "unkonwn")");
                
                if var features = dictionaryResponse[LayerKey.features.key] as? [[AnyHashable : Any]] {
                    for i in features.indices {
                        var feature = features[i];
                        if var featureProperties = feature[StaticLayerKey.properties.key] as? [AnyHashable : Any],
                           var style = featureProperties[StaticLayerKey.style.key] as? [AnyHashable : Any],
                           var iconStyle = style[StaticLayerKey.iconStyle.key] as? [AnyHashable : Any],
                           var icon = iconStyle[StaticLayerKey.icon.key] as? [AnyHashable : Any],
                           var href = icon[StaticLayerKey.href.key] as? String,
                           href.hasPrefix("https"),
                           let iconUrl = URL(string: href),
                           let featureId = feature[StaticLayerKey.id.key]
                        {
                            let documentsDirectory = getDocumentsDirectory()
                            let featureIconRelativePath = "featureIcons/\(localLayerId)/\(featureId)"
                            let featureIconPath = "\(documentsDirectory)/\(featureIconRelativePath)"
                            do {
                                let imageData = try Data(contentsOf: iconUrl)
                                if !FileManager.default.fileExists(atPath: featureIconPath) {
                                    let featureDirectory = URL(fileURLWithPath: featureIconPath).deletingLastPathComponent()
                                    try FileManager.default.createDirectory(at: featureDirectory, withIntermediateDirectories: true, attributes: nil);
                                    try imageData.write(to: URL(fileURLWithPath: featureIconPath), options: .atomic)
                                }
                                href = featureIconRelativePath
                                icon[StaticLayerKey.href.key] = href
                                iconStyle[StaticLayerKey.icon.key] = icon;
                                style[StaticLayerKey.iconStyle.key] = iconStyle;
                                featureProperties[StaticLayerKey.style.key] = style;
                                feature[StaticLayerKey.properties.key] = featureProperties;
                                features[i] = feature;
                            } catch { }
                        }
                    }
                    
                    dictionaryResponse[LayerKey.features.key] = features;
                }
                localLayer.data = dictionaryResponse;
                localLayer.loaded = NSNumber(floatLiteral: OFFLINE_LAYER_LOADED)
                localLayer.downloading = false;
                
                try? context.save()
                NotificationCenter.default.post(name: .StaticLayerLoaded, object: localLayer)
            }
//        completion: { contextDidSave, error in
//                if contextDidSave {
//                    @Injected(\.nsManagedObjectContext)
//                    var context: NSManagedObjectContext?
//                    
//                    guard let context = context else { return }
//                    if let localLayer = layer.mr_(in: context) {
//                        NotificationCenter.default.post(name: .StaticLayerLoaded, object: localLayer);
//                    }
//                }
//            }
        } failure: { task, error in
            NSLog("error \(error)")
        }

        

        return task;
    }
    
    @objc public static func createOrUpdate(json: [AnyHashable : Any], eventId: NSNumber, context: NSManagedObjectContext) {
        guard let remoteLayerId = Layer.layerId(json: json) else {
            return;
        }
        
        return context.performAndWait {
            
            var layer = try? context.fetchFirst(
                StaticLayer.self,
                predicate: NSPredicate(
                    format:"(\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@)",
                    remoteLayerId,
                    eventId
                )
            )
            if layer == nil {
                let l = StaticLayer(context: context);
                try? context.obtainPermanentIDs(for: [l])
                l.populate(json, eventId: eventId);
                l.loaded = NSNumber(floatLiteral: OFFLINE_LAYER_NOT_DOWNLOADED);
                NSLog("Inserting layer with id: \(l.remoteId ?? -1) into event \(eventId)")
                layer = l
            } else {
                NSLog("Updating layer with id: \(layer?.remoteId ?? -1) into event \(eventId)")
                layer?.populate(json, eventId: eventId);
            }
            
            try? context.save()
            
            guard let l = layer else {
                return;
            }
            NSLog("layer loaded \(l.name ?? "unkonwn")? \(l.loaded ?? -1.0)")
        }
    }
    
    @objc public static func fetchStaticLayerData(eventId: NSNumber, staticLayer: StaticLayer) {
        guard let manager = MageSessionManager.shared() else {
            return;
        }
        let fetchFeaturesTask = StaticLayer.operationToFetchStaticLayerData(layer: staticLayer, success: nil, failure: nil);
        manager.addTask(fetchFeaturesTask);
    }
    
    @objc public func removeStaticLayerData() {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        context?.performAndWait({
            guard let localLayer = try? context?.existingObject(with: self.objectID) as? StaticLayer else { return }
            
            localLayer.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED);
            localLayer.data = nil
            try? context?.save()
        })
    }
}
