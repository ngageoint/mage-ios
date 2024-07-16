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
    var mapState: MapState?
    var mapView: MKMapView?

    var dataSource: any DataSourceDefinition
    
    var currentAnnotationViews: [String: MKAnnotationView] = [:]
    var currentFeatureOverlays: [String: MKOverlay] = [:]
//    var region: MKCoordinateRegion?

    init(
        dataSource: any DataSourceDefinition
//        repository: TileRepository? = nil,
//        mapFeatureRepository: MapFeatureRepository? = nil
    ) {
        self.dataSource = dataSource
//        viewModel = DataSourceMapViewModel(
//            dataSource: dataSource,
//            key: uuid.uuidString,
//            repository: repository,
//            mapFeatureRepository: mapFeatureRepository
//        )
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

        updateMixin(mapView: mapView, mapState: mapState)

        viewModel?.$annotations.sink { annotations in
            Task {
                await self.handleFeatureChanges(annotations: annotations)
            }
        }
        .store(in: &cancellable)
        
        viewModel?.$featureOverlays.sink { featureOverlays in
            Task {
                await self.handleFeatureOverlayChanges(featureOverlays: featureOverlays)
            }
        }
        .store(in: &cancellable)
        
        viewModel?.$tileOverlays.sink { tileOverlays in
            self.updateTileOverlays(tileOverlays: tileOverlays)
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
    
    private func updateTileOverlays(tileOverlays: [DataSourceTileOverlay]) {
        guard let mapView = mapView, let viewModel = viewModel else {
            return
        }
        // save these so we can remove them later
        let previousTiles = currentTileOverlays()
        if !viewModel.show && !viewModel.repositoryAlwaysShow {
            clearPreviousTiles(previousTiles: previousTiles)
            return
        }
        mapView.addOverlays(tileOverlays, level: .aboveLabels)
        // give the map a chance to draw the new data before we take the old one off the map to prevent flashing
        DispatchQueue.main.async {
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.clearTimer), userInfo: previousTiles, repeats: false)
        }
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
        let existingAnnotations = mapView.annotations.compactMap({ annotation in
            (annotation as? DataSourceAnnotation)
        }).filter({ annotation in
            annotation.dataSource.key == self.dataSource.key
        }).sorted(by: { first, second in
            first.id < second.id
        })
        
        // this is how to create the annotations array from the previous annotations array
        let differences = annotations.difference(from: existingAnnotations) { annotation1, annotation2 in
            annotation1.id == annotation2.id
        }
        
        var inserts: [DataSourceAnnotation] = []
        var removals: [DataSourceAnnotation] = []
        for change in differences {
            switch change {
            case .insert(let offset, let element, _):
                let existing = mapView.annotations.first(where: { mapAnnotation in
                    guard let mapAnnotation = mapAnnotation as? DataSourceAnnotation else {
                        return false
                    }
                    return mapAnnotation.id == element.id
                }) as? DataSourceAnnotation
                if let existing = existing {
                    existing.coordinate = element.coordinate
                } else {
//                    currentAnnotations.insert(element)
                    inserts.append(element)
                }
                print("insert offset \(offset) for element \(element)")
            case .remove(let offset, let element, _):
                let existing = mapView.annotations.compactMap({ mapAnnotation in
                    mapAnnotation as? DataSourceAnnotation
                }).filter({ mapAnnotation in
                    if mapAnnotation.id == element.id {
                        currentAnnotationViews.removeValue(forKey: mapAnnotation.id)
                        return true
                    }
                    return false
                })
                removals.append(contentsOf: existing)
                print("remove offset \(offset) for element \(element)")
            }
        }
        NSLog("Inserting \(inserts.count), removing: \(removals.count)")
        
        mapView.addAnnotations(inserts)
        mapView.removeAnnotations(removals)
        NSLog("Annotation count: \(mapView.annotations.count)")
        
        return !inserts.isEmpty || !removals.isEmpty
    }
    
    @discardableResult
    @MainActor
    func handleFeatureOverlayChanges(featureOverlays: [MKOverlay]) -> Bool {
        guard let mapView = mapView else { return false }
        let existingFeatureOverlays = mapView.overlays.compactMap({ overlay in
            (overlay as? DataSourceIdentifiable)
        }).filter({ featureOverlay in
            featureOverlay.dataSource.key == self.dataSource.key
        }).sorted(by: { first, second in
            first.id < second.id
        })
        
        // this is how to create the annotations array from the previous annotations array
        let differences = featureOverlays.compactMap({ overlay in
            (overlay as? DataSourceIdentifiable)
        }).difference(from: existingFeatureOverlays) { overlay1, overlay2 in
            overlay1.id == overlay2.id
        }
        
        var inserts: [MKOverlay] = []
        var removals: [MKOverlay] = []
        for change in differences {
            switch change {
            case .insert(let offset, let element, _):
                let existing = mapView.overlays.first(where: { mapOverlay in
                    guard let mapOverlay = mapOverlay as? DataSourceIdentifiable else {
                        return false
                    }
                    return mapOverlay.id == element.id
                })
                if existing == nil, let element = element as? MKOverlay {
                    inserts.append(element)
                }
                print("insert offset \(offset) for element \(element)")
            case .remove(let offset, let element, _):
                let existing = mapView.overlays.compactMap({ mapOverlay in
                    mapOverlay as? DataSourceIdentifiable
                }).filter({ mapOverlay in
                    if mapOverlay.id == element.id {
                        currentFeatureOverlays.removeValue(forKey: mapOverlay.id)
                        return true
                    }
                    return false
                }).compactMap { identifiable in
                    identifiable as? MKOverlay
                }
                removals.append(contentsOf: existing)
                print("remove offset \(offset) for element \(element)")
            }
        }
        NSLog("Inserting \(inserts.count), removing: \(removals.count)")
        
        mapView.addOverlays(inserts)
        mapView.removeOverlays(removals)
        NSLog("Annotation count: \(mapView.overlays.count)")
        return !inserts.isEmpty || !removals.isEmpty
    }


    func removeMixin(mapView: MKMapView, mapState: MapState) {
        mapView.removeOverlays(viewModel?.featureOverlays ?? [])
        mapView.removeAnnotations(viewModel?.annotations ?? [])
        mapView.removeOverlays(viewModel?.tileOverlays ?? [])
    }

    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]? {
        return nil
//        return await viewModel.items(at: location, mapView: mapView, touchPoint: touchPoint)
    }

    func itemKeys(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [String: [String]] {
        return await viewModel?.itemKeys(at: location, mapView: mapView, touchPoint: touchPoint) ?? [:]
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
