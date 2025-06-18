//
//  UserHeadingDisplay.swift
//  MAGE
//
//  Created by Daniel Barela on 1/26/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MaterialComponents

protocol UserHeadingDisplay {
    var mapView: MKMapView? { get set }
    var navigationController: UINavigationController? { get }
    var userHeadingDisplayMixin: UserHeadingDisplayMixin? { get set }
}

class UserHeadingDisplayMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var userHeadingDisplay: UserHeadingDisplay
    var scheme: MDCContainerScheming?
    var locationManager: CLLocationManager?
    var straightLineNavigation: StraightLineNavigation?
    weak var mapStack: UIStackView?
    
    init(userHeadingDisplay: UserHeadingDisplay, mapStack: UIStackView, locationManager: CLLocationManager? = CLLocationManager(), scheme: MDCContainerScheming?) {
        self.userHeadingDisplay = userHeadingDisplay
        self.mapView = userHeadingDisplay.mapView
        self.scheme = scheme
        self.mapStack = mapStack
        self.locationManager = locationManager
    }
    
    func cleanupMixin() {
        locationManager?.delegate = nil
        locationManager = nil
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }
        self.scheme = scheme
    }
    
    func setupMixin() {
        applyTheme(scheme: scheme)
        
        locationManager?.delegate = self
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let overlay = overlay as? NavigationOverlay {
            return overlay.renderer
        }
        return nil
    }
    
    func start() {
        if UserDefaults.standard.showHeadingSet {
            if UserDefaults.standard.showHeading {
                locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                locationManager?.startUpdatingLocation()
                locationManager?.headingFilter = 0.5
                locationManager?.startUpdatingHeading()
                guard let mapView = userHeadingDisplay.mapView, let mapStack = mapStack, let locationManager = locationManager else {
                    return
                }

                straightLineNavigation = straightLineNavigation ?? {
                    return StraightLineNavigation(mapView: mapView, locationManager: locationManager, mapStack: mapStack)
                }()
                straightLineNavigation?.startHeading(manager: locationManager)
            }
        } else {
            // show dialog asking them what they want to do and set the preference
            let alert = UIAlertController(title: "Display Your Heading", message: "Would you like to display your heading on the map? This can be toggled in settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .cancel, handler: { action in
                UserDefaults.standard.showHeading = true
                self.start()
            }))
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
                UserDefaults.standard.showHeading = false
            }))
            userHeadingDisplay.navigationController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func stop() {
        straightLineNavigation?.stopHeading()
        locationManager?.stopUpdatingHeading()
        locationManager?.stopUpdatingLocation()
    }
    
    func didChangeUserTrackingMode(mapView: MKMapView, animated: Bool) {
        guard let mode = userHeadingDisplay.mapView?.userTrackingMode else {
            return
        }
        switch mode {
        case .none:
            break
        case .follow:
            start()
        case .followWithHeading:
            start()
        @unknown default:
            print("Unknown tracking mode \(mode)")
        }
    }
}

extension UserHeadingDisplayMixin: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        straightLineNavigation?.updateNavigationLines(manager: manager, destinationCoordinate: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        straightLineNavigation?.updateNavigationLines(manager: manager, destinationCoordinate: nil)
    }
}
