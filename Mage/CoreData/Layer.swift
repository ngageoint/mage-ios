//
//  Layer.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import Layer
import Persistence
import ServerDTO

extension Layer {
    
    @objc public static let GeoPackageDownloaded = "mil.nga.giat.mage.geopackage.downloaded";
    
    @objc public static func layerType(json: [AnyHashable : Any]) -> String? {
        return json[LayerKey.type.key] as? String;
    }

    @objc public static func refreshLayers(eventId: NSNumber) {
        Task {
            do {
                try await DependencyContainer.shared.useCaseFactory
                    .resolve(.RefreshLayersUseCase)
                    .execute(eventID: EventID(eventId))
            } catch {
                NSLog("Failed to refresh layers: \(error.localizedDescription)")
            }
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
