//
//  Layer.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

public enum LayerType : String {
    case Feature
    case GeoPackage
    case Imagery
    
    var key : String {
        return self.rawValue;
    }
}

@objc public class Layer : NSManagedObject {
    
    @objc public static let GeoPackageDownloaded = "mil.nga.giat.mage.geopackage.downloaded";
    @objc public static let OFFLINE_LAYER_LOADED = 1.0;
    @objc public static let OFFLINE_LAYER_NOT_DOWNLOADED = 0.0;
    @objc public static let EXTERNAL_LAYER_LOADED = 0.5;
    @objc public static let EXTERNAL_LAYER_PROCESSING = -1.0;
    
    @objc public static func layerType(json: [AnyHashable : Any]) -> String? {
        return json[LayerKey.type.key] as? String;
    }
    
    @objc public func populate(_ json: [AnyHashable : Any], eventId: NSNumber) {
        self.remoteId = json[LayerKey.id.key] as? NSNumber
        self.name = json[LayerKey.name.key] as? String
        self.type = json[LayerKey.type.key] as? String
        self.url = json[LayerKey.url.key] as? String
        self.file = json[LayerKey.file.key] as? [AnyHashable : Any]
        self.layerDescription = json[LayerKey.description.key] as? String
        self.state = json[LayerKey.state.key] as? String
        self.eventId = eventId;
    }
    
    @objc public static func operationToPullLayers(eventId: NSNumber, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let manager = MageSessionManager.shared(), let baseURL = MageServer.baseURL() else {
            return nil;
        }
        let url = "\(baseURL)/api/events/\(eventId)/layers";
        
        let task = manager.get_TASK(url, parameters: nil, progress: nil) { task, response in
            guard let response = response as? [[AnyHashable : Any]] else {
                return;
            }

            MagicalRecord.save { context in
                let layerRemoteIds = Layer.populateLayers(json: response, eventId: eventId, context: context)
                Layer.mr_deleteAll(matching: NSPredicate(format: "(NOT (\(LayerKey.remoteId.key) IN %@)) AND \(LayerKey.eventId.key) == %@", layerRemoteIds, eventId), in: context);
                
                var selectedOnlineLayers = UserDefaults.standard.selectedOnlineLayers ?? [:]
                
                // get the currently selected online layers, remove all existing layers and then delete the ones that are left
                var removedSelectedOnlineLayers: [NSNumber] = selectedOnlineLayers[eventId.stringValue] ?? [];
                removedSelectedOnlineLayers.removeAll { layerRemoteId in
                    layerRemoteIds.contains(layerRemoteId)
                }
                
                var selectedEventOnlineLayers = selectedOnlineLayers[eventId.stringValue] ?? [];
                selectedEventOnlineLayers.removeAll { layerRemoteId in
                    removedSelectedOnlineLayers.contains(layerRemoteId)
                }
                
                selectedOnlineLayers[eventId.stringValue] = selectedEventOnlineLayers;
                UserDefaults.standard.selectedOnlineLayers = selectedOnlineLayers;
                
                
                StaticLayer.mr_deleteAll(matching: NSPredicate(format: "(NOT (\(LayerKey.remoteId.key) IN %@)) AND \(LayerKey.eventId.key) == %@", layerRemoteIds, eventId), in: context);
                
                var selectedStaticLayers = UserDefaults.standard.selectedStaticLayers ?? [:]
                
                // get the currently selected online layers, remove all existing layers and then delete the ones that are left
                var removedSelectedStaticLayers: [NSNumber] = selectedStaticLayers[eventId.stringValue] ?? [];
                removedSelectedStaticLayers.removeAll { layerRemoteId in
                    layerRemoteIds.contains(layerRemoteId)
                }
                
                var selectedEventStaticLayers = selectedStaticLayers[eventId.stringValue] ?? [];
                selectedEventStaticLayers.removeAll { layerRemoteId in
                    removedSelectedStaticLayers.contains(layerRemoteId)
                }
                
                selectedStaticLayers[eventId.stringValue] = selectedEventStaticLayers;
                UserDefaults.standard.selectedStaticLayers = selectedStaticLayers;
                
            } completion: { contextDidSave, error in
                if let error = error {
                    failure?(task, error);
                } else {
                    success?(task, response);
                }
            }
        } failure: { task, error in
            NSLog("Error \(error)")
            failure?(task, error);
        };

        return task;
    }
    
    @discardableResult
    @objc public static func populateLayers(json: [[AnyHashable: Any]], eventId: NSNumber, context: NSManagedObjectContext) -> [NSNumber] {
        var layerRemoteIds: [NSNumber] = [];
        for layer in json {
            guard let remoteLayerId = Layer.layerId(json: layer) else {
                continue;
            }
            layerRemoteIds.append(remoteLayerId);
            
            if let layerType = Layer.layerType(json: layer), layerType == LayerType.Feature.key {
                StaticLayer.createOrUpdate(json: layer, eventId: eventId, context: context);
            } else if let layerType = Layer.layerType(json: layer), layerType == LayerType.GeoPackage.key {
                var l = Layer.mr_findFirst(with: NSPredicate(format: "(\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@)", remoteLayerId, eventId), in: context)
                if l == nil {
                    l = Layer.mr_createEntity(in: context);
                    l?.loaded = NSNumber(floatLiteral: OFFLINE_LAYER_NOT_DOWNLOADED);
                }
                guard let l = l else {
                    continue
                }
                l.populate(layer, eventId: eventId);
                
                // If this layer already exists but for a different event, set it's downloaded status
                if let existing = Layer.mr_findFirst(with: NSPredicate(format: "\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) != %@", remoteLayerId, eventId), in: context) {
                    l.loaded = existing.loaded
                }
            } else if let layerType = Layer.layerType(json: layer), layerType == LayerType.Imagery.key {
                var l = ImageryLayer.mr_findFirst(with: NSPredicate(format: "(\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@)", remoteLayerId, eventId), in: context);
                if l == nil {
                    l = ImageryLayer.mr_createEntity(in: context);
                }
                l?.populate(layer, eventId: eventId);
            } else {
                var l = Layer.mr_findFirst(with: NSPredicate(format: "(\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@)", remoteLayerId, eventId), in: context);
                if l == nil {
                    l = Layer.mr_createEntity(in: context)
                }
                l?.populate(layer, eventId: eventId);
            }
        }
        return layerRemoteIds;
    }
    
    @objc public static func refreshLayers(eventId: NSNumber) {
        let manager = MageSessionManager.shared();
        if let task = Layer.operationToPullLayers(eventId: eventId, success: nil, failure: nil) {
            manager?.addTask(task);
        }
    }
    
    static func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
    
    @objc public static func downloadGeoPackage(layer: Layer, success: (() -> Void)?, failure: ((Error) -> Void)?) {
        guard let currentEventId = Server.currentEventId(), let remoteId = layer.remoteId, let manager = MageSessionManager.shared(), let fileName = layer.file?[LayerFileKey.name.key] as? String, let baseURL = MageServer.baseURL(), let contentType = layer.file?[LayerFileKey.contentType.key] as? String else {
            return;
        }
        let url = "\(baseURL)/api/events/\(currentEventId)/layers/\(remoteId)"
        var urlPath = URL(fileURLWithPath: "\(getDocumentsDirectory())/geopackages/\(remoteId)/\(fileName)")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path)_\(remoteId)_from_server.gpkg");
        do {
            let request = try manager.requestSerializer.request(withMethod: "GET", urlString: url, parameters: nil);
            request.setValue(contentType, forHTTPHeaderField: "Accept")
            let task = manager.downloadTask(with: request as URLRequest) { downloadProgress in
                MagicalRecord.save { context in
                    guard let localLayer = layer.mr_(in: context) else {
                        return;
                    }
                    localLayer.downloadedBytes = NSNumber(value:downloadProgress.completedUnitCount);
                    NSLog("GeoPackage downloaded bytes \(downloadProgress.completedUnitCount)")
                } completion: { _, _ in
                    
                }
            } destination: { targetPath, response in
                return urlPath;
            } completionHandler: { response, filePath, error in
                if let error = error {
                    failure?(error);
                    return;
                } else {
                    success?()
                }
                
                if let fileString = filePath?.path {
                    NSLog("Downloaded GeoPackage to \(fileString)")
                    NotificationCenter.default.post(name: .GeoPackageDownloaded, object: nil, userInfo: [
                        "filePath":fileString,
                        "layerId":remoteId
                    ])
                }
            }
            
            task.taskDescription = "geopackage_download_\(remoteId)"
            if !FileManager.default.fileExists(atPath: urlPath.path) {
                let directoryToCreate = urlPath.deletingLastPathComponent();
                NSLog("Create directory for geopackage \(directoryToCreate)")
                try FileManager.default.createDirectory(at: directoryToCreate, withIntermediateDirectories: true, attributes: nil)
            } else {
                NSLog("GeoPackage still exists at \(urlPath), delete it")
                do {
                    try FileManager.default.removeItem(at: urlPath)
                } catch {
                    NSLog("Error deleting existing GeoPackage \(error)")
                }
                
                if FileManager.default.fileExists(atPath: urlPath.path) {
                    NSLog("GeoPackage file still exists at \(urlPath.path) after attempted deletion")
                }
            }
            
            MagicalRecord.save { context in
                guard let localLayer = layer.mr_(in: context) else {
                    return;
                }
                localLayer.downloading = true
            } completion: { _, _ in
                
            }
            
            manager.addTask(task);
        } catch {
            failure?(error)
        }
    }
    
    @objc public static func cancelGeoPackageDownload(layer: Layer) {
        guard let manager = MageSessionManager.shared(), let remoteId = layer.remoteId else {
            return;
        }
        
        for task in manager.downloadTasks where task.taskDescription == "geopackage_download_\(remoteId)" {
            task.cancel();
        }
        
        MagicalRecord.save { context in
            guard let localLayer = layer.mr_(in: context) else {
                return;
            }
            localLayer.downloadedBytes = 0;
            localLayer.downloading = false;
        } completion: { contextDidSave, error in

        }
    }
    
    static func layerId(json: [AnyHashable:Any]) -> NSNumber? {
        return json[LayerKey.id.key] as? NSNumber
    }
}
