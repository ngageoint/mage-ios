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

        NotificationCenter.default.addObserver(forName: .MAGEFormFetched, object: nil, queue: .main) { [weak self] notification in
            if let event: Event = notification.object as? Event {
                if event.remoteId == Server.currentEventId() {
                    if let mapState = self?.mapState {
                        self?.refreshOverlay(mapState: mapState)
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
        let viewWidth = await mapView.frame.size.width
        let viewHeight = await mapView.frame.size.height

        let latitudePerPixel = await mapView.region.span.latitudeDelta / viewHeight
        let longitudePerPixel = await mapView.region.span.longitudeDelta / viewWidth

        let iconPixelSize = await repository?.getToleranceInPixels(zoom: mapView.zoomLevel) ?? .zero

        // this is how many degrees to add and subtract to ensure we query for the item around the tap location
        let iconToleranceHeightDegrees = latitudePerPixel * iconPixelSize.height
        let iconToleranceWidthDegrees = longitudePerPixel * iconPixelSize.width

        let queryLocationMinLongitude = location.longitude - iconToleranceWidthDegrees
        let queryLocationMaxLongitude = location.longitude + iconToleranceWidthDegrees
        let queryLocationMinLatitude = location.latitude - iconToleranceHeightDegrees
        let queryLocationMaxLatitude = location.latitude + iconToleranceHeightDegrees

        let items = await repository?.getTileableItems(
            minLatitude: queryLocationMinLatitude,
            maxLatitude: queryLocationMaxLatitude,
            minLongitude: queryLocationMinLongitude,
            maxLongitude: queryLocationMaxLongitude,
            latitudePerPixel: latitudePerPixel,
            longitudePerPixel: longitudePerPixel,
            zoom: mapView.zoomLevel,
            precise: true
        )

        return items?.compactMap { image in
            if let observationMapImage = image as? ObservationMapImage {
                return observationMapImage.mapItem
            }
            return nil
        }
    }
}
