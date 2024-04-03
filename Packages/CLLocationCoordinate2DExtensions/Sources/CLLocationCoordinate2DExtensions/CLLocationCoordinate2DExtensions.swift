import CoreLocation

extension CLLocationCoordinate2D {
    public func toPixel(
        zoomLevel: Int,
        swCorner: (x: Double, y: Double),
        neCorner: (x: Double, y: Double),
        tileSize: Double,
        canCross180thMeridian: Bool = true
    ) -> CGPoint {
        var object3857Location = to3857()

        // TODO: this logic should be improved
        // just check on the edges of the world presuming that no light will span 90 degrees, which none will
        if canCross180thMeridian && (longitude < -90 || longitude > 90) {
            // if the x location has fallen off the left side and this tile is on the other side of the world
            if object3857Location.x > swCorner.x
                && swCorner.x < 0
                && object3857Location.x > 0 {
                let newCoordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude - 360.0)
                object3857Location = newCoordinate.to3857()
            }

            // if the x value has fallen off the right side and this tile is on the other side of the world
            if object3857Location.x < neCorner.x
                && neCorner.x > 0
                && object3857Location.x < 0 {
                let newCoordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude + 360.0)
                object3857Location = newCoordinate.to3857()
            }
        }

        let xPosition = (
            (
                (object3857Location.x - swCorner.x)
                / (neCorner.x - swCorner.x)
            )
            * tileSize
        )
        let yPosition = tileSize - (
            (
                (object3857Location.y - swCorner.y)
                / (neCorner.y - swCorner.y)
            )
            * tileSize
        )
        return CGPoint(x: xPosition, y: yPosition)
    }

    public func to3857() -> (x: Double, y: Double) {
        let a = 6378137.0
        let lambda = longitude / 180 * Double.pi
        let phi = latitude / 180 * Double.pi
        let x = a * lambda
        let y = a * log(tan(Double.pi / 4 + phi / 2))

        return (x: x, y: y)
    }

    // MARK: These methods and constants are copied from SFGeometryUtils in sf-ios
    // it is impossible to use a pod as a dependency in a swift package
    static let SF_WGS84_HALF_WORLD_LON_WIDTH: Double = 180.0
    static let SF_WGS84_HALF_WORLD_LAT_HEIGHT: Double = 90.0
    static let SF_DEGREES_TO_METERS_MIN_LAT: Double = -89.99999999999999
    static let SF_WEB_MERCATOR_HALF_WORLD_WIDTH: Double = 20037508.342789244

    public func degreesToMeters() -> (x: Double, y: Double) {
        let x = normalize(x: longitude, maxX: CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)
        var y = min(latitude, CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LAT_HEIGHT)
        y = max(y, CLLocationCoordinate2D.SF_DEGREES_TO_METERS_MIN_LAT)
        let xValue = x * CLLocationCoordinate2D.SF_WEB_MERCATOR_HALF_WORLD_WIDTH
        / CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH
        var yValue = log(tan(
            (CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LAT_HEIGHT + y) * .pi
            / (2 * CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)))
        / (.pi / CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)
        yValue = yValue * CLLocationCoordinate2D.SF_WEB_MERCATOR_HALF_WORLD_WIDTH
        / CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH
        return (x: xValue, y: yValue)
    }

    func normalize(x: Double, maxX: Double) -> Double {
        var normalized: Double = x
        if x < -maxX {
            normalized = x + (maxX * 2.0)
        } else if x > maxX {
            normalized = x - (maxX * 2.0)
        }
        return normalized
    }

    public static func metersToDegrees(x: Double, y: Double) -> (x: Double, y: Double) {
        let xValue = x * CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH
        / CLLocationCoordinate2D.SF_WEB_MERCATOR_HALF_WORLD_WIDTH
        var yValue = y * CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH
        / CLLocationCoordinate2D.SF_WEB_MERCATOR_HALF_WORLD_WIDTH
        yValue = atan(exp(yValue
                          * (.pi / CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)))
        / .pi * (2 * CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)
        - CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LAT_HEIGHT
        return (x: xValue, y: yValue)
    }

    public func long2Tile(zoom: Int) -> Int {
        let zoomExp = Double(pow(Double(2), Double(zoom)))
        return Int(min(zoomExp - 1, floor(Double((longitude + 180.0) / 360.0) * zoomExp)))
    }

    public func lat2Tile(zoom: Int) -> Int {
        let zoomExp = Double(pow(Double(2), Double(zoom)))
        return Int(floor(
            ((1.0 - log(tan((latitude * .pi) / 180.0) + 1.0 / cos((latitude * .pi) / 180.0)) / .pi) / 2.0) * zoomExp
        ))
    }

    public func toTile(zoom: Int) -> (x: Int, y: Int) {
        return (x: long2Tile(zoom: zoom), y: lat2Tile(zoom: zoom))
    }

    public static func longitudeFromTile(x: Int, zoom: Int) -> Double {
        return Double(x) / pow(2.0, Double(zoom)) * 360.0 - 180.0
    }

    public static func latitudeFromTile(y: Int, zoom: Int) -> Double {
        let yLocation = Double.pi - 2.0 * Double.pi * Double(y) / pow(2.0, Double(zoom))
        return 180.0 / Double.pi * atan(0.5 * (exp(yLocation) - exp(-yLocation)))
    }
}
