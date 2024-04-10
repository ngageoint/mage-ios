//
//  ObservationMap.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceTileOverlay

class ObservationsMap: DataSourceMap {

    override var minZoom: Int {
        get {
            return 2
        }
        set {

        }
    }

    override init(repository: TileRepository? = nil, mapFeatureRepository: MapFeatureRepository? = nil) {
        super.init(repository: repository, mapFeatureRepository: mapFeatureRepository)
        userDefaultsShowPublisher = UserDefaults.standard.publisher(for: \.hideObservations)

        UserDefaults.standard.publisher(for: \.observationTimeFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshMap(mapState: mapState)
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterUnitKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshMap(mapState: mapState)
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterNumberKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshMap(mapState: mapState)
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.importantFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshMap(mapState: mapState)
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.favoritesFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")
                if let mapState = self?.mapState {
                    self?.refreshMap(mapState: mapState)
                }
            }
            .store(in: &cancellable)

        NotificationCenter.default.addObserver(forName: .MAGEFormFetched, object: nil, queue: .main) { [weak self] notification in
            if let event: Event = notification.object as? Event {
                if event.remoteId == Server.currentEventId() {
                    if let mapState = self?.mapState {
                        self?.refreshMap(mapState: mapState)
                    }
                }
            }
        }
    }

    override func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]? {
        return await super.items(
            at: location,
            mapView: mapView,
            touchPoint: touchPoint
        )?.compactMap { image in
            if let observationMapImage = image as? ObservationMapImage {
                return observationMapImage.mapItem
            }
            return nil
        }
    }
}
