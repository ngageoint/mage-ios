//
//  CanReportLocation.swift
//  MAGE
//
//  Created by Daniel Barela on 1/4/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MaterialComponents
import MapFramework

protocol CanReportLocation {
    var mapView: MKMapView? { get set }
    var scheme: MDCContainerScheming? { get set }
    var navigationController: UINavigationController? { get }
    var canReportLocationMixin: CanReportLocationMixin? { get set }
}

class CanReportLocationMixin: NSObject, MapMixin {
    var canReportLocation: CanReportLocation
    weak var buttonParentView: UIStackView?
    var indexInView: Int = 1
    var locationManager: CLLocationManager?
    var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private lazy var reportLocationButton: MDCFloatingButton = {
        let reportLocationButton = MDCFloatingButton(shape: .mini)
        reportLocationButton.setImage(UIImage(named:"location_tracking_off"), for: .normal)
        reportLocationButton.addTarget(self, action: #selector(reportLocationButtonPressed(_:)), for: .touchUpInside)
        reportLocationButton.accessibilityLabel = "report location"
        return reportLocationButton
    }()
    
    init(canReportLocation: CanReportLocation, buttonParentView: UIStackView?, indexInView: Int = 1, locationManager: CLLocationManager? = CLLocationManager()) {
        self.canReportLocation = canReportLocation
        self.buttonParentView = buttonParentView
        self.indexInView = indexInView
        self.locationManager = locationManager
    }
    
    func cleanupMixin() {
        locationManager?.delegate = nil
        locationManager = nil
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
        guard let scheme = self.canReportLocation.scheme else {
            return
        }
        reportLocationButton.backgroundColor = scheme.colorScheme.surfaceColor;
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
            buttonParentView.insertArrangedSubview(reportLocationButton, at: buttonParentView.arrangedSubviews.count)
        } else {
            buttonParentView.insertArrangedSubview(reportLocationButton, at: indexInView)
        }
        
        applyTheme(scheme: self.canReportLocation.scheme)
        
        locationManager?.delegate = self
        
        
        setupReportLocationButton()
    }
    
    @objc func reportLocationButtonPressed(_ sender: UIButton) {
        let authorized = locationAuthorizationStatus == .authorizedAlways || locationAuthorizationStatus == .authorizedWhenInUse
        
        let context = NSManagedObjectContext.mr_default()
        let inEvent = Event.getCurrentEvent(context: context)?.isUserInEvent(user: User.fetchCurrentUser(context: context)) ?? false
        
        if UserDefaults.standard.locationServiceDisabled {
            MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location reporting for this MAGE server is disabled"))
        } else if !authorized {
            let alert = UIAlertController(title: "Location Services Disabled", message: "MAGE has been denied access to location services.  To report your location please go into your device settings and enable the Location permission.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
            canReportLocation.navigationController?.present(alert, animated: true, completion: nil)
        } else if !inEvent {
            MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "You cannot report your location for an event you are not part of"))
        } else if !UserDefaults.standard.reportLocation {
            UserDefaults.standard.reportLocation = !UserDefaults.standard.reportLocation
            MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "You are now reporting your location"))
        } else {
            UserDefaults.standard.reportLocation = !UserDefaults.standard.reportLocation
            MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location reporting has been disabled"))
        }
        
        setupReportLocationButton()
    }
    
    func setupReportLocationButton() {
        
        let authorized = locationAuthorizationStatus == .authorizedAlways || locationAuthorizationStatus == .authorizedWhenInUse
        
        let trackingOn = UserDefaults.standard.reportLocation
        let context = NSManagedObjectContext.mr_default()
        let inEvent = Event.getCurrentEvent(context: context)?.isUserInEvent(user: User.fetchCurrentUser(context: context)) ?? false
        
        if UserDefaults.standard.locationServiceDisabled {
            reportLocationButton.setImage(UIImage(named: "location_tracking_off"), for: .normal)
            reportLocationButton.tintColor = canReportLocation.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.3)
        } else if trackingOn && inEvent && authorized {
            reportLocationButton.setImage(UIImage(named: "location_tracking_on"), for: .normal)
            reportLocationButton.tintColor = UIColor(red: 76.0/255.0, green:175.0/255.0, blue:80.0/255.0, alpha:1.0)
        } else if inEvent {
            reportLocationButton.setImage(UIImage(named: "location_tracking_off"), for: .normal)
            reportLocationButton.tintColor = UIColor(red: 244.0/255.0, green:67.0/255.0, blue:54.0/255.0, alpha:1.0)
        } else {
            reportLocationButton.setImage(UIImage(named: "location_tracking_off"), for: .normal)
            reportLocationButton.tintColor = canReportLocation.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.3)
        }
    }
}

extension CanReportLocationMixin: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        setupReportLocationButton()
    }
}
