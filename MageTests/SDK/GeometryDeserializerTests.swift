//
//  GeometryDeserializerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/12/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import MAGE

class GeometryDeserializerTests: KIFSpec {
    
    override func spec() {
        
        describe("GeometryDeserializer Tests") {
            
            it("should deserialize a point") {
                let point: [String:Any] = [
                    "type": "Point",
                    "coordinates": [1,2]
                ]
                
                let geometry: SFPoint = GeometryDeserializer.parseGeometry(json: point) as! SFPoint;
                expect(geometry).toNot(beNil());
                expect(geometry.x).to(equal(1));
                expect(geometry.y).to(equal(2));
                expect(geometry.hasZ).to(beFalse());
                expect(geometry.hasM).to(beFalse());
            }
            
            it("should throw an exception") {
                let point: [String:Any] = [
                    "type": "Turtle",
                    "coordinates": [1,2]
                ]
                
                let geometry: SFPoint? = GeometryDeserializer.parseGeometry(json: point) as? SFPoint;
                expect(geometry).to(beNil());
                
            }
        }
    }
}
