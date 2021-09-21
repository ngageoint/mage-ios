//
//  GeoPackageFeatureItem.swift
//  MAGE
//
//  Created by Daniel Barela on 9/20/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

@objc class GeoPackageFeatureItem: NSObject {
    @objc public override init() {
        
    }
    
    @objc public init(featureId: Int = 0, featureRowData:GPKGFeatureRowData?, featureDataTypes: [String : String]? = nil, coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid, layerName: String? = nil, icon: UIImage? = nil, style: GPKGStyleRow? = nil, mediaRows: [GPKGMediaRow]? = nil) {
        self.featureId = featureId
        self.coordinate = coordinate
        self.icon = icon
        self.mediaRows = mediaRows
        self.layerName = layerName
        self.featureRowData = featureRowData
        self.featureDataTypes = featureDataTypes
        self.style = style;
    }
    
    @objc public var featureId: Int = 0;
    @objc public var featureDetail: String?;
    @objc public var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid;
    @objc public var icon: UIImage?;
    @objc public var mediaRows: [GPKGMediaRow]?;
    @objc public var featureRowData: GPKGFeatureRowData?;
    @objc public var featureDataTypes: [String : String]?;
    @objc public var layerName: String?;
    @objc public var style: GPKGStyleRow?;
}
