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
    
    @Injected(\.observationsMapFeatureRepository)
    var mapFeatureRepository: ObservationsMapFeatureRepository
    
    @Injected(\.observationsTileRepository)
    var repository: ObservationsTileRepository
    
    @Injected(\.observationIconRepository)
    var iconRepository: ObservationIconRepository
    
    var imageRepository: ObservationImageRepository

    init(imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl.shared) {
        self.imageRepository = imageRepository
        super.init(
            dataSource: DataSources.observation
        )
        viewModel = DataSourceMapViewModel(
            dataSource: dataSource,
            key: uuid.uuidString,
            repository: repository,
            mapFeatureRepository: mapFeatureRepository
        )
        viewModel?.userDefaultsShowPublisher = UserDefaults.standard.publisher(for: \.hideObservations)

        UserDefaults.standard.publisher(for: \.observationTimeFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSource.key ?? ""): \(order)")
                Task { [self] in
                    await self?.repository.clearCache()
                    self?.viewModel?.refresh()
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterUnitKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSource.key ?? ""): \(order)")
                Task { [self] in
                    await self?.repository.clearCache()
                    self?.viewModel?.refresh()
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterNumberKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSource.key ?? ""): \(order)")
                Task { [self] in
                    await self?.repository.clearCache()
                    self?.viewModel?.refresh()
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.importantFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(self?.dataSource.key ?? ""): \(order)")
                Task { [self] in
                    await self?.repository.clearCache()
                    self?.viewModel?.refresh()
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.favoritesFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                Task { [self] in
                    await self?.repository.clearCache()
                    self?.viewModel?.refresh()
                }
            }
            .store(in: &cancellable)

        NotificationCenter.default.publisher(for: .MAGEFormFetched)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let event: EventModel = notification.object as? EventModel {
                    if let eventId = event.remoteId, eventId == Server.currentEventId() {
                        Task { [self] in
                            self?.iconRepository.resetEventIconSize(eventId: Int(truncating: eventId))
                            await self?.repository.clearCache()
                            await self?.redrawFeatures()
                            self?.viewModel?.refresh()
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

    func focusAnnotation(mapItem: ObservationMapItem?) {
        if !self.currentAnnotationViews.isEmpty {
            if let mapItem = mapItem {
                for annotationView in self.currentAnnotationViews.values {
                    if let annotation = annotationView.annotation as? DataSourceAnnotation {
                        if annotation.id != mapItem.observationLocationId?.absoluteString {
                            annotationView.alpha = 0.3
                            annotationView.zPriority = .defaultUnselected
                        } else {
                            annotationView.alpha = 1.0
                            annotationView.zPriority = .defaultSelected
                        }
                    }
                }
            } else {
                for annotationView in self.currentAnnotationViews.values {
                    annotationView.alpha = 1.0
                    annotationView.zPriority = .defaultSelected
                }
            }
        } else {
            Task {
                if let mapItem = mapItem {
                    addFocusedOverlay(mapItem: mapItem)
                    await fadeTiles(fade: true)
                } else {
                    await fadeTiles(fade: false)
                    removeFocusedOverlay()
                }
            }
        }
    }

    func addFocusedOverlay(mapItem: ObservationMapItem) {
        DispatchQueue.main.async { [self] in
            if let observationLocationUrl = mapItem.observationLocationId {
                let observationTileRepo = ObservationLocationTileRepository(
                    observationLocationUrl: observationLocationUrl
                )
                if let focusedObservationTileOverlay = focusedObservationTileOverlay {
                    mapView?.removeOverlay(focusedObservationTileOverlay)
                    self.focusedObservationTileOverlay = nil
                }
                focusedObservationTileOverlay = DataSourceTileOverlay(
                    tileRepository: observationTileRepo,
                    key: "\(DataSources.observation.key)_\(observationLocationUrl)"
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

        var annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID
        )

        if let view = annotationView {
            view.annotation = annotation
        } else {
            annotationView = MKAnnotationView(
                annotation: annotation,
                reuseIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID
            )
            annotationView?.isEnabled = true
        }

        // --- Default placeholder immediately ---
        let placeholder = UIImage(named: "defaultMarker")!
        annotationView?.image = placeholder
        annotationView?.frame.size = CGSize(width: 40, height: 40)
        annotationView?.centerOffset = CGPoint(x: 0, y: -(placeholder.size.height/2.0))
        annotationView?.displayPriority = .required

        // --- Kick off async image load ---
        if let iconPath = mapItemAnnotation.mapItem.iconPath,
           let annotationView = annotationView {

            Task {
                let image = await imageRepository.imageAtPath(imagePath: iconPath)

                await MainActor.run {
                    // double-check the annotationView is still in use
                    guard currentAnnotationViews[mapItemAnnotation.id] === annotationView else { return }

                    annotationView.image = image

                    // Recalculate size based on real image
                    var size = CGSize(width: 40, height: 40)
                    let max = max(image.size.height, image.size.width)
                    if max > 0 {
                        size.width *= (image.size.width / max)
                        size.height *= (image.size.height / max)
                    }
                    annotationView.frame.size = size

                    annotationView.canShowCallout = false
                    annotationView.isEnabled = false
                    annotationView.accessibilityLabel = "Enlarged"
                    annotationView.zPriority = .max
                    annotationView.selectedZPriority = .max
                    annotationView.centerOffset = CGPoint(x: 0, y: -(image.size.height / 2.0))
                }
            }
        }

        // keep references
        mapItemAnnotation.annotationView = annotationView
        if let annotationView = annotationView {
            currentAnnotationViews[mapItemAnnotation.id] = annotationView
        }

        return annotationView
    }

}
