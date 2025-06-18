//
//  GeometryDeserializer.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/24/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

import sf_ios
import sf_geojson_ios

@objc public class GeometryDeserializer: NSObject {
    
    @objc public static func parseGeometry(json: [AnyHashable: Any]?) -> SFGeometry? {
        guard let json = json else {
            return nil;
        }
        var sfggeometry: SFGGeometry?;
        do {
            try ObjC.catchException {
                sfggeometry = SFGFeatureConverter.tree(toGeometry: json)
            }
        }
        catch {
            print("An error ocurred: \(error)")
        }
        return sfggeometry?.geometry()
    }
}
