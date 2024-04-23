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
import MapFramework

class DataSourceMap: MapMixin {
    var REFRESH_KEY: String {
        "\(dataSourceKey)MapDateUpdated"
    }
    var uuid: UUID = UUID()
    var cancellable = Set<AnyCancellable>()
    var minZoom = 2

    var repository: TileRepository?
    var mapFeatureRepository: MapFeatureRepository?
    var scheme: MDCContainerScheming?
    var mapState: MapState?
    var mapView: MKMapView?
    var lastChange: Date?
    var overlays: [MKOverlay] = []
    var renderers: [MKOverlayRenderer] = []
    var annotations: [MKAnnotation] = []

    var previousOverlays: [MKOverlay] = []
    var previousAnnotations: [MKAnnotation] = []

    var focusNotificationName: Notification.Name?

    var userDefaultsShowPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Bool>?
    var orderPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Int>?

    var show = false
    var repositoryAlwaysShow: Bool {
        repository?.alwaysShow ?? mapFeatureRepository?.alwaysShow ?? false
    }

    var dataSourceKey: String {
        repository?.dataSource.key ?? mapFeatureRepository?.dataSource.key ?? ""
    }

    init(repository: TileRepository? = nil, mapFeatureRepository: MapFeatureRepository? = nil) {
        self.repository = repository
        self.mapFeatureRepository = mapFeatureRepository
    }

    func cleanupMixin() {
        cancellable.removeAll()
    }

    func applyTheme(scheme: MDCContainerScheming?) {
        self.scheme = scheme
    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        self.mapView = mapView
        self.mapState = mapState

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

        repository?.refreshPublisher?
            .sink { date in
                if let mapState = self.mapState {
                    self.refreshMap(mapState: mapState)
                }
            }
            .store(in: &cancellable)
    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {
        if lastChange == nil
            || lastChange != mapState.mixinStates[self.REFRESH_KEY] as? Date {
            lastChange = mapState.mixinStates[self.REFRESH_KEY] as? Date ?? Date()

            if mapState.mixinStates[self.REFRESH_KEY] as? Date == nil {
                DispatchQueue.main.async {
                    mapState.mixinStates[self.REFRESH_KEY] = self.lastChange
                }
            }

            // if there are still previous overlays or annotations, just clear them now
            clearPrevious()
            previousOverlays = overlays
            previousAnnotations = annotations

            overlays = []
            annotations = []

            if !show && !repositoryAlwaysShow {
                return
            }
            Task {
                overlays = getOverlays()
                let features = await mapFeatureRepository?.getAnnotationsAndOverlays()
                if let features = features {
                    annotations.append(contentsOf: features.annotations)
                    overlays.append(contentsOf: features.overlays)
                }
                await addFeatures(features: AnnotationsAndOverlays(annotations: annotations, overlays: overlays), mapView: mapView)
            }

            // give the map a chance to draw the new data before we take the old one off the map to prevent flashing
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(clearPrevious), userInfo: nil, repeats: false)
        }
    }

    @objc func clearPrevious() {
        for overlay in previousOverlays {
            mapView?.removeOverlay(overlay)
        }
        mapView?.removeAnnotations(previousAnnotations)
        previousOverlays = []
        previousAnnotations = []
    }

    var valueAnimator: ValueAnimator?

    func fadeTiles() async {
        return await withCheckedContinuation { continuation in
            if let alpha = tileRenderer?.alpha {
                if alpha == 1.0 {
                    valueAnimator = ValueAnimator(
                        duration: 0.5,
                        startValue: 1.0,
                        endValue: 0.3,
                        callback: { value in
                            self.tileRenderer?.alpha = value
                        },
                        finishCallback: { value in
                            self.tileRenderer?.alpha = value
                            continuation.resume()
                        })
                } else {
                    valueAnimator = ValueAnimator(
                        duration: 0.5,
                        startValue: 0.3,
                        endValue: 1.0,
                        callback: { value in
                            self.tileRenderer?.alpha = value
                        },
                        finishCallback: { value in
                            self.tileRenderer?.alpha = value
                            continuation.resume()
                        })
                }
                valueAnimator?.start()
            }
        }
    }

    func getOverlays() -> [MKOverlay] {
        guard let repository = repository else {
            return []
        }
        let newOverlay = DataSourceTileOverlay(tileRepository: repository, key: dataSourceKey)
        newOverlay.minimumZ = self.minZoom
        return [newOverlay]
    }

    @MainActor
    func addFeatures(features: AnnotationsAndOverlays, mapView: MKMapView) {
        mapView.addAnnotations(features.annotations)
        mapView.showAnnotations(features.annotations, animated: true)
        mapView.addOverlays(features.overlays, level: .aboveLabels)
    }

    func removeMixin(mapView: MKMapView, mapState: MapState) {
        mapView.removeOverlays(overlays)
        mapView.removeAnnotations(annotations)
    }

    func refreshMap(mapState: MapState) {
        DispatchQueue.main.async {
            self.mapState?.mixinStates[
                self.REFRESH_KEY
            ] = Date()
        }
    }

    func setupUserDefaultsShowPublisher(mapState: MapState) {
        userDefaultsShowPublisher?
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.show = !show
                NSLog("Show \(self?.dataSourceKey ?? ""): \(!show)")
                self?.refreshMap(mapState: mapState)
            }
            .store(in: &cancellable)
    }

    func setupOrderPublisher(mapState: MapState) {
        orderPublisher?
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSourceKey ?? ""): \(order)")

                self?.refreshMap(mapState: mapState)
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

    var tileRenderer: MKOverlayRenderer?

    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let overlay = overlay as? DataSourceTileOverlay {
            if overlay.allowFade {
                let alpha = self.tileRenderer?.alpha ?? 1.0
                self.tileRenderer = standardRenderer(overlay: overlay)
                self.tileRenderer?.alpha = alpha
                return self.tileRenderer
            } else {
                return standardRenderer(overlay: overlay)
            }
        }
        return nil
    }

    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        return nil
    }

}
