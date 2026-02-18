//
//  ObservationMap.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Combine
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
    
    @Injected(\.observationImageRepository)
    var imageRepository: ObservationImageRepository

    init() {
        super.init(
            dataSource: DataSources.observation
        )
        viewModel = DataSourceMapViewModel(
            dataSource: dataSource,
            key: uuid.uuidString,
            repository: repository,
            mapFeatureRepository: mapFeatureRepository
        )
       
        let defaults = UserDefaults.standard
        Publishers.MergeMany([ // Group all the settings into one publisher so we don't trigger on every property change
            defaults.settingsChangePublisher(\.hideObservations),
            defaults.settingsChangePublisher(\.observationTimeFilterKey),
            defaults.settingsChangePublisher(\.observationTimeFilterUnitKey),
            defaults.settingsChangePublisher(\.observationTimeFilterNumberKey),
            defaults.settingsChangePublisher(\.importantFilterKey),
            defaults.settingsChangePublisher(\.favoritesFilterKey)
        ])
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.refreshAll()
        }
        .store(in: &cancellable)
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
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID)

        if let annotationView = annotationView {
            annotationView.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: OBSERVATION_MAP_ITEM_ANNOTATION_VIEW_REUSE_ID)
            annotationView?.isEnabled = true
        }

        let image = imageRepository.imageAtPath(imagePath: mapItemAnnotation.mapItem.iconPath)
        if let annotationView = annotationView {
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
        currentAnnotationViews[mapItemAnnotation.id] = annotationView // FIXME: Refactor/remove currentAnnotationViews. We should not maintain a collection that could get out of date from MapKit
        return annotationView
    }
}
