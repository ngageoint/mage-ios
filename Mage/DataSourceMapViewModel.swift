//
//  DataSourceMapViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 5/22/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapFramework
import DataSourceTileOverlay
import DataSourceDefinition
import Combine

class DataSourceMapViewModel {
    var dataSource: any DataSourceDefinition
    var key: String
    var repository: TileRepository?
    var mapFeatureRepository: MapFeatureRepository? {
        didSet {
            refresh()
        }
    }
    var minZoom = 2
    var maximumTileZoom = 6
    
    var zoom: Int?
    var region: MKCoordinateRegion?
    
    var show = false
    var repositoryAlwaysShow: Bool {
        repository?.alwaysShow ?? mapFeatureRepository?.alwaysShow ?? false
    }
    
    var cancellable = Set<AnyCancellable>()
    var userDefaultsShowPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Bool>? {
        didSet {
            setupUserDefaultsShowPublisher()
        }
    }
    
    @Published var annotations: [DataSourceAnnotation] = []
    @Published var featureOverlays: [MKOverlay] = []
    @Published var tileOverlays: [DataSourceTileOverlay] = []
    
    init(
        dataSource: any DataSourceDefinition,
        key: String,
        repository: TileRepository? = nil,
        mapFeatureRepository: MapFeatureRepository? = nil
    ) {
        self.dataSource = dataSource
        self.key = key
        self.repository = repository
        self.mapFeatureRepository = mapFeatureRepository
        
        repository?.refreshPublisher?
            .sink { date in
                self.refresh()
            }
            .store(in: &cancellable)
        
        createTileOverlays()
    }
    
    func setupUserDefaultsShowPublisher() {
        userDefaultsShowPublisher?
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.show = !show
                NSLog("Show \(self?.dataSource.key ?? ""): \(!show)")
                self?.refresh()
            }
            .store(in: &cancellable)
    }
    
    // this requeries for all features and recreates all tile overlays
    func refresh() {
        Task {
            await queryFeatures()
            createTileOverlays()
        }
    }
    
    // This sets the zoom and region to be queried and kicks off the query
    func setZoomAndRegion(zoom: Int, region: MKCoordinateRegion) {
        self.zoom = zoom
        self.region = region
        Task {
            await queryFeatures()
        }
    }
    
    private func queryFeatures() async {
        guard let zoom = zoom, let region = region else { return }
        let features = await mapFeatureRepository?.getAnnotationsAndOverlays(
            zoom: zoom,
            region: region.padded(percentage: 0.05)
        )
        annotations = (features?.annotations ?? []).sorted(by: { first, second in
            first.id < second.id
        })
        featureOverlays = features?.overlays ?? []
    }
    
    @discardableResult
    private func createTileOverlays() -> [MKTileOverlay] {
        guard let repository = repository else {
            return []
        }
        let newOverlay = DataSourceTileOverlay(tileRepository: repository, key: key)
        newOverlay.minimumZ = minZoom
        newOverlay.maximumZ = maximumTileZoom
        
        tileOverlays = [newOverlay]
        return tileOverlays
    }
    
    func itemKeys(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [String: [String]] {
        if await mapView.zoomLevel < minZoom {
            return [:]
        }
        if await mapView.zoomLevel > maximumTileZoom {
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
            dataSource.key: await repository?.getItemKeys(
                minLatitude: queryLocationMinLatitude,
                maxLatitude: queryLocationMaxLatitude,
                minLongitude: queryLocationMinLongitude,
                maxLongitude: queryLocationMaxLongitude,
                latitudePerPixel: latitudePerPixel,
                longitudePerPixel: longitudePerPixel,
                zoom: mapView.zoomLevel,
                precise: false
            ) ?? []
        ]
    }
    
    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [any DataSourceImage]? {
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
}