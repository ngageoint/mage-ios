//
//  ObservationTileRepositoryTests.swift
//  MAGETests
//
//  Created by Dan Barela on 5/16/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import OHHTTPStubs

@testable import MAGE

final class ObservationTileRepositoryTests: XCTestCase {
    
    func testStuff() async {
        let location = CLLocationCoordinate2D(latitude: 39.62601343172716,longitude: -104.90165054798126)
        let zoom = 13.7806
        let tile = location.toTile(zoom: 13)

        let minTileLon = CLLocationCoordinate2D.longitudeFromTile(x: tile.x, zoom: Int(zoom))
        let maxTileLon = CLLocationCoordinate2D.longitudeFromTile(x: tile.x + 1, zoom: Int(zoom))
        let minTileLat = CLLocationCoordinate2D.latitudeFromTile(y: tile.y + 1, zoom: Int(zoom))
        let maxTileLat = CLLocationCoordinate2D.latitudeFromTile(y: tile.y, zoom: Int(zoom))

        let neCorner3857 = CLLocationCoordinate2D(latitude: maxTileLat, longitude: maxTileLon).degreesToMeters()
        let swCorner3857 = CLLocationCoordinate2D(latitude: minTileLat, longitude: minTileLon).degreesToMeters()

        let minTileX = swCorner3857.x
        let minTileY = swCorner3857.y
        let maxTileX = neCorner3857.x
        let maxTileY = neCorner3857.y

        let tileBitmapWidth = 512

        let pixel = location.toPixel(zoomLevel: Int(zoom), swCorner: swCorner3857, neCorner: neCorner3857, tileSize: Double(tileBitmapWidth))
        
        var minPixelX: Int = 0
        var maxPixelX: Int = 512
        var minPixelY: Int = 0
        var maxPixelY: Int = 512
        
        minPixelX = Int(pixel.x.rounded(.down))
        maxPixelX = Int(pixel.x.rounded(.up))
        minPixelY = Int(pixel.y.rounded(.down))
        maxPixelY = Int(pixel.y.rounded(.up))

//        let boundsRect = Rect(
//            floor(pixel.x).toInt(),
//            floor(pixel.y).toInt(),
//            ceil(pixel.x).toInt(),
//            ceil(pixel.y).toInt()
//        )
//        println(boundsRect)
        NSLog("hi")
        
    }

    func xtestGetItemKeys() async {
        Server.setCurrentEventId(1)
        
        let localDataSource = ObservationLocationStaticLocalDataSource()
        InjectedValues[\.observationLocationLocalDataSource] = localDataSource
        let localIconDataSource = ObservationIconStaticLocalDataSource()
        InjectedValues[\.observationIconLocalDataSource] = localIconDataSource
        let iconRepository = ObservationIconRepository()
        let tileRepository = ObservationsTileRepository()
        
        localDataSource.list.append(ObservationMapItem(
            observationId: URL(string: "magetest://observation/1"),
            observationLocationId: URL(string:"magetest://observationLocation/1"),
            geometry: SFPoint(xValue: -104.90241, andYValue: 39.62691),
//            iconPath: OHPathForFile("110.png", type(of: self)),
            maxLatitude:  39.62691,
            maxLongitude: -104.90241,
            minLatitude: 39.62691,
            minLongitude: -104.90241
        ))
        
        let itemKeys = await tileRepository.getItemKeys(
            minLatitude: 39.628632488021879,
            maxLatitude: 39.628632488021879,
            minLongitude: -104.90231457859423,
            maxLongitude: -104.90231457859423,
            latitudePerPixel: 0.000058806721412885429,
            longitudePerPixel: 0.000085830109961996306,
            zoom: 14,
            precise: true,
            distanceTolerance: 1000000.0
        )
        // this should hit one
        
        XCTAssertEqual(itemKeys.count, 1)
        
        // this should not hit
        let noItemKeys = await tileRepository.getItemKeys(
            minLatitude: 39.627465124235037,
            maxLatitude: 39.627465124235037,
            minLongitude: -104.90363063984378,
            maxLongitude: -104.90363063984378,
            latitudePerPixel: 0.000058806721412885429,
            longitudePerPixel: 0.000085830109961996306,
            zoom: 14,
            precise: true,
            distanceTolerance: 1000.0
        )
        
        XCTAssertEqual(noItemKeys.count, 0)
    }
}
