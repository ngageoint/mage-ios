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
    
    var router: MageRouter
    
    // this initializes the location manager, this should go somewhere else in the future
    @Injected(\.currentLocationRepository)
    var currentLocationRepository: CurrentLocationRepository
    
    var childCoordinators: [NSObject] = [];
    
    weak var navigationController: UINavigationController?
    weak var viewController: UIViewController?
    var bottomSheet: MDCBottomSheetController?
    var attachmentViewCoordinator: AttachmentViewCoordinator?;

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
    private var observationImportObserver: NSObjectProtocol?
    private var didSetupObservationImportStatusView = false
    private var isObservationImportDeterminateActive = false
    private var mapFeatureUpdateObserver: NSObjectProtocol?
    private var didSetupMapFeatureUpdateStatusView = false

    private lazy var observationImportStatusView: UIView = {
        let statusView = UIView.newAutoLayout()
        statusView.backgroundColor = scheme?.colorScheme.surfaceColor.withAlphaComponent(0.92) ?? UIColor.systemBackground.withAlphaComponent(0.92)
        statusView.layer.cornerRadius = 10
        statusView.isHidden = true
        statusView.alpha = 0
        statusView.isUserInteractionEnabled = false
        return statusView
    }()

    private lazy var observationImportLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = scheme?.typographyScheme.body2 ?? UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = scheme?.colorScheme.onSurfaceColor
        return label
    }()

    private lazy var observationImportProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.15)
        progressView.progressTintColor = scheme?.colorScheme.primaryColor
        return progressView
    }()

    private lazy var observationImportStackView: UIStackView = {
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()

    private lazy var mapFeatureUpdateStatusView: UIView = {
        let statusView = UIView.newAutoLayout()
        statusView.backgroundColor = scheme?.colorScheme.surfaceColor.withAlphaComponent(0.92) ?? UIColor.systemBackground.withAlphaComponent(0.92)
        statusView.layer.cornerRadius = 10
        statusView.isHidden = true
        statusView.alpha = 0
        statusView.isUserInteractionEnabled = false
        return statusView
    }()

    private lazy var mapFeatureUpdateLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = scheme?.typographyScheme.body2 ?? UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = scheme?.colorScheme.onSurfaceColor
        return label
    }()

    private lazy var mapFeatureUpdateProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.15)
        progressView.progressTintColor = scheme?.colorScheme.primaryColor
        return progressView
    }()

    private lazy var mapFeatureUpdateStackView: UIStackView = {
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()
    
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
    
    public init(viewController: UIViewController?, navigationController: UINavigationController?, scheme: MDCContainerScheming?, router: MageRouter) {
        self.viewController = viewController
        self.navigationController = navigationController
        self.router = router
        super.init(scheme: scheme)
        // this initializes the location manager, this should go somewhere else in the future
        _ = currentLocationRepository.getLastLocation()
        observationImportObserver = NotificationCenter.default.addObserver(
            forName: .ObservationImportProgress,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleObservationImportProgress(notification)
        }
        mapFeatureUpdateObserver = NotificationCenter.default.addObserver(
            forName: .MapFeatureUpdateProgress,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleMapFeatureUpdateProgress(notification)
        }
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
        if let observationImportObserver {
            NotificationCenter.default.removeObserver(observationImportObserver)
        }
        if let mapFeatureUpdateObserver {
            NotificationCenter.default.removeObserver(mapFeatureUpdateObserver)
        }
        viewController = nil
    }
    
    override func removeFromSuperview() {
        cleanupMapMixins()
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
            buttonStack.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 10)
            buttonStack.autoPinEdge(toSuperviewSafeArea: .top, withInset: 10)
            setupObservationImportStatusViewIfNeeded()
            setupMapFeatureUpdateStatusViewIfNeeded()
            
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
            Task {
                await self?.bottomSheetMixin?.dismissBottomSheet()
                if let observation = notification.object as? URL {
                    await self?.router.appendRoute(ObservationRoute.detail(uri: observation))
                }
            }
        }

        viewUserNotificationObserver = NotificationCenter.default.addObserver(forName: .ViewUser, object: nil, queue: .main) { [weak self] notification in
            Task {
                await self?.bottomSheetMixin?.dismissBottomSheet()
                if let user = notification.object as? URL {
                    await self?.router.appendRoute(UserRoute.detail(uri: user))
                }
            }
        }

        viewFeedItemNotificationObserver = NotificationCenter.default.addObserver(forName: .ViewFeedItem, object: nil, queue: .main) { [weak self] notification in
            Task {
                await self?.bottomSheetMixin?.dismissBottomSheet()
                if let feedItemUri = notification.object as? URL {
                    await self?.viewFeedItemUri(feedItemUri)
                }
            }
        }
    }

    private func setupObservationImportStatusViewIfNeeded() {
        guard !didSetupObservationImportStatusView else { return }
        didSetupObservationImportStatusView = true
        observationImportStackView.addArrangedSubview(observationImportLabel)
        observationImportStackView.addArrangedSubview(observationImportProgressView)
        observationImportStatusView.addSubview(observationImportStackView)
        addSubview(observationImportStatusView)
        observationImportStatusView.autoPinEdge(toSuperviewSafeArea: .top, withInset: 200)
        observationImportStatusView.autoPinEdge(toSuperviewEdge: .leading, withInset: 16)
        observationImportStatusView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16)
        observationImportStackView.autoPinEdgesToSuperviewEdges(
            with: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )
    }

    private func setupMapFeatureUpdateStatusViewIfNeeded() {
        guard !didSetupMapFeatureUpdateStatusView else { return }
        didSetupMapFeatureUpdateStatusView = true
        mapFeatureUpdateStackView.addArrangedSubview(mapFeatureUpdateLabel)
        mapFeatureUpdateStackView.addArrangedSubview(mapFeatureUpdateProgressView)
        mapFeatureUpdateStatusView.addSubview(mapFeatureUpdateStackView)
        addSubview(mapFeatureUpdateStatusView)
        mapFeatureUpdateStatusView.autoPinEdge(toSuperviewSafeArea: .top, withInset: 260)
        mapFeatureUpdateStatusView.autoPinEdge(toSuperviewEdge: .leading, withInset: 16)
        mapFeatureUpdateStatusView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16)
        mapFeatureUpdateStackView.autoPinEdgesToSuperviewEdges(
            with: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )
    }

    private func handleObservationImportProgress(_ notification: Notification) {
        setupObservationImportStatusViewIfNeeded()
        guard
            let userInfo = notification.userInfo,
            let stateValue = userInfo[ObservationImportProgress.stateKey] as? String,
            let state = ObservationImportProgressState(rawValue: stateValue)
        else {
            return
        }
        let message = userInfo[ObservationImportProgress.messageKey] as? String
        let current = userInfo[ObservationImportProgress.currentKey] as? Int ?? 0
        let total = userInfo[ObservationImportProgress.totalKey] as? Int ?? 0

        switch state {
        case .indeterminate:
            guard !isObservationImportDeterminateActive else { return }
            showObservationImportStatus(
                message: message ?? "Fetching observations...",
                progress: 0,
                animated: false
            )
        case .progress:
            isObservationImportDeterminateActive = true
            let fallbackMessage = total > 0
            ? "Processing observations \(current) of \(total)"
            : "Processing observations..."
            let progressValue: Float = total > 0 ? Float(current) / Float(total) : 0
            showObservationImportStatus(
                message: message ?? fallbackMessage,
                progress: progressValue,
                animated: true
            )
        case .finished:
            isObservationImportDeterminateActive = false
            hideObservationImportStatus()
        }
    }

    private func showObservationImportStatus(message: String, progress: Float, animated: Bool) {
        observationImportLabel.text = message
        observationImportProgressView.setProgress(progress, animated: animated)
        guard observationImportStatusView.isHidden else { return }
        observationImportStatusView.alpha = 0
        observationImportStatusView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.observationImportStatusView.alpha = 1
        }
    }

    private func hideObservationImportStatus() {
        guard !observationImportStatusView.isHidden else { return }
        UIView.animate(withDuration: 0.2, animations: {
            self.observationImportStatusView.alpha = 0
        }, completion: { _ in
            self.observationImportStatusView.isHidden = true
        })
    }

    private func handleMapFeatureUpdateProgress(_ notification: Notification) {
        setupMapFeatureUpdateStatusViewIfNeeded()
        guard
            let userInfo = notification.userInfo,
            let stateValue = userInfo[MapFeatureUpdateProgress.stateKey] as? String,
            let state = MapFeatureUpdateProgressState(rawValue: stateValue),
            let operationValue = userInfo[MapFeatureUpdateProgress.operationKey] as? String,
            let operation = MapFeatureUpdateOperation(rawValue: operationValue)
        else {
            return
        }

        let message = userInfo[MapFeatureUpdateProgress.messageKey] as? String
        let current = userInfo[MapFeatureUpdateProgress.currentKey] as? Int ?? 0
        let total = userInfo[MapFeatureUpdateProgress.totalKey] as? Int ?? 0
        let fallbackMessage = mapFeatureUpdateFallbackMessage(operation: operation, current: current, total: total)

        switch state {
        case .indeterminate:
            showMapFeatureUpdateStatus(
                message: message ?? fallbackMessage,
                progress: 0,
                animated: false
            )
        case .progress:
            let progressValue: Float = total > 0 ? Float(current) / Float(total) : 0
            showMapFeatureUpdateStatus(
                message: message ?? fallbackMessage,
                progress: progressValue,
                animated: true
            )
        case .finished:
            hideMapFeatureUpdateStatus()
        }
    }

    private func mapFeatureUpdateFallbackMessage(
        operation: MapFeatureUpdateOperation,
        current: Int,
        total: Int
    ) -> String {
        let hasTotal = total > 0
        switch operation {
        case .addAnnotations:
            return hasTotal ? "Adding annotations \(current) of \(total)" : "Adding annotations..."
        case .removeAnnotations:
            return hasTotal ? "Removing annotations \(current) of \(total)" : "Removing annotations..."
        case .addOverlays:
            return hasTotal ? "Adding overlays \(current) of \(total)" : "Adding overlays..."
        case .removeOverlays:
            return hasTotal ? "Removing overlays \(current) of \(total)" : "Removing overlays..."
        }
    }

    private func showMapFeatureUpdateStatus(message: String, progress: Float, animated: Bool) {
        mapFeatureUpdateLabel.text = message
        mapFeatureUpdateProgressView.setProgress(progress, animated: animated)
        guard mapFeatureUpdateStatusView.isHidden else { return }
        mapFeatureUpdateStatusView.alpha = 0
        mapFeatureUpdateStatusView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.mapFeatureUpdateStatusView.alpha = 1
        }
    }

    private func hideMapFeatureUpdateStatus() {
        guard !mapFeatureUpdateStatusView.isHidden else { return }
        UIView.animate(withDuration: 0.2, animations: {
            self.mapFeatureUpdateStatusView.alpha = 0
        }, completion: { _ in
            self.mapFeatureUpdateStatusView.isHidden = true
        })
    }
    
    func viewFeedItem(_ feedItem: FeedItem) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let fivc = FeedItemViewController(feedItem: feedItem, scheme: scheme)
        navigationController?.pushViewController(fivc, animated: true)
    }
    
    @MainActor
    func viewFeedItemUri(_ feedItemUri: URL) async {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        if let feedItem = await feedItemRepository.getFeedItem(feedItemUri: feedItemUri) {
            let fivc = FeedItemViewController(feedItem: feedItem, scheme: scheme)
            navigationController?.pushViewController(fivc, animated: true)
        }
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
