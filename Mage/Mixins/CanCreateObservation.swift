//
//  CanCreateObservation.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework
import SwiftUI

protocol CanCreateObservation {
    var mapView: MKMapView? { get set }
    var navigationController: UINavigationController? { get set }
    var scheme: MDCContainerScheming? { get set }
    var canCreateObservationMixin: CanCreateObservationMixin? { get set }
}

class CanCreateObservationMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var canCreateObservation: CanCreateObservation
    weak var rootView: UIView?
    weak var mapStackView: UIStackView?
    var editCoordinator: ObservationEditCoordinator?
    weak var locationService: LocationService?
    var shouldShowFab: Bool = true
    
    private lazy var createObservationButtonHC: UIHostingController<CreateObservationButton>? = {
        let swiftUIView = CreateObservationButton { [weak self] in
            self?.createNewObservation(nil)
        }
        let hostingController = UIHostingController(rootView: swiftUIView)
        
        hostingController.sizingOptions = [.intrinsicContentSize] // Support self-sizing (iOS 16+)
        hostingController.view.backgroundColor = .clear
        
        let view = hostingController.view
        view?.translatesAutoresizingMaskIntoConstraints = false
        view?.isHidden = !shouldShowFab
        return hostingController
    }()
    
    init(canCreateObservation: CanCreateObservation, shouldShowFab: Bool? = true, rootView: UIView?, mapStackView: UIStackView?, locationService: LocationService? = nil) {
        self.canCreateObservation = canCreateObservation
        self.mapView = canCreateObservation.mapView
        self.rootView = rootView
        self.mapStackView = mapStackView
        if let locationService = locationService {
            self.locationService = locationService
        } else {
            self.locationService = LocationService.singleton()
        }
        self.shouldShowFab = shouldShowFab ?? true
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }
        canCreateObservation.scheme = scheme
    }

    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        guard let mapView = self.canCreateObservation.mapView, let mapStackView = mapStackView else {
            return
        }
        
        // Add the shared CreateObservation button from SwiftUI
        if let createObservationButtonHC,
           let createObservationButton = createObservationButtonHC.view {
            rootView?.insertSubview(createObservationButton, aboveSubview: mapView)
            createObservationButton.autoPinEdge(.bottom, to: .top, of: mapStackView, withOffset: -25)
            createObservationButton.autoPinEdge(toSuperviewMargin: .trailing)
            if let parentVC = rootView?.parentViewController {
                parentVC.addChild(createObservationButtonHC)
                createObservationButtonHC.didMove(toParent: parentVC)
            }
        }
        applyTheme(scheme: canCreateObservation.scheme)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPress(_:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func createNewObservation(_ sender: UIButton?) {
        let location = locationService?.location()
        startCreateNewObservation(location: location, provider: "gps")
    }
    
    @objc func mapLongPress(_ sender: UIGestureRecognizer) {
        guard let mapView = self.canCreateObservation.mapView else {
            return
        }
        if sender.state == .began {
            let touchPoint = sender.location(in: mapView)
            let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let mapPressLocation = CLLocation(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude)
            startCreateNewObservation(location: mapPressLocation, provider: "manual")
        }
    }
    
    func startCreateNewObservation(location: CLLocation?, provider: String) {
        var point: SFPoint? = nil
        var accuracy: CLLocationAccuracy = 0
        var delta: Double = 0
        
        if let location = location {
            if location.altitude != 0 {
                point = SFPoint(xValue: location.coordinate.longitude, andYValue: location.coordinate.latitude, andZValue: location.altitude)
            } else {
                point = SFPoint(xValue: location.coordinate.longitude, andYValue: location.coordinate.latitude)
            }
            
            accuracy = location.horizontalAccuracy
            delta = location.timestamp.timeIntervalSinceNow * -1000
        }
        
        editCoordinator = ObservationEditCoordinator(rootViewController: canCreateObservation.navigationController, delegate: self, location: point, accuracy: accuracy, provider: provider, delta: delta)
        editCoordinator?.applyTheme(withContainerScheme: canCreateObservation.scheme)
        editCoordinator?.start()
    }
}

extension CanCreateObservationMixin: ObservationEditDelegate {
    func editCancel(_ coordinator: NSObject) {
        editCoordinator = nil
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        editCoordinator = nil
    }
}
