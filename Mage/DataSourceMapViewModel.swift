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
    var mapFeatureRepository: MapFeatureRepository?
    var minZoom = 2
    
    var show = false
    var repositoryAlwaysShow: Bool {
        repository?.alwaysShow ?? mapFeatureRepository?.alwaysShow ?? false
    }
    
    var cancellable = Set<AnyCancellable>()
    var userDefaultsShowPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Bool>?
    
    var refreshSubject: PassthroughSubject<Date, Never>? = PassthroughSubject<Date, Never>()
    var refreshPublisher: AnyPublisher<Date, Never>?  {
        refreshSubject?.eraseToAnyPublisher()
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
                self.refreshSubject?.send(date)
            }
            .store(in: &cancellable)
        
        self.setupUserDefaultsShowPublisher()
    }
    
    func setupUserDefaultsShowPublisher() {
        userDefaultsShowPublisher?
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.show = !show
                NSLog("Show \(self?.dataSource.key ?? ""): \(!show)")
                self?.refreshSubject?.send(Date())
            }
            .store(in: &cancellable)
    }
    
    func queryFeatures(zoom: Int, region: MKCoordinateRegion) async {
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
    func createTileOverlays() -> [MKTileOverlay] {
        guard let repository = repository else {
            return []
        }
        let newOverlay = DataSourceTileOverlay(tileRepository: repository, key: key)
        newOverlay.minimumZ = minZoom
        newOverlay.maximumZ = 7
        
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
                precise: true
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
