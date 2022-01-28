//
//  DirectionsMixin.swift
//  MAGE
//
//  Created by Daniel Barela on 12/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol MapDirections {
    var mapView: MKMapView? { get set }
    var mapDirectionsMixin: MapDirectionsMixin? { get set }
}

class MapDirectionsMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var mapStack: UIStackView?
    var scheme: MDCContainerScheming?
    var mapDirections: MapDirections
    var viewController: UIViewController
    var sourceView: UIView?
    var itemToNavigateTo: Any?
    var straightLineNotification: StraightLineNavigationNotification?
    var straightLineNavigation: StraightLineNavigation?
    var locationManager: CLLocationManager?
    
    init(mapDirections: MapDirections, viewController: UIViewController, mapStack: UIStackView?, scheme: MDCContainerScheming?, sourceView: UIView? = nil) {
        self.mapDirections = mapDirections
        self.mapView = mapDirections.mapView
        self.viewController = viewController
        self.mapStack = mapStack
        self.scheme = scheme
        self.sourceView = sourceView
    }
    
    func setupMixin() {
        NotificationCenter.default.addObserver(forName: .DirectionsToItem, object: nil, queue: .main) { [weak self] notification in
            if let directionsNotification = notification.object as? DirectionsToItemNotification {
                self?.getDirections(notification: directionsNotification)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { [weak self] notification in
            if let straightLineNotification = notification.object as? StraightLineNavigationNotification {
                self?.startStraightLineNavigation(notification: straightLineNotification)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .DirectionsToItem, object: nil)
        NotificationCenter.default.removeObserver(self, name: .StartStraightLineNavigation, object: nil)
    }
    
    func startStraightLineNavigation(notification: StraightLineNavigationNotification) {
        self.straightLineNotification = notification
        if let observation = notification.observation {
            itemToNavigateTo = observation
        } else if let user = notification.user {
            itemToNavigateTo = user
        }
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self;
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager?.startUpdatingLocation()
        self.locationManager?.headingFilter = 0.5
        self.locationManager?.startUpdatingHeading()
        
        guard let locationManager = locationManager, let mapStack = mapStack, let mapView = mapView else {
            return
        }
        
        if straightLineNavigation == nil {
            straightLineNavigation = StraightLineNavigation(mapView: mapView, locationManager: locationManager, mapStack: mapStack)
        }
        
        straightLineNavigation?.stopNavigation()
        straightLineNavigation?.startNavigation(manager: locationManager, destinationCoordinate: notification.coordinate, delegate: self, image: notification.image, imageURL: notification.imageURL, scheme: scheme)
    }
    
    func updateStraightLineNavigationDestination(destination: CLLocationCoordinate2D) {
        if let locationManager = locationManager {
            straightLineNavigation?.updateNavigationLines(manager: locationManager, destinationCoordinate: destination)
        }
    }
    
    func getDirections(notification: DirectionsToItemNotification) {
        var location: CLLocation?
        var title: String?
        var image: UIImage?
        
        if let observation = notification.observation {
            location = observation.location
            title = observation.primaryFieldText ?? ""
            image = ObservationImage.image(observation: observation)
        }
        
        if let notificationLocation = notification.location {
            location = notificationLocation
        }
        
        if let notificationAnnotation = notification.annotation, let coordinate = notificationAnnotation.annotation?.coordinate {
            location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            image = notificationAnnotation.image
        }
                
        guard let location = location else {
            return;
        }
        
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            var straightLineNavigationNotification = StraightLineNavigationNotification(coordinate: location.coordinate)
            straightLineNavigationNotification.observation = notification.observation
            straightLineNavigationNotification.feedItem = notification.feedItem
            straightLineNavigationNotification.user = notification.user
            straightLineNavigationNotification.title = title
            straightLineNavigationNotification.image = image
            straightLineNavigationNotification.imageURL = notification.imageUrl
            
            self.startStraightLineNavigation(notification: straightLineNavigationNotification)
        }));
        
        let appleMapsQueryString = "daddr=\(location.coordinate.latitude),\(location.coordinate.longitude)&ll=\(location.coordinate.latitude),\(location.coordinate.longitude)&q=\(title ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed);
        let appleMapsUrl = URL(string: "https://maps.apple.com/?\(appleMapsQueryString ?? "")");
        
        let googleMapsUrl = URL(string: "https://maps.google.com/?\(appleMapsQueryString ?? "")");
        
        let alert = UIAlertController(title: "Navigate With...", message: nil, preferredStyle: .actionSheet);
        alert.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { (action) in
            UIApplication.shared.open(appleMapsUrl!, options: [:]) { (success) in
                print("opened? \(success)")
            }
        }))
        alert.addAction(UIAlertAction(title:"Google Maps", style: .default, handler: { (action) in
            UIApplication.shared.open(googleMapsUrl!, options: [:]) { (success) in
                print("opened? \(success)")
            }
        }))
        for action in extraActions {
            alert.addAction(action);
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
        
        if let popoverController = alert.popoverPresentationController {
            var view: UIView = viewController.view;
            if let sourceView = sourceView {
                view = sourceView;
            } else {
                popoverController.permittedArrowDirections = [];
            }
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        viewController.present(alert, animated: true, completion: nil);
    }
}

extension MapDirectionsMixin : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let straightLineNotification = straightLineNotification, let straightLineNavigation = straightLineNavigation {
            straightLineNavigation.updateNavigationLines(manager: manager, destinationCoordinate: straightLineNotification.coordinate);
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if let straightLineNotification = straightLineNotification, let straightLineNavigation = straightLineNavigation {
            straightLineNavigation.updateNavigationLines(manager: manager, destinationCoordinate: straightLineNotification.coordinate);
        }
    }
}

extension MapDirectionsMixin : StraightLineNavigationDelegate {
    func cancelStraightLineNavigation() {
        itemToNavigateTo = nil
        straightLineNotification = nil
        straightLineNavigation?.stopNavigation()
        locationManager?.stopUpdatingHeading()
        locationManager?.stopUpdatingLocation()
    }
}
