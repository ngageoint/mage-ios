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

protocol UserTrackingMap {
    var mapView: MKMapView? { get set }
    var navigationController: UINavigationController? { get }
    var userTrackingMapMixin: UserTrackingMapMixin? { get set }
}

class UserTrackingMapMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var userTrackingMap: UserTrackingMap
    var scheme: MDCContainerScheming?
    var buttonParentView: UIStackView?
    var indexInView: Int = 0
    var locationManager: CLLocationManager?
    var isTrackingAnimation: Bool = false
    var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    private lazy var trackingButton: MDCFloatingButton = {
        let trackingButton = MDCFloatingButton(shape: .mini)
        trackingButton.setImage(UIImage(named:"location_arrow_off"), for: .normal)
        trackingButton.addTarget(self, action: #selector(onTrackingButtonPressed(_:)), for: .touchUpInside)
        trackingButton.accessibilityLabel = "report location"
        return trackingButton
    }()
    
    init(userTrackingMap: UserTrackingMap, buttonParentView: UIStackView?, indexInView: Int = 0, scheme: MDCContainerScheming?) {
        self.userTrackingMap = userTrackingMap
        self.mapView = userTrackingMap.mapView
        self.scheme = scheme
        self.buttonParentView = buttonParentView
        self.indexInView = indexInView
    }
    
    deinit {
        locationManager?.delegate = nil
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }
        self.scheme = scheme
        
        trackingButton.backgroundColor = scheme.colorScheme.surfaceColor;
        trackingButton.tintColor = scheme.colorScheme.primaryColor;
        self.trackingButton.setImageTintColor(scheme.colorScheme.primaryColor, for: .normal)
    }
    
    func setupMixin() {
        guard let buttonParentView = buttonParentView else {
            return
        }
        if buttonParentView.arrangedSubviews.count < indexInView {
            buttonParentView.insertArrangedSubview(trackingButton, at: buttonParentView.arrangedSubviews.count)
        } else {
            buttonParentView.insertArrangedSubview(trackingButton, at: indexInView)
        }
        
        applyTheme(scheme: scheme)
        
        locationManager = CLLocationManager()
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
        }
        
        guard let mapView = userTrackingMap.mapView else {
            return
        }

        switch mapView.userTrackingMode {
        case .none:
            mapView.setUserTrackingMode(.follow, animated: true)
            // startHeading()
            trackingButton.setImage(UIImage(named: "location_arrow_on"), for: .normal)
        case .follow:
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            // startHeading()
            trackingButton.setImage(UIImage(named: "location_arrow_follow"), for: .normal)
        case .followWithHeading:
            mapView.setUserTrackingMode(.none, animated: true)
            trackingButton.setImage(UIImage(named: "location_arrow_off"), for: .normal)
        @unknown default:
            mapView.setUserTrackingMode(.none, animated: true)
            trackingButton.setImage(UIImage(named: "location_arrow_off"), for: .normal)
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
            self.trackingButton.tintColor = scheme.colorScheme.primaryColor;
            self.trackingButton.setImageTintColor(scheme.colorScheme.primaryColor, for: .normal)
        }
    }
}

extension UserTrackingMapMixin: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationAuthorizationStatus = status
        setupTrackingButton()
    }
}
