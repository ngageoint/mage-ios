//
//  DirectionsMixin.swift
//  MAGE
//
//  Created by Daniel Barela on 12/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import Kingfisher

protocol Navigable {
    var coordinate: CLLocationCoordinate2D { get }
}

protocol MapDirections {
    var mapView: MKMapView? { get set }
    var mapDirectionsMixin: MapDirectionsMixin? { get set }
}

class MapDirectionsMixin: NSObject, MapMixin {
    var directionsToItemObserver: Any?
    var startStraightLineNavigationObserver: Any?
    var mapView: MKMapView?
    weak var mapStack: UIStackView?
    var scheme: MDCContainerScheming?
    var mapDirections: MapDirections
    weak var viewController: UIViewController?
    var sourceView: UIView?
    var itemToNavigateTo: Any?
    var straightLineNotification: StraightLineNavigationNotification?
    var straightLineNavigation: StraightLineNavigation?
    var locationManager: CLLocationManager?
    var locationFetchedResultsController: NSFetchedResultsController<Location>?
    var observationFetchedResultsController: NSFetchedResultsController<Observation>?
    var feedItemFetchedResultsController: NSFetchedResultsController<FeedItem>?
    
    init(mapDirections: MapDirections, viewController: UIViewController, mapStack: UIStackView?, scheme: MDCContainerScheming?, sourceView: UIView? = nil) {
        self.mapDirections = mapDirections
        self.mapView = mapDirections.mapView
        self.viewController = viewController
        self.mapStack = mapStack
        self.scheme = scheme
        self.sourceView = sourceView
    }
    
    func setupMixin() {
        directionsToItemObserver = NotificationCenter.default.addObserver(forName: .DirectionsToItem, object: nil, queue: .main) { [weak self] notification in
            if let directionsNotification = notification.object as? DirectionsToItemNotification {
                self?.getDirections(notification: directionsNotification)
            }
        }
        
        startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { [weak self] notification in
            if let straightLineNotification = notification.object as? StraightLineNavigationNotification {
                self?.startStraightLineNavigation(notification: straightLineNotification)
            }
        }
    }
    
    deinit {
        if let directionsToItemObserver = directionsToItemObserver {
            NotificationCenter.default.removeObserver(directionsToItemObserver, name: .DirectionsToItem, object: nil)
        }
        directionsToItemObserver = nil
        if let startStraightLineNavigationObserver = startStraightLineNavigationObserver {
            NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
        }
        startStraightLineNavigationObserver = nil
    }
    
    func startStraightLineNavigation(notification: StraightLineNavigationNotification) {
        self.straightLineNotification = notification
        if let observation = notification.observation {
            itemToNavigateTo = observation
            observationFetchedResultsController = Observation.fetchedResultsController(observation, delegate: self)
            try? observationFetchedResultsController?.performFetch()
        } else if let user = notification.user {
            itemToNavigateTo = user
            locationFetchedResultsController = Location.mostRecentLocationFetchedResultsController(user, delegate: self)
            try? locationFetchedResultsController?.performFetch()
        } else if let feedItem = notification.feedItem {
            itemToNavigateTo = feedItem
            feedItemFetchedResultsController = FeedItem.fetchedResultsController(feedItem, delegate: self)
            try? feedItemFetchedResultsController?.performFetch()
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
            title = observation.primaryFieldText ?? "Observation"
            image = ObservationImage.image(observation: observation)
        }
        
        if let user = notification.user {
            location = user.location?.location
            title = user.name ?? "User"
            image = UIImage(named: "me")
        }
        
        if let feedItem = notification.feedItem {
            location = CLLocation(latitude: feedItem.coordinate.latitude, longitude: feedItem.coordinate.longitude)
            title = feedItem.title ?? "Feed Item"
            image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: globalContainerScheme().colorScheme.primaryColor);
            if let url: URL = feedItem.iconURL {
                let size = 24;
                
                let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
                KingfisherManager.shared.retrieveImage(with: url, options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ]) { result in
                    switch result {
                    case .success(let value):
                        image = value.image.aspectResize(to: CGSize(width: size, height: size));
                    case .failure(_):
                        image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: globalContainerScheme().colorScheme.primaryColor);
                    }
                }
            }
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
            
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:straightLineNavigationNotification)
            NotificationCenter.default.post(name: .MapRequestFocus, object: nil)
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
            var view: UIView? = sourceView
            if view == nil {
                popoverController.permittedArrowDirections = []
                view = viewController?.view
            }
            if let view = view {
                popoverController.sourceView = view
                popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }
        
        viewController?.present(alert, animated: true, completion: nil);
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
        straightLineNotification?.imageURL = nil
        straightLineNotification = nil
        straightLineNavigation?.stopNavigation()
        straightLineNavigation = nil
        locationManager?.stopUpdatingHeading()
        locationManager?.stopUpdatingLocation()
        feedItemFetchedResultsController?.delegate = nil
        feedItemFetchedResultsController = nil
        observationFetchedResultsController?.delegate = nil
        observationFetchedResultsController = nil
        locationFetchedResultsController?.delegate = nil
        locationFetchedResultsController = nil
    }
}

extension MapDirectionsMixin : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let locationManager = locationManager else {
            return
        }
        
        if type != .update {
            return
        }
        
        if let navigable = anObject as? Navigable {
            straightLineNavigation?.updateNavigationLines(manager: locationManager, destinationCoordinate: navigable.coordinate)
        }
    }
}
