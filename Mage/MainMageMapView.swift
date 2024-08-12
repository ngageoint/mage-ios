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

class MainMageMapView: 
    MageMapView,
        FilteredObservationsMap,
        FilteredUsersMap,
        BottomSheetEnabled,
        MapDirections,
        HasMapSettings,
        HasMapSearch,
        CanCreateObservation,
        CanReportLocation,
        UserHeadingDisplay,
        UserTrackingMap,
        StaticLayerMap,
        GeoPackageLayerMap,
        FeedsMap
{
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    @Injected(\.feedItemRepository)
    var feedItemRepository: FeedItemRepository
    
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    // this initializes the location manager, this should go somewhere else in the future
    @Injected(\.currentLocationRepository)
    var currentLocationRepository: CurrentLocationRepository
    
    var childCoordinators: [NSObject] = [];
    
    weak var navigationController: UINavigationController?
    weak var viewController: UIViewController?
    var bottomSheet: MDCBottomSheetController?
    var attachmentViewCoordinator: AttachmentViewCoordinator?;

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
        // this initializes the location manager, this should go somewhere else in the future
        _ = currentLocationRepository.getLastLocation()
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
        viewController = nil
//        navigationController = nil
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
            
            persistedMapStateMixin = PersistedMapStateMixin()
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

            observationMap = ObservationsMap()
            mapMixins.append(observationMap!)
        }
        
        initiateMapMixins()
        
        viewObservationNotificationObserver = NotificationCenter.default.addObserver(forName: .ViewObservation, object: nil, queue: .main) { [weak self] notification in
            self?.bottomSheetMixin?.dismissBottomSheet()
            if let observation = notification.object as? URL {
                Task {
                    await self?.viewObservation(observation)
                }
            }
        }

        viewUserNotificationObserver = NotificationCenter.default.addObserver(forName: .ViewUser, object: nil, queue: .main) { [weak self] notification in
            self?.bottomSheetMixin?.dismissBottomSheet()
            if let user = notification.object as? URL {
                Task {
                    await self?.viewUserUri(user)
                }
            }
        }

        viewFeedItemNotificationObserver = NotificationCenter.default.addObserver(forName: .ViewFeedItem, object: nil, queue: .main) { [weak self] notification in
            self?.bottomSheetMixin?.dismissBottomSheet()
            if let feedItemUri = notification.object as? URL {
                Task {
                    await self?.viewFeedItemUri(feedItemUri)
                }
            }
        }
    }
    
    func viewUser(_ user: User) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let uvc = UserViewController(userModel: UserModel(user: user), scheme: scheme)
        navigationController?.pushViewController(uvc, animated: true)
    }
    
    func viewFeedItem(_ feedItem: FeedItem) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let fivc = FeedItemViewController(feedItem: feedItem, scheme: scheme)
        navigationController?.pushViewController(fivc, animated: true)
    }
    
    @MainActor
    func viewFeedItemUri(_ feedItemUri: URL) async {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        if let feedItem = await feedItemRepository.getFeedItem(feedItemrUri: feedItemUri) {
            let fivc = FeedItemViewController(feedItem: feedItem, scheme: scheme)
            navigationController?.pushViewController(fivc, animated: true)
        }
    }
    
    @MainActor
    func viewUserUri(_ userUri: URL) async {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        if let user = await userRepository.getUser(userUri: userUri) {
            let uvc = UserViewController(userModel: user, scheme: scheme)
            navigationController?.pushViewController(uvc, animated: true)
        }
    }
    
    @MainActor
    func viewObservation(_ observationUri: URL) async {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let observationView = ObservationFullView(viewModel: ObservationViewViewModel(uri: observationUri)) { favoritesModel in
            guard let favoritesModel = favoritesModel,
                  let favoriteUsers = favoritesModel.favoriteUsers
            else {
                return
            }
            self.showFavorites(userIds: favoriteUsers)
        } moreActions: {
            Task {
                if let observation = await self.observationRepository.getObservation(observationUri: observationUri) {
                    let actionsSheet: ObservationActionsSheetController = ObservationActionsSheetController(observation: observation, delegate: self);
                    actionsSheet.applyTheme(withContainerScheme: self.scheme);
                    self.bottomSheet = MDCBottomSheetController(contentViewController: actionsSheet);
                    self.navigationController?.present(self.bottomSheet!, animated: true, completion: nil);
                }
            }
        } editObservation: { observationUri in
            Task {
                guard let observation = await self.observationRepository.getObservation(observationUri: observationUri) else {
                    return;
                }
                let observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: observation);
                observationEditCoordinator.applyTheme(withContainerScheme: self.scheme);
                observationEditCoordinator.start();
                self.childCoordinators.append(observationEditCoordinator)

            }
        } selectedAttachment: { attachmentUri in
            self.selectedAttachment(attachmentUri)
        } selectedUnsentAttachment: { localPath, contentType in
            
        }

        let ovc2 = SwiftUIViewController(swiftUIView: observationView)
        navigationController?.pushViewController(ovc2, animated: true)
    }
    
    func onSearchResultSelected(result: GeocoderResult) {
        // no-op
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        NSLog("Mage map view region did change")
        let zoomLevel = mapView.zoomLevel
        
        mapStateRepository.zoom = Int(zoomLevel)
        mapStateRepository.region = mapView.region
    }
}

extension MainMageMapView: ObservationEditDelegate, ObservationActionsDelegate {
    func editCancel(_ coordinator: NSObject) {
        removeChildCoordinator(coordinator);
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        removeChildCoordinator(coordinator);
    }
    
    func removeChildCoordinator(_ coordinator: NSObject) {
        if let index = self.childCoordinators.firstIndex(where: { (child) -> Bool in
            return coordinator == child;
        }) {
            self.childCoordinators.remove(at: index);
        }
    }
    
    func viewObservation(_ observation: Observation) {
        Task {
            await viewObservation(observation.objectID.uriRepresentation())
        }
    }
    
    func favoriteObservation(_ observation: Observation, completion: ((Observation?) -> Void)?) {
        ObservationActions.favorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: userRepository.getCurrentUser()?.remoteId)()
    }
    
    func copyLocation(_ locationString: String) {
        UIPasteboard.general.string = locationString;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location \(locationString) copied to clipboard"))
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView?) {
        guard let location = observation.location else {
            return;
        }
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: UIImage(named: "defaultMarker"), coordinate: location.coordinate))
        }));
        
        if let viewController = self.viewController {
            ObservationActionHandler.getDirections(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, title: "Observation", viewController: viewController, extraActions: extraActions, sourceView: sourceView);
        }
    }
    
    func deleteObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        if let viewController = self.viewController {
            ObservationActionHandler.deleteObservation(observation: observation, viewController: viewController) { (success, error) in
                self.navigationController?.popViewController(animated: true);
            }
        }
    }
    
    func cancelAction() {
        bottomSheet?.dismiss(animated: true, completion: nil);
    }
    
    func showFavorites(userIds: [String]) {
        if (userIds.count != 0) {
            let locationViewController = LocationsTableViewController(userIds: userIds, actionsDelegate: nil, scheme: scheme);
            locationViewController.title = "Favorited By";
            self.navigationController?.pushViewController(locationViewController, animated: true);
        }
    }
}

extension MainMageMapView: AttachmentSelectionDelegate {
    func selectedAttachment(_ attachmentUri: URL!) {
        guard let nav = self.navigationController else {
            return;
        }
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme);
                attachmentViewCoordinator?.start();
            }
        }
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        guard let nav = self.navigationController else {
            return;
        }
        attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, url: URL(fileURLWithPath: unsentAttachment["localPath"] as! String), contentType: unsentAttachment["contentType"] as! String, delegate: self, scheme: scheme);
        attachmentViewCoordinator?.start();
    }
    
    func selectedNotCachedAttachment(_ attachmentUri: URL!, completionHandler handler: ((Bool) -> Void)!) {
        guard let nav = self.navigationController else {
            return;
        }
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme);
                attachmentViewCoordinator?.start();
            }
        }
    }
}

extension MainMageMapView: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil;
    }
}
