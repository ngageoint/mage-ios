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

protocol CanReportLocation {
    var mapView: MKMapView? { get set }
    var navigationController: UINavigationController? { get }
    var canReportLocationMixin: CanReportLocationMixin? { get set }
}

class CanReportLocationMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var canReportLocation: CanReportLocation
    var scheme: MDCContainerScheming?
    var buttonParentView: UIStackView?
    var locationService: LocationService?
    var indexInView: Int = 1
    var locationManager: CLLocationManager?
    var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private lazy var reportLocationButton: MDCFloatingButton = {
        let createFab = MDCFloatingButton(shape: .mini)
        createFab.setImage(UIImage(named:"location_tracking_off"), for: .normal)
        createFab.addTarget(self, action: #selector(reportLocationButtonPressed(_:)), for: .touchUpInside)
        createFab.accessibilityLabel = "report location"
        return createFab
    }()
    
    init(canReportLocation: CanReportLocation, buttonParentView: UIStackView?, indexInView: Int = 1, scheme: MDCContainerScheming?) {
        self.canReportLocation = canReportLocation
        self.mapView = canReportLocation.mapView
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
        reportLocationButton.backgroundColor = scheme.colorScheme.surfaceColor;
    }
    
    func setupMixin() {
        guard let buttonParentView = buttonParentView else {
            return
        }
        if buttonParentView.arrangedSubviews.count < indexInView {
            buttonParentView.insertArrangedSubview(reportLocationButton, at: buttonParentView.arrangedSubviews.count)
        } else {
            buttonParentView.insertArrangedSubview(reportLocationButton, at: indexInView)
        }
        
        applyTheme(scheme: scheme)
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        
        setupReportLocationButton()
    }
    
    @objc func reportLocationButtonPressed(_ sender: UIButton) {
        let authorized = locationAuthorizationStatus == .authorizedAlways || locationAuthorizationStatus == .authorizedWhenInUse
        
        let context = NSManagedObjectContext.mr_default()
        let inEvent = Event.getCurrentEvent(context: context)?.isUserInEvent(user: User.fetchCurrentUser(context: context)) ?? false

        if !authorized {
            let alert = UIAlertController(title: "Location Services Disabled", message: "MAGE has been denied access to location services.  To report your location please go into your device settings and enable the Location permission.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
            canReportLocation.navigationController?.present(alert, animated: true, completion: nil)
        } else if !inEvent {
            let alert = UIAlertController(title: "Not In Event", message: "You cannot report your location for an event you are not part of.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            canReportLocation.navigationController?.present(alert, animated: true, completion: nil)
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
        
        if trackingOn && inEvent && authorized {
            reportLocationButton.setImage(UIImage(named: "location_tracking_on"), for: .normal)
            reportLocationButton.tintColor = UIColor(red: 76.0/255.0, green:175.0/255.0, blue:80.0/255.0, alpha:1.0)
        } else {
            reportLocationButton.setImage(UIImage(named: "location_tracking_off"), for: .normal)
            reportLocationButton.tintColor = UIColor(red: 244.0/255.0, green:67.0/255.0, blue:54.0/255.0, alpha:1.0)
        }
    }
}

extension CanReportLocationMixin: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationAuthorizationStatus = status
        setupReportLocationButton()
    }
}
