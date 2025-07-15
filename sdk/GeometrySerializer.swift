//
//  GeometrySerializer.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/25/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

import SimpleFeatures
import SimpleFeaturesGeoJSON

@objc public class GeometrySerializer: NSObject {
    
    @objc public static func serializeGeometry(_ geometry: SFGeometry?) -> [AnyHashable: Any]? {
        guard let geometry = geometry else {
            return nil;
        }
        var json: [AnyHashable: Any]?;
        do {
            try ObjC.catchException {
                json = SFGFeatureConverter.simpleGeometry(toTree: geometry)
            }
        }
        catch {
            MageLogger.misc.error("An error ocurred: \(error)")
        }
        return json
    }
}
