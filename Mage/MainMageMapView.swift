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

class MainMageMapView: MageMapView, FilteredObservationsMap, FilteredUsersMap, BottomSheetEnabled, MapDirections, HasMapSettings, HasMapSearch, CanCreateObservation, CanReportLocation, UserHeadingDisplay, UserTrackingMap, StaticLayerMap, PersistedMapState, GeoPackageLayerMap, FeedsMap {
    
    weak var navigationController: UINavigationController?
    weak var viewController: UIViewController?

    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    var filteredUsersMapMixin: FilteredUsersMapMixin?
    var bottomSheetMixin: BottomSheetMixin?
    var mapDirectionsMixin: MapDirectionsMixin?
    var persistedMapStateMixin: PersistedMapStateMixin?
    var hasMapSearchMixin: HasMapSearchMixin?
    var hasMapSettingsMixin: HasMapSettingsMixin?
    var canCreateObservationMixin: CanCreateObservationMixin?
    var canReportLocationMixin: CanReportLocationMixin?
    var userTrackingMapMixin: UserTrackingMapMixin?
    var userHeadingDisplayMixin: UserHeadingDisplayMixin?
    var staticLayerMapMixin: StaticLayerMapMixin?
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin?
    var feedsMapMixin: FeedsMapMixin?
    var onlineLayerMapMixin: OnlineLayerMapMixin?
    var observationMap: ObservationsMap?

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
        hasMapSearchMixin = nil
        hasMapSettingsMixin = nil
        canCreateObservationMixin = nil
        canReportLocationMixin = nil
        userTrackingMapMixin = nil
        userHeadingDisplayMixin = nil
        staticLayerMapMixin = nil
        geoPackageLayerMapMixin = nil
        feedsMapMixin = nil
        onlineLayerMapMixin = nil
        observationMap = nil
    }
    
    override func layoutView() {
        super.layoutView()

        if let mapView = mapView {
            self.insertSubview(buttonStack, aboveSubview: mapView)
            buttonStack.autoPinEdge(.top, to: .top, of: mapView, withOffset: 25)
            buttonStack.autoPinEdge(toSuperviewMargin: .left)
            
//            filteredObservationsMapMixin = FilteredObservationsMapMixin(filteredObservationsMap: self)
            filteredUsersMapMixin = FilteredUsersMapMixin(filteredUsersMap: self, scheme: scheme)
            bottomSheetMixin = BottomSheetMixin(bottomSheetEnabled: self)
            if let viewController = viewController {
                mapDirectionsMixin = MapDirectionsMixin(mapDirections: self, viewController: viewController, mapStack: mapStack, scheme: scheme)
                mapMixins.append(mapDirectionsMixin!)
            }
            
            persistedMapStateMixin = PersistedMapStateMixin(persistedMapState: self)
            hasMapSettingsMixin = HasMapSettingsMixin(hasMapSettings: self, rootView: self)
            canCreateObservationMixin = CanCreateObservationMixin(canCreateObservation: self, shouldShowFab: UIDevice.current.userInterfaceIdiom != .pad, rootView: self, mapStackView: mapStack, locationService: nil)
            canReportLocationMixin = CanReportLocationMixin(canReportLocation: self, buttonParentView: buttonStack, indexInView: 2)
            userTrackingMapMixin = UserTrackingMapMixin(userTrackingMap: self, buttonParentView: buttonStack, indexInView: 1, scheme: scheme)
            hasMapSearchMixin = HasMapSearchMixin(hasMapSearch: self, rootView: buttonStack, indexInView: 0, navigationController: self.navigationController, scheme: self.scheme)
            userHeadingDisplayMixin = UserHeadingDisplayMixin(userHeadingDisplay: self, mapStack: mapStack, scheme: scheme)
            staticLayerMapMixin = StaticLayerMapMixin(staticLayerMap: self)
            geoPackageLayerMapMixin = GeoPackageLayerMapMixin(geoPackageLayerMap: self)
            feedsMapMixin = FeedsMapMixin(feedsMap: self)
            onlineLayerMapMixin = OnlineLayerMapMixin()
//            mapMixins.append(filteredObservationsMapMixin!)
            mapMixins.append(filteredUsersMapMixin!)
            mapMixins.append(bottomSheetMixin!)
            mapMixins.append(persistedMapStateMixin!)
            mapMixins.append(hasMapSettingsMixin!)
            mapMixins.append(hasMapSearchMixin!)
            mapMixins.append(canCreateObservationMixin!)
            mapMixins.append(canReportLocationMixin!)
            mapMixins.append(userTrackingMapMixin!)
            mapMixins.append(userHeadingDisplayMixin!)
            mapMixins.append(staticLayerMapMixin!)
            mapMixins.append(geoPackageLayerMapMixin!)
            mapMixins.append(feedsMapMixin!)
            mapMixins.append(onlineLayerMapMixin!)

            if let observationsTileRepository = RepositoryManager.shared.observationsTileRepository,
               let observationsMapFeatureRepository = RepositoryManager.shared.observationsMapFeatureRepository
            {
                observationMap = ObservationsMap(
                    repository: observationsTileRepository,
                    mapFeatureRepository: observationsMapFeatureRepository
                )
                mapMixins.append(observationMap!)
            }
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
    
    func viewObservation(_ observation: Observation) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let ovc = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme)
        navigationController?.pushViewController(ovc, animated: true)
    }
    
    func onSearchResultSelected(result: GeocoderResult) {
        // no-op
    }
}
