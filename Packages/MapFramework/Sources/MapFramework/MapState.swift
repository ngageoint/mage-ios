//
//  MapState.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import MapKit

public class MapState: ObservableObject, Hashable {
    public static func == (lhs: MapState, rhs: MapState) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var id = UUID()

    public init() {
        
    }

    @AppStorage("mapType") public var mapType: Int = Int(MKMapType.standard.rawValue)

    @Published public var userTrackingMode: Int = Int(MKUserTrackingMode.none.rawValue)
    @Published public var mixinStates: [String: Any] = [:]

    public var centerDate: Date?
    @Published public var center: MKCoordinateRegion? {
        didSet {
            centerDate = Date()
        }
    }
    @Published public var forceCenter: MKCoordinateRegion? {
        didSet {
            forceCenterDate = Date()
        }
    }
    public var forceCenterDate: Date?

    @Published public var coordinateCenter: CLLocationCoordinate2D? {
        didSet {
            forceCenterDate = Date()
        }
    }
}
