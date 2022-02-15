//
//  MainMageMapViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import MaterialComponents
import CoreData

class MainMageMapView: MageMapView, FilteredObservationsMap, FilteredUsersMap, BottomSheetEnabled, MapDirections, HasMapSettings, CanCreateObservation, CanReportLocation, UserHeadingDisplay, UserTrackingMap, StaticLayerMap, PersistedMapState, GeoPackageLayerMap, FeedsMap {
    
    weak var navigationController: UINavigationController?
    weak var viewController: UIViewController?

    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    var filteredUsersMapMixin: FilteredUsersMapMixin?
    var bottomSheetMixin: BottomSheetMixin?
    var mapDirectionsMixin: MapDirectionsMixin?
    var persistedMapStateMixin: PersistedMapStateMixin?
    var hasMapSettingsMixin: HasMapSettingsMixin?
    var canCreateObservationMixin: CanCreateObservationMixin?
    var canReportLocationMixin: CanReportLocationMixin?
    var userTrackingMapMixin: UserTrackingMapMixin?
    var userHeadingDisplayMixin: UserHeadingDisplayMixin?
    var staticLayerMapMixin: StaticLayerMapMixin?
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin?
    var feedsMapMixin: FeedsMapMixin?
    
    var viewObservationNotificationObserver: Any?
    var viewUserNotificationObserver: Any?
    var viewFeedItemNotificationObserver: Any?
    var startStraightLineNavigationNotificationObserver: Any?
    
    private lazy var buttonStack: UIStackView = {
        let buttonStack = UIStackView.newAutoLayout()
        buttonStack.alignment = .fill
        buttonStack.distribution = .fill
        buttonStack.spacing = 10
        buttonStack.axis = .vertical
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.isLayoutMarginsRelativeArrangement = true
        return buttonStack
    }()
    
    public init(viewController: UIViewController?, navigationController: UINavigationController?, scheme: MDCContainerScheming?) {
        self.viewController = viewController
        self.navigationController = navigationController
        super.init(scheme: scheme)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let viewObservationNotificationObserver = viewObservationNotificationObserver {
            NotificationCenter.default.removeObserver(viewObservationNotificationObserver, name: .ViewObservation, object: nil)
        }
        if let viewUserNotificationObserver = viewUserNotificationObserver {
            NotificationCenter.default.removeObserver(viewUserNotificationObserver, name: .ViewUser, object: nil)
        }
        if let viewFeedItemNotificationObserver = viewFeedItemNotificationObserver {
            NotificationCenter.default.removeObserver(viewFeedItemNotificationObserver, name: .ViewFeedItem, object: nil)
        }
        if let startStraightLineNavigationNotificationObserver = startStraightLineNavigationNotificationObserver {
            NotificationCenter.default.removeObserver(startStraightLineNavigationNotificationObserver, name: .StartStraightLineNavigation, object: nil)
        }
        viewController = nil
        navigationController = nil
    }
    
    override func removeFromSuperview() {
        cleanupMapMixins()
        filteredObservationsMapMixin = nil
        filteredUsersMapMixin = nil
        bottomSheetMixin = nil
        mapDirectionsMixin = nil
        persistedMapStateMixin = nil
        hasMapSettingsMixin = nil
        canCreateObservationMixin = nil
        canReportLocationMixin = nil
        userTrackingMapMixin = nil
        userHeadingDisplayMixin = nil
        staticLayerMapMixin = nil
        geoPackageLayerMapMixin = nil
        feedsMapMixin = nil
    }
    
    override func layoutView() {
        super.layoutView()

        if let mapView = mapView {
            self.insertSubview(buttonStack, aboveSubview: mapView)
            buttonStack.autoPinEdge(.top, to: .top, of: mapView, withOffset: 25)
            buttonStack.autoPinEdge(toSuperviewMargin: .left)
            
            filteredObservationsMapMixin = FilteredObservationsMapMixin(mapView: mapView, scheme: scheme)
            filteredUsersMapMixin = FilteredUsersMapMixin(filteredUsersMap: self, scheme: scheme)
            bottomSheetMixin = BottomSheetMixin(mapView: mapView, navigationController: self.navigationController, scheme: scheme)
            if let viewController = viewController {
                mapDirectionsMixin = MapDirectionsMixin(mapDirections: self, viewController: viewController, mapStack: mapStack, scheme: scheme)
                mapMixins.append(mapDirectionsMixin!)
            }
            
            persistedMapStateMixin = PersistedMapStateMixin(persistedMapState: self)
            hasMapSettingsMixin = HasMapSettingsMixin(hasMapSettings: self, navigationController: navigationController, rootView: self, scheme: scheme)
            canCreateObservationMixin = CanCreateObservationMixin(canCreateObservation: self, navigationController: navigationController, rootView: self, mapStackView: mapStack, scheme: scheme, locationService: nil)
            canReportLocationMixin = CanReportLocationMixin(canReportLocation: self, buttonParentView: buttonStack, indexInView: 1, scheme: scheme)
            userTrackingMapMixin = UserTrackingMapMixin(userTrackingMap: self, buttonParentView: buttonStack, indexInView: 0, scheme: scheme)
            userHeadingDisplayMixin = UserHeadingDisplayMixin(userHeadingDisplay: self, mapStack: mapStack, scheme: scheme)
            staticLayerMapMixin = StaticLayerMapMixin(staticLayerMap: self, scheme: scheme)
            geoPackageLayerMapMixin = GeoPackageLayerMapMixin(geoPackageLayerMap: self)
            feedsMapMixin = FeedsMapMixin(mapView: mapView, scheme: scheme)
            mapMixins.append(filteredObservationsMapMixin!)
            mapMixins.append(filteredUsersMapMixin!)
            mapMixins.append(bottomSheetMixin!)
            mapMixins.append(persistedMapStateMixin!)
            mapMixins.append(hasMapSettingsMixin!)
            mapMixins.append(canCreateObservationMixin!)
            mapMixins.append(canReportLocationMixin!)
            mapMixins.append(userTrackingMapMixin!)
            mapMixins.append(userHeadingDisplayMixin!)
            mapMixins.append(staticLayerMapMixin!)
            mapMixins.append(geoPackageLayerMapMixin!)
            mapMixins.append(feedsMapMixin!)
        }
        
        initiateMapMixins()
        
        viewObservationNotificationObserver = NotificationCenter.default.addObserver(forName: .ViewObservation, object: nil, queue: .main) { [weak self] notification in
            if let observation = notification.object as? Observation {
                self?.viewObservation(observation)
            }
        }

        viewUserNotificationObserver = NotificationCenter.default.addObserver(forName: .ViewUser, object: nil, queue: .main) { [weak self] notification in
            if let user = notification.object as? User {
                self?.viewUser(user)
            }
        }

        viewFeedItemNotificationObserver = NotificationCenter.default.addObserver(forName: .ViewFeedItem, object: nil, queue: .main) { [weak self] notification in
            if let feedItem = notification.object as? FeedItem {
                self?.viewFeedItem(feedItem)
            }
        }
    }
    
    @objc func filterTapped(_ sender: UIBarButtonItem) {
        let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil)
        guard let vc = filterStoryboard.instantiateInitialViewController() as? UINavigationController else {
            return
        }
        if let fvc: FilterTableViewController = vc.topViewController as? FilterTableViewController {
            fvc.applyTheme(withContainerScheme: scheme)
        }
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.barButtonItem = sender
        viewController?.present(vc, animated: true, completion: nil)
    }
    
    func viewUser(_ user: User) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let uvc = UserViewController(user: user, scheme: scheme)
        navigationController?.pushViewController(uvc, animated: true)
    }
    
    func viewFeedItem(_ feedItem: FeedItem) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let fivc = FeedItemViewController(feedItem: feedItem, scheme: scheme)
        navigationController?.pushViewController(fivc, animated: true)
    }
}

extension MainMageMapView : ObservationActionsDelegate {
    
    func viewObservation(_ observation: Observation) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let ovc = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme)
        navigationController?.pushViewController(ovc, animated: true)
    }
    
    func favoriteObservation(_ observation: Observation, completion: ((Observation?) -> Void)?) {
        observation.toggleFavorite { (_, _) in
            NotificationCenter.default.post(name: .ObservationUpdated, object: observation)
        }
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView? = nil) {
        //        self.resetEnlargedPin();
        //        self.mageBottomSheet.dismiss(animated: true, completion: {
        //            guard let location = observation.location else {
        //                return;
        //            }
        //            var extraActions: [UIAlertAction] = [];
        //            extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
        //                self.observationToNavigateTo = observation;
        //                self.locationToNavigateTo = kCLLocationCoordinate2DInvalid;
        //                self.userToNavigateTo = nil;
        //                self.feedItemToNavigateTo = nil;
        //                self.startStraightLineNavigation(location.coordinate, image: ObservationImage.image(observation: observation));
        //            }));
        //            ObservationActionHandler.getDirections(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, title: observation.primaryFeedFieldText ?? "Observation", viewController: self.navigationController, extraActions: extraActions, sourceView: nil);
        //        });
    }
    
}
