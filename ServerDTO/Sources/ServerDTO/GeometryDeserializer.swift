//
//  GeometryDeserializer.swift
//  ServerDTO
//
//

import SimpleFeatures
import SimpleFeaturesGeoJSON
import ExceptionCatcher

@objc public class GeometryDeserializer: NSObject {
    
    @objc public static func parseGeometry(json: [AnyHashable: Any]?) -> SFGeometry? {
        guard let json = json else {
            return nil;
        }
        var sfggeometry: SFGGeometry?;
        do {
            sfggeometry = try ExceptionCatcher.catch {
                SFGFeatureConverter.tree(toGeometry: json)
            }
        }
        catch {
            print("An error ocurred: \(error)")
        }
        return sfggeometry?.geometry()
    }
}
