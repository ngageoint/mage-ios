//
//  CoordinateDisplayTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 1/7/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import CoreLocation

@testable import MAGE

class LocationUtilitiesTests: QuickSpec {
    
    override func spec() {
        
        describe("LocationUtilitiesTests Tests") {

            it("should display the coordinate") {
                UserDefaults.standard.locationDisplay = .latlng
                
                expect(CLLocationCoordinate2D(latitude: 15.48, longitude: 20.47).toDisplay()).to(equal("15.4800, 20.4700"))

                UserDefaults.standard.locationDisplay = .mgrs
                expect(CLLocationCoordinate2D(latitude: 15.48, longitude: 20.47).toDisplay()).to(equal("34PDC4314911487"))

                UserDefaults.standard.locationDisplay = .dms
                expect(CLLocationCoordinate2D(latitude: 15.48, longitude: 20.47).toDisplay()).to(equal("15° 28' 48\" N, 20° 28' 12\" E"))

                expect(CLLocationCoordinate2D(latitude: 15.48, longitude: 20.47).toDisplay(short: true)).to(equal("15° 28' 48\" N, 20° 28' 12\" E"))
                UserDefaults.standard.locationDisplay = .dms
                expect(LocationUtilities.latitudeDMSString(coordinate:11.186388888888889)).to(equal("11° 11' 11\" N"))
                expect(CLLocationCoordinate2D.parse(coordinates:"111111N, 121212E").toDisplay()).to(equal("11° 11' 11\" N, 12° 12' 12\" E"))
                
                expect(LocationUtilities.latitudeDMSString(coordinate:0.186388888888889)).to(equal("0° 11' 11\" N"))
                expect(CLLocationCoordinate2D.parse(coordinates:"01111N, 01212E").toDisplay()).to(equal("0° 11' 11\" N, 0° 12' 12\" E"))
            }
            
            it("should split the coordinate string") {
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: nil)).to(equal([]))
                
                var coordinates = "112233N 0152144W"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["112233N","0152144W"]))

                coordinates = "N 11 ° 22'33 \"- W 15 ° 21'44"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["N11°22'33\"","W15°21'44"]))
                
                coordinates = "N 11 ° 22'30 \""
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["N11°22'30\""]))

                coordinates = "11 ° 22'33 \"N - 15 ° 21'44\" W"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["11°22'33\"N","15°21'44\"W"]))

                coordinates = "11° 22'33 N 015° 21'44 W"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["11°22'33N","015°21'44W"]))

                coordinates = "11.4584 15.6827"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["11.4584","15.6827"]))

                coordinates = "-11.4584 15.6827"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["-11.4584","15.6827"]))

                coordinates = "11.4584 -15.6827"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["11.4584","-15.6827"]))

                coordinates = "11.4584, 15.6827"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["11.4584","15.6827"]))

                coordinates = "-11.4584, 15.6827"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["-11.4584","15.6827"]))

                coordinates = "11.4584, -15.6827"
                expect(CLLocationCoordinate2D.splitCoordinates(coordinates: coordinates)).to(equal(["11.4584","-15.6827"]))
            }
            
            it("should parse the coordinate string") {
                expect(CLLocationCoordinate2D.parse(coordinate:nil)).to(beNil())
                
                var coordinates = "112230N"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(11.375))
                
                coordinates = "112230"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(11.375))
                
                coordinates = "purple"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(beNil())
                
                coordinates = "N 11 ° 22'30 \""
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(11.375)))
                
                coordinates = "N 11 ° 22'30.36 \""
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(11.375)))
                
                coordinates = "N 11 ° 22'30.remove \""
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(11.375)))

                coordinates = "11 ° 22'30 \"N"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(11.375)))

                coordinates = "11° 22'30 N"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(11.375)))

                coordinates = "11.4584"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(11.4584)))

                coordinates = "-11.4584"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(-11.4584)))

                coordinates = "0151545W"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(-15.2625)))

                coordinates = "W 15 ° 15'45"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(-15.2625)))

                coordinates = "15 ° 15'45\" W"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(-15.2625)))

                coordinates = "015° 15'45 W"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(-15.2625)))

                coordinates = "15.6827"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(15.6827)))

                coordinates = "-15.6827"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(-15.6827)))
                
                coordinates = "0.186388888888889"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(equal(CLLocationDegrees(0.186388888888889)))
                
                coordinates = "0° 11' 11\" N"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(beCloseTo(CLLocationDegrees(0.186388888888889)))
                
                coordinates = "705600N"
                expect(CLLocationCoordinate2D.parse(coordinate: coordinates)).to(beCloseTo(CLLocationDegrees(70.9333)))
            }
            
            it("should parse the coordinate string to a DMS string") {
                expect(LocationUtilities.parseToDMSString(nil)).to(beNil())
                
                var coordinates = "112230N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 22' 30\" N"))

                coordinates = "112230"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 22' 30\" "))

                coordinates = "30N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("30° N"))

                coordinates = "3030N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("30° 30' N"))

                coordinates = "purple"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("E"))

                coordinates = ""
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal(""))

                coordinates = "N 11 ° 22'30 \""
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 22' 30\" N"))

                coordinates = "N 11 ° 22'30.36 \""
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 22' 30\" N"))

                coordinates = "112233.99N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 22' 34\" N"))

                coordinates = "11.999999N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("12° 00' 00\" N"))

                coordinates = "N 11 ° 22'30.remove \""
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 22' 30\" N"))

                coordinates = "11 ° 22'30 \"N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 22' 30\" N"))

                coordinates = "11° 22'30 N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 22' 30\" N"))

                coordinates = "11"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° "))

                coordinates = "11.4584"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true, latitude: true)).to(equal("11° 27' 30\" N"))

                coordinates = "-11.4584"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true, latitude: true)).to(equal("11° 27' 30\" S"))

                coordinates = "11.4584"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true)).to(equal("11° 27' 30\" E"))

                coordinates = "-11.4584"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true)).to(equal("11° 27' 30\" W"))

                coordinates = "11.4584"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true, latitude: true)).to(equal("11° 27' 30\" N"))

                coordinates = "-11.4584"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true, latitude: true)).to(equal("11° 27' 30\" S"))

                coordinates = "0151545W"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("015° 15' 45\" W"))

                coordinates = "113000W"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 30' 00\" W"))

                coordinates = "W 15 ° 15'45"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("15° 15' 45\" W"))

                coordinates = "15 ° 15'45\" W"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("15° 15' 45\" W"))

                coordinates = "015° 15'45 W"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("015° 15' 45\" W"))

                coordinates = "15.6827"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("15° 40' 58\" "))

                coordinates = "-15.6827"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("15° 40' 58\" "))

                coordinates = "15.6827"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true)).to(equal("15° 40' 58\" E"))

                coordinates = "-15.6827"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true)).to(equal("15° 40' 58\" W"))

                coordinates = "113000NNNN"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("11° 30' 00\" N"))
                
                coordinates = "0.186388888888889"
                expect(LocationUtilities.parseToDMSString(coordinates, addDirection: true)).to(equal("0° 11' 11\" E"))
                
                coordinates = "0° 11' 11\" N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("0° 11' 11\" N"))
                
                coordinates = "705600N"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("70° 56' 00\" N"))
                
                coordinates = "70° 560'"
                expect(LocationUtilities.parseToDMSString(coordinates)).to(equal("7° 05' 60\" "))
            }
            
            it("should parse to DMS") {
                let coordinate = "113000NNNN"
                let parsed = LocationUtilities.parseDMS(coordinate: coordinate)
                expect(parsed.direction).to(equal("N"))
                expect(parsed.seconds).to(equal(0))
                expect(parsed.minutes).to(equal(30))
                expect(parsed.degrees).to(equal(11))
            }
            
            it("should parse to DMS 2") {
                let coordinate = "70560"
                let parsed = LocationUtilities.parseDMS(coordinate: coordinate)
                expect(parsed.direction).to(beNil())
                expect(parsed.seconds).to(equal(60))
                expect(parsed.minutes).to(equal(5))
                expect(parsed.degrees).to(equal(7))
            }
            
            it("should split the coordinate string") {
                var coordinates = "112230N 0151545W"
                var parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.375))
                expect(parsed.longitude).to(equal(-15.2625))
                
                coordinates = "N 11 ° 22'30 \"- W 15 ° 15'45"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.375))
                expect(parsed.longitude).to(equal(-15.2625))

                coordinates = "11 ° 22'30 \"N - 15 ° 15'45\" W"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.375))
                expect(parsed.longitude).to(equal(-15.2625))

                coordinates = "11° 22'30 N 015° 15'45 W"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.375))
                expect(parsed.longitude).to(equal(-15.2625))
                
                coordinates = "N 11° 22'30 W 015° 15'45 "
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.375))
                expect(parsed.longitude).to(equal(-15.2625))

                coordinates = "11.4584 15.6827"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.4584))
                expect(parsed.longitude).to(equal(15.6827))

                coordinates = "-11.4584 15.6827"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(-11.4584))
                expect(parsed.longitude).to(equal(15.6827))

                coordinates = "11.4584 -15.6827"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.4584))
                expect(parsed.longitude).to(equal(-15.6827))

                coordinates = "11.4584, 15.6827"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.4584))
                expect(parsed.longitude).to(equal(15.6827))

                coordinates = "-11.4584, 15.6827"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(-11.4584))
                expect(parsed.longitude).to(equal(15.6827))

                coordinates = "11.4584, -15.6827"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude).to(equal(11.4584))
                expect(parsed.longitude).to(equal(-15.6827))
                
                coordinates = "11.4584"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude.isNaN).to(beTrue())
                expect(parsed.longitude).to(equal(11.4584))
                
                coordinates = "11 ° 22'30 \"N"
                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                expect(parsed.latitude.isNaN).to(beTrue())
                // TODO: is this wrong? shouldn't this be latitude?
                expect(parsed.longitude).to(equal(11.375))
                
                // future test
                //                coordinates = "11-22-30N 015-15-45W"
                //                parsed = CLLocationCoordinate2D.parse(coordinates: coordinates)
                //                expect(parsed.latitude.isNaN).to(beTrue())
                //                expect(parsed.latitude).to(equal(11.375))
                //                expect(parsed.longitude).to(equal(-15.2625))
            }
            
            it("should validate DMS latitude input") {
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: nil)).to(beFalse())
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: "NS1122N")).to(beFalse())
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: "002233.NS")).to(beFalse())
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: "ABCDEF.NS")).to(beFalse())
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: "11NSNS.1N")).to(beFalse())
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: "1111NS.1N")).to(beFalse())
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: "113000NNN")).to(beFalse())
                
                var validString = "112233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: validString)).to(beTrue())
                validString = "002233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: validString)).to(beTrue())
                validString = "02233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: validString)).to(beTrue())
                validString = "12233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: validString)).to(beTrue())
                validString = "002233S"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: validString)).to(beTrue())
                validString = "002233.2384S"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: validString)).to(beTrue())
                validString = "1800000E"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: validString)).to(beTrue())
                validString = "1800000W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: validString)).to(beTrue())
                validString = "900000S"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: validString)).to(beTrue())
                validString = "900000N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: validString)).to(beTrue())

                var invalidString = "2233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "33N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "2N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = ".123N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = ""
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())

                invalidString = "2233W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "33W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "2W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "233W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = ".123W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = ""
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())

                invalidString = "112233"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "1a2233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "1a2233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "11a233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "1122a3N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "912233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "-112233N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "116033N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "112260N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())

                invalidString = "1812233W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "-112233W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "002233E"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "002233N"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "1800001E"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "1800000.1E"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "1800001W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "1800000.1W"
                expect(LocationUtilities.validateLongitudeFromDMS(longitude: invalidString)).to(beFalse())
                invalidString = "900001N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "900000.1N"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "900001S"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "900000.1S"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "108900S"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
                invalidString = "100089S"
                expect(LocationUtilities.validateLatitudeFromDMS(latitude: invalidString)).to(beFalse())
            }
            
            it("should return a latitude dms string") {
                var coordinate = CLLocationDegrees(11.1)
                expect(LocationUtilities.latitudeDMSString(coordinate:coordinate)).to(equal("11° 06' 00\" N"))
                coordinate = CLLocationDegrees(-11.1)
                expect(LocationUtilities.latitudeDMSString(coordinate:coordinate)).to(equal("11° 06' 00\" S"))
                coordinate = CLLocationDegrees(0.125)
                expect(LocationUtilities.latitudeDMSString(coordinate: coordinate)).to(equal("0° 07' 30\" N"))
                coordinate = CLLocationDegrees(-0.125)
                expect(LocationUtilities.latitudeDMSString(coordinate: coordinate)).to(equal("0° 07' 30\" S"))
            }
            
            it("should return a longitude dms string") {
                var coordinate = CLLocationDegrees(11.1)
                expect(LocationUtilities.longitudeDMSString(coordinate:coordinate)).to(equal("11° 06' 00\" E"))
                coordinate = CLLocationDegrees(-11.1)
                expect(LocationUtilities.longitudeDMSString(coordinate:coordinate)).to(equal("11° 06' 00\" W"))
                coordinate = CLLocationDegrees(18.077251)
                expect(LocationUtilities.longitudeDMSString(coordinate:coordinate)).to(equal("18° 04' 38\" E"))
                coordinate = CLLocationDegrees(0.125)
                expect(LocationUtilities.longitudeDMSString(coordinate: coordinate)).to(equal("0° 07' 30\" E"))
                coordinate = CLLocationDegrees(-0.125)
                expect(LocationUtilities.longitudeDMSString(coordinate: coordinate)).to(equal("0° 07' 30\" W"))
            }
        }
    }
}
