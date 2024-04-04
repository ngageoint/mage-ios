//
//  DataSourceMap.swift
//  MAGE
//
//  Created by Daniel Barela on 3/14/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import DataSourceTileOverlay
import MKMapViewExtensions

class DataSourceMap: MapMixin {
    var uuid: UUID = UUID()
    var cancellable = Set<AnyCancellable>()
    var minZoom = 2

    var repository: TileRepository?
//    var mapFeatureRepository: MapFeatureRepository?

    var mapState: MapState?
    var mapView: MKMapView?
    var lastChange: Date?
    var overlays: [MKOverlay] = []
    var renderers: [MKOverlayRenderer] = []
    var annotations: [MKAnnotation] = []

    var focusNotificationName: Notification.Name?

    var userDefaultsShowPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Bool>?
    var orderPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Int>?

    var show = false
    var repositoryAlwaysShow: Bool {
        repository?.alwaysShow ?? false //mapFeatureRepository?.alwaysShow ?? false
    }

    var dataSourceKey: String {
        repository?.dataSource.key ?? "" //mapFeatureRepository?.dataSource.key ?? ""
    }

    init(repository: TileRepository? = nil) { //}, mapFeatureRepository: MapFeatureRepository? = nil) {
        self.repository = repository
//        self.mapFeatureRepository = mapFeatureRepository
    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        self.mapView = mapView
        self.mapState = mapState

        self.setupDataSourceUpdatedPublisher(mapState: mapState)
        self.setupUserDefaultsShowPublisher(mapState: mapState)
        self.setupOrderPublisher(mapState: mapState)
        updateMixin(mapView: mapView, mapState: mapState)

        // this would eventually be rendered unnecessary when we switch to SwiftUI as it would watch the
        // StateObject and trigger an update when it changes
        mapState.objectWillChange
            .makeConnectable()
            .autoconnect()
            .sink { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    if let mapState = self?.mapState {
                        self?.updateMixin(mapView: mapView, mapState: mapState)
                    }
                }
            }
            .store(in: &cancellable)
//        LocationManager.shared().$current10kmMGRS
//            .receive(on: RunLoop.main)
//            .sink { [weak self] _ in
//                self?.refreshOverlay(mapState: mapState)
//            }
//            .store(in: &cancellable)
    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {
        let stateKey = "FetchRequestMixin\(dataSourceKey)DateUpdated"
        if lastChange == nil
            || lastChange != mapState.mixinStates[stateKey] as? Date {
            lastChange = mapState.mixinStates[stateKey] as? Date ?? Date()

            if mapState.mixinStates[stateKey] as? Date == nil {
                DispatchQueue.main.async {
                    mapState.mixinStates[stateKey] = self.lastChange
                }
            }
            for overlay in overlays {
                mapView.removeOverlay(overlay)
            }
            mapView.removeAnnotations(annotations)
            overlays = []
            annotations = []

            if !show && !repositoryAlwaysShow {
                return
            }
            if let repository = repository {
                let newOverlay = DataSourceTileOverlay(tileRepository: repository, key: dataSourceKey)
                newOverlay.tileSize = CGSize(width: 512, height: 512)
                newOverlay.minimumZ = self.minZoom

                overlays.append(newOverlay)
                addFeatures(features: AnnotationsAndOverlays(annotations: [], overlays: overlays), mapView: mapView)
            }

//            Task {
//                let features = await mapFeatureRepository?.getAnnotationsAndOverlays()
//                if let features = features {
//                    annotations.append(contentsOf: features.annotations)
//                    overlays.append(contentsOf: features.overlays)
//                    await MainActor.run {
//                        addFeatures(features: features, mapView: mapView)
//                    }
//                }
//            }
        }
    }

    func addFeatures(features: AnnotationsAndOverlays, mapView: MKMapView) {
        mapView.addAnnotations(features.annotations)
        // find the right place
//        let mapOrder = UserDefaults.standard.dataSourceMapOrder(dataSourceKey)
        let mapOrder = 0
        if mapView.overlays(in: .aboveLabels).isEmpty {
            for overlay in features.overlays {
                mapView.insertOverlay(overlay, at: 0, level: .aboveLabels)
            }
            return
        }
//        else {
//            for added in mapView.overlays(in: .aboveLabels) {
//                if let added = added as? any DataSourceOverlay,
//                   let key = added.key,
//                   let addedOverlay = added as? MKTileOverlay {
//                    let addedOrder = 0 //UserDefaults.standard.dataSourceMapOrder(key)
//                    if addedOrder < mapOrder {
//                        for overlay in features.overlays {
//                            mapView.insertOverlay(overlay, below: addedOverlay)
//                        }
//                        return
//                    }
//                }
//            }
//        }

        for overlay in features.overlays {
            mapView.insertOverlay(overlay, at: mapView.overlays(in: .aboveLabels).count, level: .aboveLabels)
        }
    }

    func removeMixin(mapView: MKMapView, mapState: MapState) {
        for overlay in overlays {
            mapView.removeOverlay(overlay)
        }
        mapView.removeAnnotations(annotations)
    }

    func refreshOverlay(mapState: MapState) {
        DispatchQueue.main.async {
            self.mapState?.mixinStates[
                "FetchRequestMixin\(self.dataSourceKey)DateUpdated"
            ] = Date()
        }
    }

    func setupDataSourceUpdatedPublisher(mapState: MapState) {
        NotificationCenter.default.publisher(for: .DataSourceUpdated)
            .receive(on: RunLoop.main)
            .compactMap {
                $0.object as? DataSourceUpdatedNotification
            }
            .sink { item in
                let key = self.dataSourceKey
                if item.key == key {
                    NSLog("New data for \(key), refresh overlay, clear the cache")
                    self.repository?.clearCache(completion: {
                        self.refreshOverlay(mapState: mapState)
                    })
                }
            }
            .store(in: &cancellable)
    }

    func setupUserDefaultsShowPublisher(mapState: MapState) {
        userDefaultsShowPublisher?
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.show = !show
                NSLog("Show \(self?.dataSourceKey ?? ""): \(!show)")
                self?.refreshOverlay(mapState: mapState)
            }
            .store(in: &cancellable)
    }

    func setupOrderPublisher(mapState: MapState) {
        orderPublisher?
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")

                self?.refreshOverlay(mapState: mapState)
            }
            .store(in: &cancellable)
    }

    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]? {
        let viewWidth = await mapView.frame.size.width
        let viewHeight = await mapView.frame.size.height

        let latitudePerPixel = await mapView.region.span.latitudeDelta / viewHeight
        let longitudePerPixel = await mapView.region.span.longitudeDelta / viewWidth

        let queryLocationMinLongitude = location.longitude
        let queryLocationMaxLongitude = location.longitude
        let queryLocationMinLatitude = location.latitude
        let queryLocationMaxLatitude = location.latitude

        return await repository?.getTileableItems(
            minLatitude: queryLocationMinLatitude,
            maxLatitude: queryLocationMaxLatitude,
            minLongitude: queryLocationMinLongitude,
            maxLongitude: queryLocationMaxLongitude,
            latitudePerPixel: latitudePerPixel,
            longitudePerPixel: longitudePerPixel,
            zoom: mapView.zoomLevel,
            precise: true
        )
    }

    func itemKeys(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [String: [String]] {
        if await mapView.zoomLevel < minZoom {
            return [:]
        }
        guard show == true else {
            return [:]
        }

        let viewWidth = await mapView.frame.size.width
        let viewHeight = await mapView.frame.size.height

        let latitudePerPixel = await mapView.region.span.latitudeDelta / viewHeight
        let longitudePerPixel = await mapView.region.span.longitudeDelta / viewWidth

        let queryLocationMinLongitude = location.longitude
        let queryLocationMaxLongitude = location.longitude
        let queryLocationMinLatitude = location.latitude
        let queryLocationMaxLatitude = location.latitude

        return [
            dataSourceKey: await repository?.getItemKeys(
                minLatitude: queryLocationMinLatitude,
                maxLatitude: queryLocationMaxLatitude,
                minLongitude: queryLocationMinLongitude,
                maxLongitude: queryLocationMaxLongitude,
                latitudePerPixel: latitudePerPixel,
                longitudePerPixel: longitudePerPixel,
                zoom: mapView.zoomLevel,
                precise: true
            ) ?? []
        ]
    }

    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        standardRenderer(overlay: overlay)
    }

    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        return nil
    }

}
