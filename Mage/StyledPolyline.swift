//
//  StyledPolyline.m
//  MAGE
//
//

import CoreLocation

@objc class StyledPolyline : MKPolyline, OverlayRenderable {
    var renderer: MKOverlayRenderer {
        get {
            let renderer = MKPolylineRenderer(polyline: self)
            renderer.strokeColor = lineColor
            renderer.lineWidth = lineWidth
            return renderer
        }
    }
    
    @objc public var lineColor: UIColor = .black
    @objc public var lineWidth: CGFloat = 1.0
    @objc var observationRemoteId: String?
    public var _observation: Observation?
    
    public var observation: Observation? {
        get {
            guard let observationRemoteId = observationRemoteId else {
                return _observation
            }
            
            return Observation.mr_findFirst(byAttribute: "remoteId", withValue: observationRemoteId, in: NSManagedObjectContext.mr_default())
        }
        set {
            if let remoteId = newValue?.remoteId {
                observationRemoteId = remoteId
            } else {
                _observation = newValue
            }
        }
    }
    
    @objc static func generate(path: [[NSNumber]])-> StyledPolyline {
        var coordinates: [CLLocationCoordinate2D] = []
        for point in path {
            coordinates.append(CLLocationCoordinate2D(latitude: point[1].doubleValue, longitude: point[0].doubleValue))
        }
        
        return StyledPolyline(coordinates: coordinates, count: path.count)
    }
    
    @objc static func create(polyline: MKPolyline) -> StyledPolyline {
        let styledPolyline = StyledPolyline(points: polyline.points(), count: polyline.pointCount)
        styledPolyline.title = polyline.title
        styledPolyline.subtitle = polyline.subtitle
        return styledPolyline
    }
    
    @objc public func setLineColor(hex: String, alpha: CGFloat = 1.0) {
        self.lineColor = UIColor(hex: hex)?.withAlphaComponent(alpha) ?? self.lineColor
    }

}
