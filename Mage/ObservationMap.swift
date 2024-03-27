//
//  ObservationMap.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceTileOverlay

class ObservationMap: DataSourceMap {

    override var minZoom: Int {
        get {
            return 2
        }
        set {

        }
    }

    override init(repository: TileRepository? = nil) {
        super.init(repository: repository)
        userDefaultsShowPublisher = UserDefaults.standard.publisher(for: \.hideObservations)

        UserDefaults.standard.publisher(for: \.observationTimeFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshOverlay(mapState: mapState)
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterUnitKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshOverlay(mapState: mapState)
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterNumberKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshOverlay(mapState: mapState)
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.importantFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshOverlay(mapState: mapState)
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.favoritesFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshOverlay(mapState: mapState)
                }
            }
            .store(in: &cancellable)
    }
}
