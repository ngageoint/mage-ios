//
//  Settings.swift
//  MAGE
//
//  Created by William Newman on 1/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum MapSearchType: Int32 {
    case none
    case native
    case nominatim
}

@objc public class Settings: NSManagedObject {
    
    var mapSearchType: MapSearchType {
        get { return MapSearchType(rawValue: self.mapSearchTypeCode) ?? .none }
        set { self.mapSearchTypeCode = newValue.rawValue }
    }
    
    @objc public static func getSettings() -> Settings? {
        return Settings.mr_findFirst()
    }
    
    @objc public func populate(_ json: [AnyHashable : Any]) {
        self.mapSearchUrl = json[SettingsKey.mobileNominatimUrl.key] as? String
        let mapSearchType = json[SettingsKey.mobileSearchType.key] as? String
        switch (mapSearchType) {
            case "NATIVE": self.mapSearchType = .native
            case "NOMINATIM": self.mapSearchType = .nominatim
            default: self.mapSearchType = .none
        }
    }
    
    @objc public static func operationToPullMapSettings(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let manager = MageSessionManager.shared(), let baseURL = MageServer.baseURL() else {
            return nil;
        }
        let url = "\(baseURL)/api/settings/map";
        
        let task = manager.get_TASK(url, parameters: nil, progress: nil) { task, response in
            guard let response = response as? [AnyHashable : Any] else {
                return;
            }

            MagicalRecord.save { context in
                var settings = Settings.mr_findFirst(in: context)
                if (settings == nil) {
                    settings = Settings.mr_createEntity(in: context)
                }

                settings?.populate(response)
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
}
