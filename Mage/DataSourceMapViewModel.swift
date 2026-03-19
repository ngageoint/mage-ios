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
    
    var repositoryAlwaysShow: Bool {
        repository?.alwaysShow ?? mapFeatureRepository?.alwaysShow ?? false
    }
    
    var cancellable = Set<AnyCancellable>()
    
    @Published var annotations: [DataSourceAnnotation] = []
    @Published var featureOverlays: [MKOverlay] = []
    
    private var lastAnnotationKeys: Set<String> = []
    private var lastOverlayKeys: Set<String> = []
    
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
        
        // DataSourceMap -> annotations/featureOverlays/tileOverlay -> each trigger this
        requerySubject
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] index in
                Task { [weak self] in
                    await self?.queryFeatures()
                }
            }
            .store(in: &cancellable)
//        
//        mapStateRepository.$zoom
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] zoom in
//            self?.requerySubject.send(())
//        }
//            .store(in: &cancellable)
//        
//        mapStateRepository.$region
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] region in
//            self?.requerySubject.send(())
//        }
//            .store(in: &cancellable)
//        
        repository?.refreshPublisher?
            .sink { [weak self] date in
                self?.refresh()
            }
            .store(in: &cancellable)
    }
    
    // this requeries for all features and recreates all tile overlays
    func refresh() {
        requerySubject.send(())
    }
    
    private func queryFeatures() async {
        guard let zoom = mapStateRepository.zoom, let region = mapStateRepository.region else { return }
        if UserDefaults.standard.hideObservations {
            annotations = []
            featureOverlays = []
            lastAnnotationKeys = []
            lastOverlayKeys = []
            return
        }
        let features = await mapFeatureRepository?.getAnnotationsAndOverlays(
            zoom: zoom,
            region: region.padded(percentage: 2.0)
        )
        let newAnnotations = features?.annotations ?? []
        let newAnnotationKeys = Set(newAnnotations.map { $0.key() })
        if newAnnotationKeys.count != lastAnnotationKeys.count || newAnnotationKeys != lastAnnotationKeys {
            lastAnnotationKeys = newAnnotationKeys
            annotations = newAnnotations.sorted(by: { first, second in
                first.id < second.id
            })
        }
        if let overlays = features?.overlays {
            let newOverlayKeys = Set(overlays.compactMap { ($0 as? DataSourceIdentifiable)?.key() })
            if newOverlayKeys.count != lastOverlayKeys.count || newOverlayKeys != lastOverlayKeys {
                lastOverlayKeys = newOverlayKeys
                featureOverlays = overlays
            }
        }
    }
}
