//
//  ObservationMap.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceTileOverlay
import MapFramework

class ObservationsMap: DataSourceMap {
    let OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID = "OBSERVATION_ICON"
    var enlargedAnnotation: DataSourceAnnotation?
    var focusedObservationTileOverlay: DataSourceTileOverlay?

    init(
        repository: TileRepository? = nil,
        mapFeatureRepository: MapFeatureRepository? = nil
    ) {
        super.init(
            dataSource: DataSources.observation,
            repository: repository,
            mapFeatureRepository: mapFeatureRepository
        )
        viewModel.userDefaultsShowPublisher = UserDefaults.standard.publisher(for: \.hideObservations)

        UserDefaults.standard.publisher(for: \.observationTimeFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSource.key ?? ""): \(order)")
                Task { [self] in
                    await repository?.clearCache()
                    self?.refresh()
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterUnitKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSource.key ?? ""): \(order)")
                Task { [self] in
                    await repository?.clearCache()
                    self?.refresh()
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterNumberKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSource.key ?? ""): \(order)")
                Task { [self] in
                    await repository?.clearCache()
                    self?.refresh()
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.importantFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSource.key ?? ""): \(order)")
                Task { [self] in
                    await repository?.clearCache()
                    self?.refresh()
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.favoritesFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                Task { [self] in
                    await repository?.clearCache()
                    self?.refresh()
                }
            }
            .store(in: &cancellable)

        NotificationCenter.default.publisher(for: .MAGEFormFetched)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                if let event: Event = notification.object as? Event {
                    if event.remoteId == Server.currentEventId() {
                        Task { [self] in
                            await repository?.clearCache()
                            self.refresh()
                        }
                    }
                }
            }
            .store(in: &cancellable)

        NotificationCenter.default.publisher(for: .MapAnnotationFocused)
            .receive(on: DispatchQueue.main)
            .map {$0.object as? MapAnnotationFocusedNotification}
            .sink { output in
                self.focusAnnotation(mapItem: output?.item as? ObservationMapItem)
            }
            .store(in: &cancellable)
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

    func focusAnnotation(mapItem: ObservationMapItem?) {
        Task {
            if let mapItem = mapItem {
                addFocusedOverlay(mapItem: mapItem)
                await fadeTiles()
            } else {
                await fadeTiles()
                removeFocusedOverlay()
            }
        }
    }

    func addFocusedOverlay(mapItem: ObservationMapItem) {
        DispatchQueue.main.async { [self] in
            if let observationUrl = mapItem.observationId,
               let observationsTileRepository = viewModel.repository as? ObservationsTileRepository
            {
                let observationTileRepo = ObservationTileRepository(
                    observationUrl: observationUrl,
                    localDataSource: observationsTileRepository.localDataSource
                )
                if let focusedObservationTileOverlay = focusedObservationTileOverlay {
                    mapView?.removeOverlay(focusedObservationTileOverlay)
                    self.focusedObservationTileOverlay = nil
                }
                focusedObservationTileOverlay = DataSourceTileOverlay(
                    tileRepository: observationTileRepo,
                    key: "\(DataSources.observation.key)_\(observationUrl)"
                )
                focusedObservationTileOverlay?.allowFade = false
                mapView?.addOverlay(focusedObservationTileOverlay!, level: .aboveLabels)
            }
        }
    }

    func removeFocusedOverlay() {
        DispatchQueue.main.async { [self] in
            if let focusedObservationTileOverlay = focusedObservationTileOverlay {
                mapView?.removeOverlay(focusedObservationTileOverlay)
                self.focusedObservationTileOverlay = nil
            }
        }
    }

    override func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard let mapItemAnnotation = annotation as? ObservationMapItemAnnotation else {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID)

        if let annotationView = annotationView {
            annotationView.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID)
            annotationView?.isEnabled = true
        }

        if let iconPath = mapItemAnnotation.mapItem.iconPath, let annotationView = annotationView {
            let image = ObservationImage.imageAtPath(imagePath: iconPath)
            annotationView.image = image

            var size = CGSize(width: 40, height: 40)
            let max = max(image.size.height, image.size.width)
            size.width *= ((image.size.width) / max)
            size.height *= ((image.size.height) / max)
            annotationView.frame.size = size
            annotationView.canShowCallout = false
            annotationView.isEnabled = false
            annotationView.accessibilityLabel = "Enlarged"
            annotationView.zPriority = .max
            annotationView.selectedZPriority = .max


            annotationView.centerOffset = CGPoint(x: 0, y: -(image.size.height/2.0))
//            annotationView.accessibilityLabel = "Observation"
//            annotationView.accessibilityValue = "Observation"
            annotationView.displayPriority = .required
//            annotationView.canShowCallout = true
        }
        mapItemAnnotation.annotationView = annotationView
        return annotationView
    }
}
