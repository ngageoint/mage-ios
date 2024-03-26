//
//  MapBoundingBox.swift
//
//
//  Created by Daniel Barela on 3/14/24.
//

import Foundation
import CoreLocation

public class MapBoundingBox: Codable, ObservableObject {
    @Published var swCorner: (x: Double, y: Double)
    @Published var neCorner: (x: Double, y: Double)

    enum CodingKeys: String, CodingKey {
        case swCornerX
        case swCornerY
        case neCornerX
        case neCornerY
    }

    init(swCorner: (x: Double, y: Double), neCorner: (x: Double, y: Double)) {
        self.swCorner = swCorner
        self.neCorner = neCorner
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let swCornerX = try values.decode(Double.self, forKey: .swCornerX)
        let swCornerY = try values.decode(Double.self, forKey: .swCornerY)
        swCorner = (x: swCornerX, y: swCornerY)

        let neCornerX = try values.decode(Double.self, forKey: .neCornerX)
        let neCornerY = try values.decode(Double.self, forKey: .neCornerY)
        neCorner = (x: neCornerX, y: neCornerY)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(swCorner.x, forKey: .swCornerX)
        try container.encode(swCorner.y, forKey: .swCornerY)
        try container.encode(neCorner.x, forKey: .neCornerX)
        try container.encode(neCorner.y, forKey: .neCornerY)
    }

    var swCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: swCorner.y, longitude: swCorner.x)
    }

    var seCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: swCorner.y, longitude: neCorner.x)
    }

    var neCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: neCorner.y, longitude: neCorner.x)
    }

    var nwCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: neCorner.y, longitude: swCorner.x)
    }
}
