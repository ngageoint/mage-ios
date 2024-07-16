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
    
    @Injected(\.mapStateRepository)
    var mapStateRepository: MapStateRepository
    
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
    
    let requerySubject = PassthroughSubject<Void, Never>()
    
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
        
        requerySubject
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { index in
                Task {
                    await self.queryFeatures()
                }
            }
            .store(in: &cancellable)
        
        mapStateRepository.$zoom.sink { zoom in
            self.requerySubject.send(())
        }.store(in: &cancellable)
        
        mapStateRepository.$region.sink { region in
            self.requerySubject.send(())
        }.store(in: &cancellable)
        
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
        requerySubject.send(())
        createTileOverlays()
    }
    
    private func queryFeatures() async {
        guard let zoom = mapStateRepository.zoom, let region = mapStateRepository.region else { return }
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
        guard let zoom = mapStateRepository.zoom else { return [:] }
        if zoom < minZoom {
            return [:]
        }
        if zoom > maximumTileZoom {
            return [:]
        }
        guard show == true else {
            return [:]
        }

        let viewWidth = await mapView.frame.size.width
        let viewHeight = await mapView.frame.size.height

        let latitudePerPixel = await mapView.region.span.latitudeDelta / viewHeight
        let longitudePerPixel = await mapView.region.span.longitudeDelta / viewWidth
        
        let screenPercentage = 0.03
        let distanceTolerance = await mapView.visibleMapRect.size.width * Double(screenPercentage)

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
                zoom: zoom,
                precise: true,
                distanceTolerance: distanceTolerance
            ) ?? []
        ]
    }
    
    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [any DataSourceImage]? {
        guard let zoom = mapStateRepository.zoom else { return nil }
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
            zoom: zoom,
            precise: true
        )
    }
}
