//
//  MapStateRepository.swift
//  MAGE
//
//  Created by Dan Barela on 7/3/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct MapStateRepositoryProviderKey: InjectionKey {
    static var currentValue: MapStateRepository = MapStateRepository()
}

extension InjectedValues {
    var mapStateRepository: MapStateRepository {
        get { Self[MapStateRepositoryProviderKey.self] }
        set { Self[MapStateRepositoryProviderKey.self] = newValue }
    }
}

public class MapStateRepository: ObservableObject {
    
    @Published var zoom: Int?
    @Published var region: MKCoordinateRegion?
    
}
