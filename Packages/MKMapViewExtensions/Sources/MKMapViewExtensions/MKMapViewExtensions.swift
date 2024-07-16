import MapKit

extension MKMapView {

    static let MAX_CLUSTER_ZOOM = 17

     // modified from https://github.com/stleamist/MKZoomLevel  Since we use 512x512 tiles
    // MARK: Zoom Level Getter & Setter
    
    public var zoomLevel: CGFloat {
        get { return zoomLevel(from: bottomLongitudeDelta) }
        set { self.setZoomLevel(newValue, animated: false)}
    }
    
    func setZoomLevel(_ zoomLevel: CGFloat, animated: Bool) {
        let oldBottomLongitudeDelta = bottomLongitudeDelta
        let newBottomLongitudeDelta = longitudeDelta(from: zoomLevel)
        
        let oldCenterCoordinateDistance: CLLocationDistance
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, *) {
            oldCenterCoordinateDistance = self.camera.centerCoordinateDistance
        } else {
            let pitchInRadians = self.camera.pitch * (.pi / 180)
            oldCenterCoordinateDistance = self.camera.altitude / cos(Double(pitchInRadians))
        }
        
        let newCenterCoordinateDistance = oldCenterCoordinateDistance * (newBottomLongitudeDelta / oldBottomLongitudeDelta)
        
        let camera = MKMapCamera(
            lookingAtCenter: self.camera.centerCoordinate,
            fromDistance: newCenterCoordinateDistance,
            pitch: self.camera.pitch,
            heading: self.camera.heading
        )
        
        self.setCamera(camera, animated: animated)
    }
    
    // MARK: Unit Conversion
    
    private func zoomLevel(from longitudeDelta: CLLocationDegrees) -> CGFloat {
        return log2(360 * self.frame.size.width / (128 * CGFloat(longitudeDelta))) - 1.0
    }
    
    private func longitudeDelta(from zoomLevel: CGFloat) -> CLLocationDegrees {
        return CLLocationDistance(360 * self.frame.size.width / (128 * exp2(zoomLevel)))
    }
    
    // MARK: Calculation
    
    private var bottomLongitudeDelta: CLLocationDegrees {
        let bottomCoordinates = self.bottomCoordinatesAtPrimeMeridian
        let bottomLongitudeDeltaHorizontalComponent = bottomCoordinates.southEast.longitude - bottomCoordinates.northWest.longitude
        let bottomLongitudeDelta = bottomLongitudeDeltaHorizontalComponent / cos(positiveHeading)
        return bottomLongitudeDelta
    }
    
    private var positiveHeading: CLLocationDirection {
        let bottomCoordinates = self.bottomCoordinatesAtPrimeMeridian
        
        let p1 = MKMapPoint(bottomCoordinates.northWest)
        let p2 = MKMapPoint(bottomCoordinates.southEast)
        
        let width = p2.x - p1.x
        let height = p2.y - p1.y
        let hypotenuse = hypot(width, height)
        
        let heading = asin(height / hypotenuse)
        
        return heading
    }
    
    private var bottomCoordinatesAtPrimeMeridian: (northWest: CLLocationCoordinate2D, southEast: CLLocationCoordinate2D) {
        let bottomRect = CGRect(x: 0, y: bounds.height, width: bounds.width, height: 0)
        
        /// If you calculate the distance using two points from`convert(_:toCoordinateFrom:)`
        /// instead of a region from `convert(_:toRegionFrom)`,
        /// it is hard to check if the two points cross the 180th meridian
        /// considering the case when the map heads to the south.
        var region = self.convert(bottomRect, toRegionFrom: self)
        
        /// Normalize the longtidue of the center coordinate into the prime meridian
        /// in order to prevent incorrect distance from being calculated
        /// when the `region` crosses the 180th meridian.
        region.center.longitude = 0
        
        let northWestCoordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude + (region.span.latitudeDelta / 2),
            longitude: region.center.longitude - (region.span.longitudeDelta / 2)
        )
        let southEastCoordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude - (region.span.latitudeDelta / 2),
            longitude: region.center.longitude + (region.span.longitudeDelta / 2)
        )
        
        return (northWestCoordinate, southEastCoordinate)
    }
}
