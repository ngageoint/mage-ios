//
//  GeoPackageFeatureBottomSheetViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import GeoPackage

class GeoPackageFeatureBottomSheetViewModel: ObservableObject {
    @Published var itemKey: String
    @Published var coordinate: CLLocationCoordinate2D
    @Published var title: String
    @Published var date: Date?
    @Published var secondaryTitle: String?
    @Published var layerName: String
    @Published var featureDetail: String?
    @Published var icon: UIImage?
    @Published var color: Color?
    @Published var propertyRows: [GeoPackageProperty] = []
    @Published var attributeRelations: [GeoPackageRelation] = []
    @Published var mediaRows: [GeoPackageMediaRow] = []
    
    init(featureItem: GeoPackageFeatureItem) {
        itemKey = featureItem.toKey().toKey()
        coordinate = featureItem.coordinate
        title = featureItem.createTitle()
        date = featureItem.getDate()
        secondaryTitle = featureItem.createSecondaryTitle()
        layerName = featureItem.layerName
        featureDetail = featureItem.featureDetail
        icon = featureItem.icon
        if let style = featureItem.style, style.hasColor(), let styleColor = style.color() {
            color = Color(uiColor: styleColor.uiColor())
        }
        setPropertyRows(featureItem: featureItem)
        addAttributeRows(featureItem: featureItem)
        mediaRows = createMediaRows(mediaRows: featureItem.mediaRows)
    }
    
    func setPropertyRows(featureItem: GeoPackageFeatureItem) {
        guard let featureRowData = featureItem.featureRowData else {
            return;
        }
        
        let geometryColumn: String? = featureRowData.geometryColumn()
        if let values = featureRowData.values() as? [String : Any] {
            for (key, value) in values.sorted(by: { $0.0 < $1.0 }) {
                if key != geometryColumn {
                    propertyRows.append(createProperty(featureItem: featureItem, key: key, value: value))
                }
            }
        }
    }
    
    func createProperty(featureItem: GeoPackageFeatureItem, key: String, value: Any) -> GeoPackageProperty {
        var valueString: String?
        
        if let dataType = featureItem.featureDataTypes?[key] {
            let gpkgDataType = GPKGDataTypes.fromName(dataType)
            if (gpkgDataType == .DT_BOOLEAN) {
                valueString = "\((value as? Int) == 0 ? "true" : "false")"
            } else if (gpkgDataType == .DT_DATE) {
                let dateDisplayFormatter = DateFormatter();
                dateDisplayFormatter.dateFormat = "yyyy-MM-dd";
                dateDisplayFormatter.timeZone = TimeZone(secondsFromGMT: 0);
                
                if let date = value as? Date {
                    valueString = "\(dateDisplayFormatter.string(from: date))"
                }
            } else if (gpkgDataType == .DT_DATETIME) {
                valueString = "\((value as? NSDate)?.formattedDisplay() ?? value)";
            } else {
                valueString = "\(value)"
            }
        } else {
            valueString = "\(value)"
        }
        
        return GeoPackageProperty(name: key, value: valueString)
    }
    
    func addAttributeRows(featureItem: GeoPackageFeatureItem) {
        guard let attributeRows = featureItem.attributeRows else {
            return;
        }
        
        for attributeRow in attributeRows {
            guard let featureRowData = attributeRow.featureRowData else {
                continue;
            }
            
            var attributeRowData: [GeoPackageProperty] = []
            
            let geometryColumn: String? = featureRowData.geometryColumn()
            if let values = featureRowData.values() as? [String : Any] {
                for (key, value) in values.sorted(by: { $0.0 < $1.0 }) {
                    if key != geometryColumn {
                        attributeRowData.append(createProperty(featureItem: featureItem, key: key, value: value))
                    }
                }
            }
            
            let medias: [GeoPackageMediaRow] = createMediaRows(mediaRows: attributeRow.mediaRows)
            attributeRelations.append(GeoPackageRelation(properties: attributeRowData, medias: medias))
        }
    }
    
    func createMediaRows(mediaRows: [GPKGMediaRow]?) -> [GeoPackageMediaRow] {
        var medias: [GeoPackageMediaRow] = []
        for mediaRow in mediaRows ?? [] {
            var title = "media"
            if mediaRow.hasColumn(withColumnName: "title"), let titleValue = mediaRow.value(withColumnName: "title") as? String {
                title = titleValue
            } else if mediaRow.hasColumn(withColumnName: "name"), let nameValue = mediaRow.value(withColumnName: "name") as? String {
                title = nameValue
            }
            
            if let image = mediaRow.dataImage() {
                medias.append(GeoPackageMediaRow(title: title, image: image))
            } else {
                medias.append(GeoPackageMediaRow(title: title, image: UIImage(systemName: "paperclip", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))!))
            }
        }
        return medias
    }
}
