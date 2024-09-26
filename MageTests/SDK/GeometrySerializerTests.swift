//
//  GeometrySerializerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/12/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import sf_ios

@testable import MAGE

class GeometrySerializerTests: KIFSpec {
    
    override func spec() {
        
        describe("GeometrySerializer Tests") {
            
            it("should serialize a point") {
                let geometry: SFPoint = SFPoint(x: 1, andY: 2);
                
                let json: [AnyHashable:Any] = GeometrySerializer.serializeGeometry(geometry)!;
                
                let point: [AnyHashable:Any] = [
                    "type": "Point",
                    "coordinates": [1,2]
                ]
                
                expect(json).toNot(beNil());
                expect(json["type"] as? String).to(equal(point["type"] as? String));
                expect(json["coordinates"] as? [NSNumber]).to(equal(point["coordinates"] as? [NSNumber]))
            }
        }
    }
}
