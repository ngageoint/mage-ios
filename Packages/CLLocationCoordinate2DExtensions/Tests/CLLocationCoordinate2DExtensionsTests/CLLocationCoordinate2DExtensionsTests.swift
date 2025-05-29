import XCTest
import CoreLocation

@testable import CLLocationCoordinate2DExtensions

final class CLLocationCoordinate2DExtensionsTests: XCTestCase {

    func testPixelsCrossingDateLine() {
        let tileSize = 512.0
        // Check behavior when a nav warning crosses the prime meridian AND 90E
        // Tile (left of prime meridian): 66.51S,90.00W - 0,0
        let testCoord1 = CLLocationCoordinate2D(latitude: -8.89, longitude: 92.46)
        let pixel = testCoord1.toPixel(zoomLevel: 2, swCorner: (x: -10018754, y: -10018754), neCorner: (x: 0, y: 0), tileSize: tileSize, canCross180thMeridian: false)
        // 182 degrees between left edge of tile (90W) and coord (92E) => coord is 2.03 tiles to the right
        XCTAssertGreaterThan(pixel.x, 2 * tileSize)
        XCTAssertLessThan(pixel.x, 2.1 * tileSize)

        // Check behavior when a nav warning nears the 180th meridian AND crosses 90W
        // Tile (left of 180th meridian): 90.00E,0.00N - 180.00E,66.51N
        let testCoord2 = CLLocationCoordinate2D(latitude: 28.88, longitude: -175.0)
        let pixel2 = testCoord2.toPixel(zoomLevel: 2, swCorner: (x: 10018754, y: 0), neCorner: (x: 20037508, y: 10018754), tileSize: tileSize, canCross180thMeridian: false)
        // avoid placing coord right of the current tile (beyond 180 degrees) to prevent render issues
        // 265 degrees between left edge of tile (90E) and coord (175W) => coord is 2.94 tiles to the left
        XCTAssertLessThan(pixel2.x, -2.9 * tileSize)
        XCTAssertGreaterThan(pixel2.x, -3 * tileSize)
    }

    func testConversion() {
        let point = CLLocationCoordinate2D(latitude: 21.943049, longitude: -112.500003)
        let point2 = point.degreesToMeters()
        XCTAssertEqual(-12523443.048201751, point2.x, accuracy: 0.00000001)
        XCTAssertEqual(2504688.958883909, point2.y, accuracy: 0.00000001)

        let point3 = CLLocationCoordinate2D.metersToDegrees(x: point2.x, y: point2.y)
        XCTAssertEqual(-112.500003, point3.x, accuracy: 0.0000000000001)
        XCTAssertEqual(21.943049, point3.y, accuracy: 0.0000000000001)
    }
}
