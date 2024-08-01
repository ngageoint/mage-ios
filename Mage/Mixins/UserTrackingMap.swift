//
//  UserTracking.swift
//  MAGE
//
//  Created by Daniel Barela on 1/25/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MaterialComponents
import MapFramework

protocol UserTrackingMap {
    var mapView: MKMapView? { get set }
    var navigationController: UINavigationController? { get }
    var userTrackingMapMixin: UserTrackingMapMixin? { get set }
}

class UserTrackingMapMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var userTrackingMap: UserTrackingMap
    var scheme: MDCContainerScheming?
    weak var buttonParentView: UIStackView?
    var indexInView: Int = 0
    var locationManager: CLLocationManager?
    var isTrackingAnimation: Bool = false
    var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    private lazy var trackingButton: MDCFloatingButton = {
        let trackingButton = MDCFloatingButton(shape: .mini)
        trackingButton.setImage(UIImage(systemName: "location"), for: .normal)
        trackingButton.addTarget(self, action: #selector(onTrackingButtonPressed(_:)), for: .touchUpInside)
        trackingButton.accessibilityLabel = "track location"
        return trackingButton
    }()
    
    init(userTrackingMap: UserTrackingMap, buttonParentView: UIStackView?, indexInView: Int = 0, locationManager: CLLocationManager? = CLLocationManager(), scheme: MDCContainerScheming?) {
        self.userTrackingMap = userTrackingMap
        self.mapView = userTrackingMap.mapView
        self.scheme = scheme
        self.buttonParentView = buttonParentView
        self.indexInView = indexInView
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
        
        trackingButton.backgroundColor = scheme.colorScheme.surfaceColor;
        trackingButton.tintColor = scheme.colorScheme.primaryColorVariant;
        self.trackingButton.setImageTintColor(scheme.colorScheme.primaryColorVariant, for: .normal)
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        guard let buttonParentView = buttonParentView else {
            return
        }
        if buttonParentView.arrangedSubviews.count < indexInView {
            buttonParentView.insertArrangedSubview(trackingButton, at: buttonParentView.arrangedSubviews.count)
        } else {
            buttonParentView.insertArrangedSubview(trackingButton, at: indexInView)
        }
        
        applyTheme(scheme: scheme)
        
        locationManager?.delegate = self
        
        setupTrackingButton()
    }
    
    @objc func onTrackingButtonPressed(_ sender: UIButton) {
        let authorized = locationAuthorizationStatus == .authorizedAlways || locationAuthorizationStatus == .authorizedWhenInUse
        if !authorized {
            let alert = UIAlertController(title: "Location Services Disabled", message: "MAGE has been denied access to location services.  To show your location on the map, please go into your device settings and enable the Location permission.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
            userTrackingMap.navigationController?.present(alert, animated: true, completion: nil)
            return
        }
        
        guard let mapView = userTrackingMap.mapView else {
            return
        }

        switch mapView.userTrackingMode {
        case .none:
            mapView.setUserTrackingMode(.follow, animated: true)
            trackingButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        case .follow:
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            trackingButton.setImage(UIImage(systemName: "location.north.line.fill"), for: .normal)
        case .followWithHeading:
            mapView.setUserTrackingMode(.none, animated: true)
            trackingButton.setImage(UIImage(systemName: "location"), for: .normal)
        @unknown default:
            mapView.setUserTrackingMode(.none, animated: true)
            trackingButton.setImage(UIImage(systemName: "location"), for: .normal)
        }
    }
    
    func setupTrackingButton() {
        let authorized = locationAuthorizationStatus == .authorizedAlways || locationAuthorizationStatus == .authorizedWhenInUse
        if !authorized {
            trackingButton.applySecondaryTheme(withScheme: globalDisabledScheme())
        } else {
            guard let scheme = scheme else {
                return
            }
            self.trackingButton.backgroundColor = scheme.colorScheme.surfaceColor;
            self.trackingButton.tintColor = scheme.colorScheme.primaryColorVariant;
            self.trackingButton.setImageTintColor(scheme.colorScheme.primaryColorVariant, for: .normal)
        }
    }
}

extension UserTrackingMapMixin: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        setupTrackingButton()
    }
}
