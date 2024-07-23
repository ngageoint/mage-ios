import CoreLocation
import MapKit

public struct DMSCoordinate {
    var degrees: Int?
    var minutes: Int?
    var seconds: Int?
    var decimalSeconds: Int?
    var direction: String?
}

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

    // attempts to parse what was passed in to DDD° MM' SS.sss" (NS) or returns "" if unparsable
    public static func parseToDMSString(
        _ string: String?,
        addDirection: Bool = false,
        latitude: Bool = false
    ) -> String? {
        guard let string = string else {
            return nil
        }

        if string.isEmpty {
            return ""
        }

        let parsed = parseDMS(coordinate: string, addDirection: addDirection, latitude: latitude)

        let direction = parsed.direction ?? ""

        var seconds = ""
        if let parsedSeconds = parsed.seconds {
            let roundedSeconds = Int(Double("\(parsedSeconds).\(parsed.decimalSeconds ?? 0)")?.rounded() ?? 0)
            seconds = String(format: "%02d", roundedSeconds)
        }

        var minutes = ""
        if let parsedMinutes = parsed.minutes {
            minutes = String(format: "%02d", parsedMinutes)
        }

        var degrees = ""
        if let parsedDegrees = parsed.degrees {
            degrees = "\(parsedDegrees)"
        }

        if !degrees.isEmpty {
            degrees = "\(degrees)° "
        }
        if !minutes.isEmpty {
            minutes = "\(minutes)\' "
        }
        if !seconds.isEmpty {
            seconds = "\(seconds)\" "
        }

        return "\(degrees)\(minutes)\(seconds)\(direction)"
    }

    public static func latitudeDMSString(coordinate: CLLocationDegrees) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = 2

        var latDegrees: Int = Int(coordinate)
        var latMinutes = Int(abs((coordinate.truncatingRemainder(dividingBy: 1) * 60.0)))
        var latSeconds = abs(
            (
                (coordinate.truncatingRemainder(dividingBy: 1) * 60.0)
                    .truncatingRemainder(dividingBy: 1) * 60.0
            )).rounded()
        if latSeconds == 60 {
            latSeconds = 0
            latMinutes += 1
        }
        if latMinutes == 60 {
            latDegrees += 1
            latMinutes = 0
        }
        return """
        \(abs(latDegrees))° \(formatter.string(for: latMinutes) ?? "")\' \
        \(formatter.string(for: latSeconds) ?? "")\" \(latDegrees >= 0 ? "N" : "S")
        """
    }

    public static func longitudeDMSString(coordinate: CLLocationDegrees) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = 2

        var lonDegrees: Int = Int(coordinate)
        var lonMinutes = Int(abs((coordinate.truncatingRemainder(dividingBy: 1) * 60.0)))
        var lonSeconds = abs(
            (
                (coordinate.truncatingRemainder(dividingBy: 1) * 60.0)
                    .truncatingRemainder(dividingBy: 1) * 60.0
            )).rounded()
        if lonSeconds == 60 {
            lonSeconds = 0
            lonMinutes += 1
        }
        if lonMinutes == 60 {
            lonDegrees += 1
            lonMinutes = 0
        }
        return """
        \(abs(lonDegrees))° \(formatter.string(for: lonMinutes) ?? "")\' \
        \(formatter.string(for: lonSeconds) ?? "")\" \(lonDegrees >= 0 ? "E" : "W")
        """
    }

    // must be in the form of Deg°Min'Sec"Dir
    static func parseWellFormedDMS(
        coordinate: String
    ) -> DMSCoordinate? {
        let split = coordinate.components(separatedBy: ["°", "'", "\""])
        if split.count != 4 {
            return nil
        }
        if let degrees = Int(split[0]),
           let minutes = Int(split[1]),
           let seconds = Int(split[2]) {
            return DMSCoordinate(
                degrees: degrees,
                minutes: minutes,
                seconds: seconds,
                direction: split[3]
            )
        }
        return nil
    }

    // Need to parse the following formats:
    // 1. 112233N 0112244W
    // 2. N 11 ° 22'33 "- W 11 ° 22'33
    // 3. 11 ° 22'33 "N - 11 ° 22'33" W
    // 4. 11° 22'33 N 011° 22'33 W
    static func parseDMS(
        coordinate: String,
        addDirection: Bool = false,
        latitude: Bool = false
    ) -> DMSCoordinate {
        if let wellFormed = CLLocationCoordinate2D.parseWellFormedDMS(
            coordinate: coordinate) {
            return wellFormed
        }
        var coordinateToParse = coordinate.trimmingCharacters(in: .whitespacesAndNewlines)

        var dmsCoordinate: DMSCoordinate = DMSCoordinate()
        if addDirection {
            // check if the first character is negative
            if coordinateToParse.firstIndex(of: "-") == coordinateToParse.startIndex {
                dmsCoordinate.direction = latitude ? "S" : "W"
            } else {
                dmsCoordinate.direction = latitude ? "N" : "E"
            }
        }

        var charactersToKeep = CharacterSet()
        charactersToKeep.formUnion(.decimalDigits)
        charactersToKeep.insert(charactersIn: ".NSEWnsew")
        coordinateToParse = coordinate.components(separatedBy: charactersToKeep.inverted).joined()

        if let direction = coordinateToParse.last {
            // the last character might be a direction not a number
            if direction.wholeNumberValue == nil {
                dmsCoordinate.direction = "\(direction)".uppercased()
                coordinateToParse = "\(coordinateToParse.dropLast(1))"
            }
        }
        if let direction = coordinateToParse.first {
            // the first character might be a direction not a number
            if direction.wholeNumberValue == nil {
                dmsCoordinate.direction = "\(direction)".uppercased()
                coordinateToParse = "\(coordinateToParse.dropFirst(1))"
            }
        }
        // remove all characers except numbers and decimal points
        charactersToKeep = CharacterSet()
        charactersToKeep.formUnion(.decimalDigits)
        charactersToKeep.insert(charactersIn: ".")
        coordinateToParse = coordinate.components(separatedBy: charactersToKeep.inverted).joined()

        // split the numbers before the decimal seconds
        if coordinateToParse.isEmpty {
            return dmsCoordinate
        }
        let split = coordinateToParse.split(separator: ".")

        coordinateToParse = "\(split[0])"
        let decimalSeconds = split.count == 2 ? Int(split[1]) : nil

        dmsCoordinate.seconds = Int(coordinateToParse.suffix(2))
        coordinateToParse = "\(coordinateToParse.dropLast(2))"

        dmsCoordinate.minutes = Int(coordinateToParse.suffix(2))
        dmsCoordinate.degrees = Int(coordinateToParse.dropLast(2))

        CLLocationCoordinate2D.correctMinutesAndSeconds(dmsCoordinate: &dmsCoordinate, decimalSeconds: decimalSeconds)

        return dmsCoordinate
    }

    static func correctMinutesAndSeconds(dmsCoordinate: inout DMSCoordinate, decimalSeconds: Int?) {
        if dmsCoordinate.degrees == nil {
            if dmsCoordinate.minutes == nil {
                dmsCoordinate.degrees = dmsCoordinate.seconds
                dmsCoordinate.seconds = nil
            } else {
                dmsCoordinate.degrees = dmsCoordinate.minutes
                dmsCoordinate.minutes = dmsCoordinate.seconds
                dmsCoordinate.seconds = nil
            }
        }

        if dmsCoordinate.minutes == nil && dmsCoordinate.seconds == nil && decimalSeconds != nil {
            // this would be the case if a decimal degrees was passed in ie 11.123
            let decimal = Double(".\(decimalSeconds ?? 0)") ?? 0.0
            dmsCoordinate.minutes = Int(abs((decimal.truncatingRemainder(dividingBy: 1) * 60.0)))
            let seconds = abs(
                (
                    (decimal.truncatingRemainder(dividingBy: 1) * 60.0)
                        .truncatingRemainder(dividingBy: 1)
                    * 60.0)
            )
            dmsCoordinate.seconds = Int(seconds.rounded())
        } else if let decimalSeconds = decimalSeconds {
            dmsCoordinate.decimalSeconds = decimalSeconds
        }

        if dmsCoordinate.seconds == 60 {
            dmsCoordinate.minutes = (dmsCoordinate.minutes ?? 0) + 1
            dmsCoordinate.seconds = 0
        }

        if dmsCoordinate.minutes == 60 {
            dmsCoordinate.degrees = (dmsCoordinate.degrees ?? 0) + 1
            dmsCoordinate.minutes = 0
        }
    }
}

public extension MKCoordinateRegion {
    
    func padded(percentage: Double) -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta * (1.0 + percentage),
                longitudeDelta: span.longitudeDelta * (1.0 + percentage)
            )
        )
    }

    func corners() -> (southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        let southWest = CLLocationCoordinate2D(
            latitude: center.latitude - (span.latitudeDelta / 2.0),
            longitude: center.longitude - (span.longitudeDelta / 2.0))
        let northEast = CLLocationCoordinate2D(
            latitude: center.latitude + (span.latitudeDelta / 2.0),
            longitude: center.longitude + (span.longitudeDelta / 2.0))
        return (southWest: southWest, northEast: northEast)
    }

    func intersectingTileBounds(
        includeBorder: Bool = true,
        minZoom: Int = 0,
        maxZoom: Int = 18
    ) -> [Int: (southWest: (x: Int, y: Int), northEast: (x: Int, y: Int))] {
        var tiles: [Int: (southWest: (x: Int, y: Int), northEast: (x: Int, y: Int))] = [:]
        let corners = corners()

        for i in minZoom...maxZoom {
            let southWestTile = corners.southWest.toTile(zoom: i)
            let northEastTile = corners.northEast.toTile(zoom: i)
            if includeBorder {
                tiles[i] = (
                    (x: southWestTile.x - 1, y: southWestTile.y - 1),
                    (x: northEastTile.x + 1, y: northEastTile.y + 1)
                )
            } else {
                tiles[i] = (southWestTile, northEastTile)
            }
        }
        return tiles
    }
}

extension CLLocationCoordinate2D: Codable {
    public enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try values.decode(Double.self, forKey: .latitude)
        let longitude = try values.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
}

extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
