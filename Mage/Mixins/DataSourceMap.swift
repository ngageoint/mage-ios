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
import DataSourceDefinition

class DataSourceMap: MapMixin {
    var REFRESH_KEY: String {
        "\(dataSource.key)\(uuid.uuidString)MapDateUpdated"
    }
    var uuid: UUID = UUID()
    var cancellable = Set<AnyCancellable>()
    
    var viewModel: DataSourceMapViewModel?

    var scheme: MDCContainerScheming?
    weak var mapState: MapState?
    weak var mapView: MKMapView?

    var dataSource: any DataSourceDefinition
    
    var currentAnnotationViews: [String: MKAnnotationView] = [:]
    var currentFeatureOverlays: [String: MKOverlay] = [:]

    init(
        dataSource: any DataSourceDefinition
    ) {
        self.dataSource = dataSource
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

        viewModel?.$annotations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] annotations in
                Task { [weak self] in
                    await self?.handleFeatureChanges(annotations: annotations)
                }
            }
            .store(in: &cancellable)
        
        viewModel?.$featureOverlays
            .receive(on: DispatchQueue.main)
            .sink { [weak self] featureOverlays in
                Task { [weak self] in
                    await self?.handleFeatureOverlayChanges(featureOverlays: featureOverlays)
                }
            }
            .store(in: &cancellable)
    }
    
    func currentTileOverlays() -> [DataSourceTileOverlay] {
        mapView?.overlays.compactMap({ overlay in
            overlay as? DataSourceTileOverlay
        }).filter({ overlay in
            overlay.key == uuid.uuidString
        }) ?? []
    }
    
    @MainActor
    func redrawFeatures() {
        let existingAnnotations = mapView?.annotations.compactMap({ annotation in
            (annotation as? DataSourceAnnotation)
        }).filter({ annotation in
            annotation.dataSource.key == self.dataSource.key
        }) ?? []
        mapView?.removeAnnotations(existingAnnotations)
        mapView?.addAnnotations(viewModel?.annotations ?? [])
    }
    
    func updateMixin(mapView: MKMapView, mapState: MapState) { }

    @objc func clearTimer(timer: Timer) {
        clearPreviousTiles(previousTiles: timer.userInfo as? [MKTileOverlay])
    }
    
    func clearPreviousTiles(previousTiles: [MKTileOverlay]?) {
        for overlay in previousTiles ?? [] {
            mapView?.removeOverlay(overlay)
        }
    }

    var valueAnimator: ValueAnimator?

    func fadeTiles(fade: Bool) async {
        return await withCheckedContinuation { continuation in
            if fade {
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

    @discardableResult
    @MainActor
    func handleFeatureChanges(annotations: [DataSourceAnnotation]) -> Bool {
        guard let mapView = mapView else { return false }
        let annotationDictionary = [String : DataSourceAnnotation]()
        
        // Create a dictionary lookup so we don't fall into a O(n^2) complexity issue on inserts/removes
        let existingAnnotations = mapView.annotations.compactMap { annotation in
            (annotation as? DataSourceAnnotation)
        }
        .filter { annotation in
            annotation.dataSource.key == self.dataSource.key
        }
        .reduce(into: annotationDictionary) { dictionary, annotation in
            dictionary[annotation.id] = annotation
        }
        
        var inserts: [DataSourceAnnotation] = []
        var removals: [DataSourceAnnotation] = []

        // Update or prepare to insert annotations
        for annotation in annotations {
            if let existing = existingAnnotations[annotation.id] {
                existing.coordinate = annotation.coordinate
            } else {
                inserts.append(annotation)
            }
        }
        
        // Prepare to remove observations
        let newIds = Set(annotations.map { $0.id })
        for (id, existingAnnotation) in existingAnnotations {
            if !newIds.contains(id) {
                removals.append(existingAnnotation)
                currentAnnotationViews.removeValue(forKey: id) // FIXME: Refactor/remove currentAnnotationViews. We should not maintain a collection that could get out of date from MapKit
            }
        }
                
        mapView.addAnnotations(inserts)
        mapView.removeAnnotations(removals)
        
        return !inserts.isEmpty || !removals.isEmpty
    }
    
    /// Compares incoming overlays to the map's current overlays using a stable key (itemKey, falling back to id).
    /// It computes inserts and removals by key, then adds/removes only the necessary overlays to avoid flicker during small pans.
    @discardableResult
    @MainActor
    func handleFeatureOverlayChanges(featureOverlays: [MKOverlay]) -> Bool {
        guard let mapView = mapView else { return false }

        let featureOverlayChanges: [DataSourceIdentifiable] = featureOverlays
            .compactMap { $0 as? DataSourceIdentifiable }
            .filter { $0.dataSource.key == self.dataSource.key }

        let existingOverlays: [DataSourceIdentifiable] = mapView.overlays
            .compactMap { $0 as? DataSourceIdentifiable }
            .filter { $0.dataSource.key == self.dataSource.key }

        // Sort both sides by the stable key to make diffs predictable
        let sortedNew = featureOverlayChanges.sorted { $0.key() < $1.key() }
        let sortedExisting = existingOverlays.sorted { $0.key() < $1.key() }

        // Compute key sets
        let newKeys = Set(sortedNew.map { $0.key() })
        let existingKeys = Set(sortedExisting.map { $0.key() })

        // Determine inserts and removals by key
        let keysToInsert = newKeys.subtracting(existingKeys)
        let keysToRemove = existingKeys.subtracting(newKeys)

        // Build overlay arrays to add/remove
        var inserts: [MKOverlay] = []
        var removals: [MKOverlay] = []

        // Inserts: take the overlay instances from the new list
        for newOverlay in sortedNew where keysToInsert.contains(newOverlay.key()) {
            if let overlay = newOverlay as? MKOverlay {
                inserts.append(overlay)
            }
        }

        // Removals: find overlays on the map with matching keys
        for existingOverlay in sortedExisting where keysToRemove.contains(existingOverlay.key()) {
            if let overlay = existingOverlay as? MKOverlay {
                removals.append(overlay)
                currentFeatureOverlays.removeValue(forKey: existingOverlay.key())
            }
        }

        mapView.addOverlays(inserts)
        mapView.removeOverlays(removals)
        return !inserts.isEmpty || !removals.isEmpty
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {
        mapView.removeOverlays(viewModel?.featureOverlays ?? [])
        mapView.removeAnnotations(viewModel?.annotations ?? [])
        for cancellable in cancellable {
            cancellable.cancel()
        }
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

