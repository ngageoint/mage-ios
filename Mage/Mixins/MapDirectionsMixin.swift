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
import MapFramework

protocol Navigable {
    var coordinate: CLLocationCoordinate2D { get }
}

protocol MapDirections {
    var mapView: MKMapView? { get set }
    var mapDirectionsMixin: MapDirectionsMixin? { get set }
}

class MapDirectionsMixin: NSObject, MapMixin {
    @Injected(\.observationLocationRepository)
    var observationLocationRepository: ObservationLocationRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    @Injected(\.feedItemRepository)
    var feedItemRepository: FeedItemRepository
    
    var directionsToItemObserver: Any?
    var startStraightLineNavigationObserver: Any?
    var mapView: MKMapView?
    weak var mapStack: UIStackView?
    var scheme: MDCContainerScheming?
    var mapDirections: MapDirections
    weak var viewController: UIViewController?
    var sourceView: UIView?
    var straightLineNotification: StraightLineNavigationNotification?
    var straightLineNavigation: StraightLineNavigation?
    var locationManager: CLLocationManager?
    var locationFetchedResultsController: NSFetchedResultsController<Location>?
    var observationFetchedResultsController: NSFetchedResultsController<Observation>?
    var feedItemFetchedResultsController: NSFetchedResultsController<FeedItem>?
    private var timer: Timer?
    
    init(mapDirections: MapDirections, viewController: UIViewController, mapStack: UIStackView?, scheme: MDCContainerScheming?, locationManager: CLLocationManager? = nil, sourceView: UIView? = nil) {
        self.mapDirections = mapDirections
        self.mapView = mapDirections.mapView
        self.viewController = viewController
        self.mapStack = mapStack
        self.scheme = scheme
        self.sourceView = sourceView
        self.locationManager = locationManager
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        directionsToItemObserver = NotificationCenter.default.addObserver(forName: .DirectionsToItem, object: nil, queue: .main) { [weak self] notification in
            if let directionsNotification = notification.object as? DirectionsToItemNotification {
                Task { [weak self] in
                    await self?.getDirections(notification: directionsNotification)
                }
            }
        }
        
        startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { [weak self] notification in
            if let straightLineNotification = notification.object as? StraightLineNavigationNotification {
                self?.startStraightLineNavigation(notification: straightLineNotification)
            }
        }
    }
    
    func cleanupMixin() {
        if let directionsToItemObserver = directionsToItemObserver {
            NotificationCenter.default.removeObserver(directionsToItemObserver, name: .DirectionsToItem, object: nil)
        }
        directionsToItemObserver = nil
        if let startStraightLineNavigationObserver = startStraightLineNavigationObserver {
            NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
        }
        startStraightLineNavigationObserver = nil
        self.locationManager?.delegate = nil;
        self.locationManager = nil
    }
    
    func startStraightLineNavigation(notification: StraightLineNavigationNotification) {
        self.straightLineNotification = notification
        self.locationManager = self.locationManager ?? CLLocationManager()
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
    
    func getDirections(notification: DirectionsToItemNotification) async {
        var location: CLLocation?
        var title: String?
        var image: UIImage?
        
        if notification.dataSource.key == DataSources.observation.key,
           let observationLocationUri = notification.itemKey,
           let uri = URL(string: observationLocationUri)
        {
            if let observationLocation = await observationLocationRepository.getObservationLocation(observationLocationUri: uri)
            {
                title = observationLocation.primaryFieldText ?? "Observation"
                if let imageName = ObservationImageRepositoryImpl.shared.imageName(
                    eventId: observationLocation.eventId,
                    formId: observationLocation.formId,
                    primaryFieldText: observationLocation.primaryFieldText,
                    secondaryFieldText: observationLocation.secondaryFieldText
                ) {
                    image = UIImage(named: imageName)
                }
            }
        }
        
        if notification.dataSource.key == DataSources.user.key,
           let userUri = notification.itemKey,
           let uri = URL(string: userUri)
        {
            if let user = await userRepository.getUser(userUri: uri) {
                title = user.name ?? "User"
                image = UIImage(systemName: "person.fill")
            }
        }
        
        if notification.dataSource.key == DataSources.feedItem.key,
           let key = notification.itemKey,
           let uri = URL(string: key)
        {
            if let feedItem = await feedItemRepository.getFeedItem(feedItemUri: uri) {
                title = feedItem.title ?? "Feed Item"
                image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: globalContainerScheme().colorScheme.primaryColor);
                if let url: URL = feedItem.iconURL {
                    let size = 24;
                    
                    let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
                    await KingfisherManager.shared.retrieveImage(with: url, options: [
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
        }
        
        if notification.dataSource.key == DataSources.featureItem.key,
           let key = notification.itemKey,
           let featureItem = FeatureItem.fromKey(jsonString: key)
        {
            title = featureItem.featureTitle ?? "Feature"
            image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: globalContainerScheme().colorScheme.primaryColor);
            if let url: URL = featureItem.iconURL {
                let size = 24;
                
                let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
                await KingfisherManager.shared.retrieveImage(with: url, options: [
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
        
        if let notificationAnnotation = notification.annotation, let coordinate = await notificationAnnotation.annotation?.coordinate {
            location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            image = await notificationAnnotation.image
        }
                
        guard let location = location else {
            return;
        }
        
        var extraActions: [UIAlertAction] = [];
        await extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            var straightLineNavigationNotification = StraightLineNavigationNotification(coordinate: location.coordinate)
            straightLineNavigationNotification.title = title
            straightLineNavigationNotification.image = image
            straightLineNavigationNotification.imageURL = notification.imageUrl
            
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:straightLineNavigationNotification)
            NotificationCenter.default.post(name: .MapRequestFocus, object: nil)
        }));
        
        let appleMapsQueryString = "daddr=\(location.coordinate.latitude),\(location.coordinate.longitude)&dirflg=d".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed);
        
        let appleMapsUrl = URL(string: "https://maps.apple.com/?\(appleMapsQueryString ?? "")");
        
        let googleMapsUrl = URL(string: "https://maps.google.com/?\(appleMapsQueryString ?? "")");
        
        let alert = await UIAlertController(title: "Navigate With...", message: nil, preferredStyle: .actionSheet);
        
        if notification.includeCopy {
            await alert.addAction(UIAlertAction(title: "Copy To Clipboard", style: .default, handler: { (action) in
                    UIPasteboard.general.string = location.coordinate.toDisplay()
                    MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location \(location.coordinate.toDisplay()) copied to clipboard"))
            }))
        }
        
        await alert.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { (action) in
            UIApplication.shared.open(appleMapsUrl!, options: [:]) { (success) in
                print("opened? \(success)")
            }
        }))
        await alert.addAction(UIAlertAction(title:"Google Maps", style: .default, handler: { (action) in
            UIApplication.shared.open(googleMapsUrl!, options: [:]) { (success) in
                print("opened? \(success)")
            }
        }))
        for action in extraActions {
            await alert.addAction(action);
        }
        
        await alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
        
        if let popoverController = await alert.popoverPresentationController {
            var view: UIView? = notification.sourceView ?? sourceView
            if view == nil {
                popoverController.permittedArrowDirections = []
                view = await viewController?.view
            }
            if let view = view {
                popoverController.sourceView = view
                popoverController.sourceRect = await CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }
        
        await viewController?.present(alert, animated: true, completion: nil);
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let overlay = overlay as? NavigationOverlay {
            return overlay.renderer
        }
        return nil
    }
}

extension MapDirectionsMixin : CLLocationManagerDelegate {
    
    func maybeScheduleTimer(_ manager: CLLocationManager, straightLineNotification: StraightLineNavigationNotification, straightLineNavigation: StraightLineNavigation) {
        if let timer = timer {
            if !timer.isValid {
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { (timer) in
                    timer.invalidate()
                    straightLineNavigation.updateNavigationLines(manager: manager, destinationCoordinate: straightLineNotification.coordinate);
                })
            }
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { (timer) in
                timer.invalidate()
                straightLineNavigation.updateNavigationLines(manager: manager, destinationCoordinate: straightLineNotification.coordinate);
            })
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let straightLineNotification = straightLineNotification, let straightLineNavigation = straightLineNavigation {
            maybeScheduleTimer(manager, straightLineNotification: straightLineNotification, straightLineNavigation: straightLineNavigation)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if let straightLineNotification = straightLineNotification, let straightLineNavigation = straightLineNavigation {
            maybeScheduleTimer(manager, straightLineNotification: straightLineNotification, straightLineNavigation: straightLineNavigation)
        }
    }
}

extension MapDirectionsMixin : StraightLineNavigationDelegate {
    func cancelStraightLineNavigation() {
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
