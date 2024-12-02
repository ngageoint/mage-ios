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
import Combine

extension UserDefaults {
    @objc public var mapType: Int {
        get {
            return integer(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
}

public class MapState: ObservableObject, Hashable {
    public static func == (lhs: MapState, rhs: MapState) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var id = UUID()
    
    private var cancellable: Set<AnyCancellable> = Set()

    public init() {
        UserDefaults.standard.publisher(for: \.mapType)
            .receive(on: RunLoop.main)
            .sink { [weak self] mapType in
                self?.mapType = mapType
            }
            .store(in: &cancellable)
    }

    @Published public var mapType: Int = Int(MKMapType.standard.rawValue)

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
