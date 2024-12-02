//
//  GeoPackageFeatureKey.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class GeoPackageFeatureKey: NSObject, Codable {
    let geoPackageName: String
    let featureId: Int
    let layerName: String
    let maxFeaturesFound: Bool
    let featureCount: Int
    let tableName: String
    
    @objc public init(geoPackageName: String, featureId: Int, layerName: String, tableName: String) {
        self.geoPackageName = geoPackageName
        self.featureId = featureId
        self.layerName = layerName
        self.tableName = tableName
        self.maxFeaturesFound = false
        self.featureCount = 1
    }
    
    @objc public init(geoPackageName: String, featureCount: Int, layerName: String, tableName: String) {
        self.geoPackageName = geoPackageName
        self.featureId = -1
        self.layerName = layerName
        self.tableName = tableName
        self.maxFeaturesFound = true
        self.featureCount = featureCount
    }
    
    @objc public func toKey() -> String {
        let jsonEncoder = JSONEncoder()
        if let jsonData = try? jsonEncoder.encode(self) {
            return String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        }
        return ""
    }
    
    static func fromKey(jsonString: String) -> GeoPackageFeatureKey? {
        if let jsonData = jsonString.data(using: .utf8) {
            let jsonDecoder = JSONDecoder()
            return try? jsonDecoder.decode(GeoPackageFeatureKey.self, from: jsonData)
        }
        return nil
    }
}
