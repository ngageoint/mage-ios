//
//  GeoPackageFeatureItem.swift
//  MAGE
//
//  Created by Daniel Barela on 9/20/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import geopackage_ios
import ExceptionCatcher

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

@objc class GeoPackageFeatureItem: NSObject {
//    @objc public override init() {
//        
//    }
    
    @objc public init(maxFeaturesReached: Bool, featureCount: Int = 0, geoPackageName: String, layerName: String, tableName: String) {
        self.maxFeaturesReached = maxFeaturesReached;
        self.featureCount = featureCount;
        self.layerName = layerName;
        self.tableName = tableName;
        self.geoPackageName = geoPackageName
    }
    
    @objc public init(
        featureId: Int = 0,
        geoPackageName: String,
        featureRowData:GPKGFeatureRowData?,
        featureDataTypes: [String : String]? = nil,
        coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid,
        layerName: String,
        tableName: String,
        icon: UIImage? = nil,
        style: GPKGStyleRow? = nil,
        mediaRows: [GPKGMediaRow]? = nil,
        attributeRows: [GeoPackageFeatureItem]? = nil
    ) {
        self.geoPackageName = geoPackageName
        self.featureId = featureId
        self.coordinate = coordinate
        self.icon = icon
        self.mediaRows = mediaRows
        self.layerName = layerName
        self.featureRowData = featureRowData
        self.featureDataTypes = featureDataTypes
        self.style = style;
        self.attributeRows = attributeRows;
        self.tableName = tableName
    }
    
    func toKey() -> GeoPackageFeatureKey {
        GeoPackageFeatureKey(geoPackageName: geoPackageName, featureId: featureId, layerName: layerName, tableName: layerName)
    }
    
    @objc public var featureId: Int = 0;
    @objc public var featureDetail: String?;
    @objc public var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid;
    @objc public var icon: UIImage?;
    @objc public var mediaRows: [GPKGMediaRow]?;
    @objc public var attributeRows: [GeoPackageFeatureItem]?;
    @objc public var featureRowData: GPKGFeatureRowData?;
    @objc public var featureDataTypes: [String : String]?;
    @objc public var layerName: String;
    @objc public var style: GPKGStyleRow?;
    @objc public var maxFeaturesReached: Bool = false;
    @objc public var featureCount: Int = 1;
    @objc public var geoPackageName: String
    @objc public var tableName: String
    
    @objc public init?(featureRow: GPKGFeatureRow, geoPackage: GPKGGeoPackage, layerName: String, projection: PROJProjection) {
        self.layerName = layerName
        self.geoPackageName = geoPackage.name
        self.tableName = featureRow.tableName()
        super.init()
        do {
            try ExceptionCatcher.catch {
                let rte = GPKGRelatedTablesExtension(geoPackage: geoPackage)
                var mediaTables: [GPKGExtendedRelation] = []
                var attributeTables: [GPKGExtendedRelation] = []
                let styles = GPKGFeatureTableStyles(geoPackage: geoPackage, andTable: featureRow.featureTable)
                
                var medias: [GPKGMediaRow] = []
                var attributes: [GPKGAttributesRow] = []
                
                if let relationsDao = GPKGExtendedRelationsDao.create(withDatabase: geoPackage.database),
                    relationsDao.tableExists()
                {
                    if let relations = relationsDao.relations(toBaseTable: featureRow.tableName()) {
                        do {
                            try ExceptionCatcher.catch {
                                while relations.moveToNext() {
                                    if let extendedRelation = relationsDao.relation(relations),
                                       extendedRelation.relationType() == GPKGRelationTypes.fromName(GPKG_RT_MEDIA_NAME) {
                                        mediaTables.append(extendedRelation)
                                    } else if let extendedRelation = relationsDao.relation(relations),
                                              extendedRelation.relationType() == GPKGRelationTypes.fromName(GPKG_RT_ATTRIBUTES_NAME) {
                                        attributeTables.append(extendedRelation)
                                    }
                                }
                                relations.close()
                            }
                        } catch {
                            relations.close()
                        }
                    }
                }
                
                
                let featureId = featureRow.idValue()
                for relation in mediaTables {
                    let relatedMedia = rte?.mappings(forTableName: relation.mappingTableName, withBaseId: featureId)
                    let mediaDao = rte?.mediaDao(forTableName: relation.relatedTableName)
                    if let relatedMediaRows = mediaDao?.rows(withIds: relatedMedia) {
                        medias.append(contentsOf: relatedMediaRows)
                    }
                }
                
                for relation in attributeTables {
                    let relatedAttributes = rte?.mappings(forTableName: relation.mappingTableName, withBaseId: featureId) ?? []
                    let attributesDao = geoPackage.attributesDao(withTableName: relation.relatedTableName)
                    for relatedAttribute in relatedAttributes {
                        if let row = attributesDao?.query(forIdObject: relatedAttribute) as? GPKGAttributesRow {
                            attributes.append(row)
                        }
                    }
                }
                
                var values: [String: NSObject] = [:]
                var featureDataTypes: [String: String] = [:]
                var geometryColumnName: String?
                var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
                
                let dataColumnsDao = GPKGDataColumnsDao(database: geoPackage.database)
                
                let geometryColumn = featureRow.geometryColumnIndex()
                for columnIndex in 0...featureRow.columnCount()-1 {
                    let value = featureRow.value(with: columnIndex)
                    var columnName = featureRow.columnName(with: columnIndex)
                    if let dataColumnsDao = dataColumnsDao, dataColumnsDao.tableExists() {
                        if let dataColumn = dataColumnsDao.dataColumn(byTableName: featureRow.table.tableName(), andColumnName: columnName) {
                            columnName = dataColumn.name
                        }
                    }
                    
                    if columnIndex == geometryColumn {
                        geometryColumnName = columnName
                        if let geometry = value as? GPKGGeometryData {
                            var centroid = geometry.geometry.centroid()
                            if let transform = SFPGeometryTransform(from: projection, andToEpsg: 4326) {
                                centroid = transform.transform(centroid)
                                transform.destroy()
                            }
                            if let centroid = centroid {
                                coordinate = CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue)
                            }
                        }
                    }
                    
                    if let columnName = columnName {
                        if let column = featureRow.featureColumns.column(with: columnIndex),
                           let dataTypeName = GPKGDataTypes.name(column.dataType)
                        {
                            featureDataTypes[columnName] = dataTypeName
                        }
                        if let value = value {
                            values[columnName] = value
                        }
                    }
                }
                
                let featureRowData = GPKGFeatureRowData(values: values, andGeometryColumnName: geometryColumnName)
                
                var attributeFeatureRowData: [GeoPackageFeatureItem] = []
                for row in attributes {
                    if let featureItem = GeoPackageFeatureItem(row: row, geoPackage: geoPackage, layerName: layerName) {
                        attributeFeatureRowData.append(featureItem)
                    }
                }
                var icon: UIImage?
                var style: GPKGStyleRow?
                if let featureStyle = styles?.featureStyle(withFeature: featureRow) {
                    style = featureStyle.style
                    
                    if featureStyle.hasIcon() {
                        icon = featureStyle.icon.dataImage()
                    }
                }
                self.featureId = Int(featureId)
                self.featureRowData = featureRowData
                self.featureDataTypes = featureDataTypes
                self.coordinate = coordinate
                self.layerName = layerName
                self.icon = icon
                self.style = style
                self.mediaRows = medias
                self.attributeRows = attributeFeatureRowData
            }
        } catch {
            debugPrint(error)
            return nil
        }
    }
    
    @objc public init?(row: GPKGAttributesRow, geoPackage: GPKGGeoPackage, layerName: String) {
        self.geoPackageName = geoPackage.name
        self.tableName = row.tableName()
        let rte = GPKGRelatedTablesExtension(geoPackage: geoPackage)
        let dataColumnsDao = GPKGDataColumnsDao(database: geoPackage.database)
        
        var attributeMediaTables: [GPKGExtendedRelation] = []
        var attributeMedias: [GPKGMediaRow] = []
        
        if let relationsDao = GPKGExtendedRelationsDao.create(withDatabase: geoPackage.database),
            relationsDao.tableExists()
        {
            if let relations = relationsDao.relations(toBaseTable: row.attributesTable.tableName()) {
                do {
                    try ExceptionCatcher.catch {
                        while relations.moveToNext() {
                            if let extendedRelation = relationsDao.relation(relations),
                               extendedRelation.relationType() == GPKGRelationTypes.fromName(GPKG_RT_MEDIA_NAME) {
                                attributeMediaTables.append(extendedRelation)
                            }
                        }
                        relations.close()
                    }
                } catch {
                    relations.close()
                }
            }
        }
        
        let attributeId = row.idValue()
        for relation in attributeMediaTables {
            if let relatedMedia = rte?.mappings(forTableName: relation.mappingTableName, withBaseId: attributeId) {
                let mediaDao = rte?.mediaDao(forTableName: relation.relatedTableName)
                attributeMedias = mediaDao?.rows(withIds: relatedMedia) ?? []
            }
        }
        
        var values: [String: NSObject] = [:]
        var attributeDataTypes: [String: String] = [:]
        
        for columnIndex in 0...row.columnCount()-1 {
            let value = row.value(with: columnIndex)
            var columnName = row.columnName(with: columnIndex)
            if let dataColumnsDao = dataColumnsDao, dataColumnsDao.tableExists() {
                if let dataColumn = dataColumnsDao.dataColumn(byTableName: row.table.tableName(), andColumnName: columnName) {
                    columnName = dataColumn.name
                }
            }
            if let columnName = columnName {
                if let column = row.attributesColumns.column(with: columnIndex),
                   let dataTypeName = GPKGDataTypes.name(column.dataType) {
                    attributeDataTypes[columnName] = dataTypeName
                }
                if let value = value {
                    values[columnName] = value
                }

            }
        }
        
        self.featureRowData = GPKGFeatureRowData(values: values, andGeometryColumnName: nil)
        self.featureId = Int(row.idValue())
        self.featureDataTypes = attributeDataTypes
        self.layerName = layerName
        self.mediaRows = attributeMedias
    }
    
    func getDate() -> Date? {
        if let values = self.featureRowData?.values(), let titleKey = values.keys.first(where: { key in
            return ["date", "timestamp"].contains((key as? String)?.lowercased());
        }) {
            return values[titleKey] as? Date;
        }
        return nil;
    }
    
    func createTitle() -> String {
        let title = "GeoPackage Feature";
        if maxFeaturesReached {
            return "\(featureCount) Features";
        }
        if let values = featureRowData?.values(), let titleKey = values.keys.first(where: { key in
            return ["name", "title", "primaryfield"].contains((key as? String)?.lowercased());
        }) {
            return values[titleKey] as? String ?? title;
        }
        return title;
    }
    
    func createSecondaryTitle() -> String? {
        if let values = featureRowData?.values(), let titleKey = values.keys.first(where: { key in
            return ["secondaryfield", "subtitle", "variantfield"].contains((key as? String)?.lowercased());
        }) {
            if let title = values[titleKey] as? String {
                return title;
            }
        }
        return nil
    }
}
