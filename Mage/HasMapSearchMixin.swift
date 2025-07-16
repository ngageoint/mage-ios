//
//  HasMapSearchMixin.swift
//  MAGE
//
//  Created by William Newman on 11/29/23.
//  Copyright © 2023 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework

import Combine
import MGRS
import GARS

protocol HasMapSearch {
    var mapView: MKMapView? { get set }
    var scheme: MDCContainerScheming? { get set }
    var navigationController: UINavigationController? { get set }
    var hasMapSearchMixin: HasMapSearchMixin? { get set }
    func onSearchResultSelected(result: GeocoderResult);
}

class HasMapSearchMixin: NSObject, MapMixin {
    @Injected(\.settingsRepository)
    var settingsRepository: SettingsRepository
    
    var hasMapSearch: HasMapSearch
    var rootView: UIStackView
    var indexInView: Int = 0
    var scheme: MDCContainerScheming?
    var bottomSheet: MDCBottomSheetController?;
    var navigationController: UINavigationController?
    var annotation: MKPointAnnotation?
    var searchController: SearchSheetController
    
    var cancellables: Set<AnyCancellable> = Set()

    private lazy var mapSearchButton: MDCFloatingButton = {
        let mapSearchButton = MDCFloatingButton(shape: .mini)
        mapSearchButton.setImage(UIImage(systemName:"magnifyingglass"), for: .normal)
        mapSearchButton.addTarget(self, action: #selector(mapSearchButtonTapped(_:)), for: .touchUpInside)
        mapSearchButton.accessibilityLabel = "map_search"
        return mapSearchButton
    }()
    
    init(hasMapSearch: HasMapSearch, rootView: UIStackView, indexInView: Int = 0, navigationController: UINavigationController?, scheme: MDCContainerScheming?) {
        self.hasMapSearch = hasMapSearch
        self.rootView = rootView
        self.indexInView = indexInView
        self.navigationController = navigationController
        self.scheme = scheme
        self.searchController = SearchSheetController(mapView: hasMapSearch.mapView, scheme: scheme)
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
        hasMapSearch.scheme = scheme
        mapSearchButton.backgroundColor = scheme?.colorScheme.surfaceColor;
        mapSearchButton.tintColor = scheme?.colorScheme.primaryColorVariant;
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        settingsRepository.observeSettings()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { settingsModel in
                self.updateView(settingsModel: settingsModel)
            })
            .store(in: &cancellables)
    }
    
    func updateView(settingsModel: SettingsModel?) {
        if let settings = settingsModel,
           settings.mapSearchType != .none
        {
            mapSearchButton.isHidden = false
            if rootView.arrangedSubviews.count < indexInView {
                rootView.insertArrangedSubview(mapSearchButton, at: rootView.arrangedSubviews.count)
            } else {
                rootView.insertArrangedSubview(mapSearchButton, at: indexInView)
            }
            applyTheme(scheme: hasMapSearch.scheme)
        } else {
            mapSearchButton.isHidden = true
        }
    }
    
    func cleanupMixin() {
        self.searchController.dismiss(animated: true)
    }
    
    @objc func mapSearchButtonTapped(_ sender: UIButton) {
        showSearchBottomSheet()
    }
    
    func showSearchBottomSheet() {
        searchController.delegate = self
        searchController.modalPresentationStyle = .formSheet
        if let sheet = searchController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.delegate = self
        }
        self.navigationController?.present(searchController, animated: true, completion: nil)
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "SearchAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        annotationView?.markerTintColor = scheme?.colorScheme.primaryColor

        return annotationView
    }
}

extension HasMapSearchMixin: UISheetPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let mapView = hasMapSearch.mapView else { return }
        
        // reset the layout margin if it was updated
        mapView.layoutMargins.bottom = 0.0
    }
}

extension HasMapSearchMixin: SearchControllerDelegate {
    func clearSearchResult() {
        guard let mapView = hasMapSearch.mapView else { return }
        if let annotation = annotation {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func onSearchResultSelected(type: SearchResponseType, result: GeocoderResult) {
        guard let location = result.location else { return }
        guard let mapView = hasMapSearch.mapView else { return }

        if let annotation = annotation {
            mapView.removeAnnotation(annotation)
        }
        
        let region = getRegion(searchType: type, location: location, grid: result.address)
        mapView.setRegion(region, animated: true)
        
        let newAnnotation = MKPointAnnotation()
        newAnnotation.title = result.name
        newAnnotation.coordinate = location
        mapView.addAnnotation(newAnnotation)
        annotation = newAnnotation
        
        let screenHeight = UIScreen.main.bounds.size.height
        mapView.layoutMargins.bottom = screenHeight / 2
        
        hasMapSearch.onSearchResultSelected(result: result)
    }
    
    private func getRegion(searchType: SearchResponseType, location: CLLocationCoordinate2D, grid: String?) -> MKCoordinateRegion {
        var region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)

        if (searchType == .mgrs) {
            if let grid = grid {
                let gridType = MGRS.precision(grid)
                switch (gridType) {
                    case .GZD, .HUNDRED_KILOMETER:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 500000, longitudinalMeters: 500000)
                    case .TEN_KILOMETER:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 50000, longitudinalMeters: 50000)
                    case .KILOMETER:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 5000, longitudinalMeters: 5000)
                    case .HUNDRED_METER:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
                    case .TEN_METER, .METER:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 50, longitudinalMeters: 50)
                    }
            }
        } else if (searchType == .gars) {
            if let grid = grid {
                let gridType = GARS.precision(grid)
                switch (gridType) {
                    case .TWENTY_DEGREE:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 1000000, longitudinalMeters: 1000000)
                    case .TEN_DEGREE:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 75000, longitudinalMeters: 75000)
                    case .FIVE_DEGREE, .ONE_DEGREE:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 62500, longitudinalMeters: 62500)
                    case .THIRTY_MINUTE:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 50000, longitudinalMeters: 50000)
                    case .FIFTEEN_MINUTE:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 37500, longitudinalMeters: 37500)
                    case .FIVE_MINUTE:
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 25000, longitudinalMeters: 25000)
                    }
            }
        }
        
        return region
    }
}
