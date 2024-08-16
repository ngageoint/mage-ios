//
//  MageSplitViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 9/7/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class MageSplitViewController : UISplitViewController {
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    var bottomSheet: MDCBottomSheetController?
    
    var startStraightLineNavigationObserver: AnyObject?

    var scheme: MDCContainerScheming?;
    var masterViewController: UINavigationController?;
    var detailViewController: UINavigationController?;
    var sideBarController: MageSideBarController?;
    var mapViewController: MapViewController_iPad?;
    var masterViewButton: UIBarButtonItem?;
    var mapCalloutDelegates: [Any] = [];
    var childCoordinators: [NSObject] = [];
    var attachmentCoordinator: AttachmentViewCoordinator?;
    
    var router = MageRouter()
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc convenience public init(containerScheme: MDCContainerScheming) {
        self.init(frame: CGRect.zero);
        self.scheme = containerScheme;
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme;
        
        self.view.backgroundColor = containerScheme.colorScheme.surfaceColor;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.maximumPrimaryColumnWidth = 426;
        self.preferredPrimaryColumnWidthFraction = 1.0;
        self.preferredDisplayMode = .oneBesideSecondary;
        
        Mage.singleton.startServices(initial: true);
        
        self.delegate = self;
        
        self.sideBarController = MageSideBarController(containerScheme: self.scheme!);
        self.sideBarController!.delegate = self;
        self.masterViewController = UINavigationController(rootViewController: self.sideBarController!);

        self.mapViewController = MapViewController_iPad(delegate: self, scheme: self.scheme!);
        self.detailViewController = UINavigationController(rootViewController: self.mapViewController!);
        
        self.viewControllers = [self.masterViewController!, self.detailViewController!]
        
        self.applyTheme(withContainerScheme: self.scheme);
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        
        self.masterViewButton = self.displayModeButtonItem;
        
        if (!UIWindow.isLandscape) {
            ensureButtonVisible();
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
            guard let _: StraightLineNavigationNotification = notification.object as? StraightLineNavigationNotification else {
                return;
            }
            self.detailViewController?.popToRootViewController(animated: false);
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        if let startStraightLineNavigationObserver = startStraightLineNavigationObserver {
            NotificationCenter.default.removeObserver(startStraightLineNavigationObserver)
        }
        startStraightLineNavigationObserver = nil
    }
    
    func ensureButtonVisible() {
        self.masterViewButton?.title = self.sideBarController?.title;
        self.masterViewButton?.style = .plain;
        self.mapViewController?.navigationItem.leftBarButtonItem = self.masterViewButton;
    }
    
    
    
}

extension MageSplitViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        if let coordinatorIndex = self.childCoordinators.firstIndex(of: coordinator) {
            self.childCoordinators.remove(at: coordinatorIndex)
        }
        attachmentCoordinator = nil;
    }
}

extension MageSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        self.masterViewButton = svc.displayModeButtonItem;
        if (displayMode == .oneOverSecondary) {
            ensureButtonVisible();
        } else if (displayMode == .secondaryOnly) {
            ensureButtonVisible();
        } else if (displayMode == .oneBesideSecondary) {
            ensureButtonVisible();
        }
    }
}

extension MageSplitViewController: ObservationActionsDelegate & UserActionsDelegate & AttachmentSelectionDelegate & FeedItemSelectionDelegate & ObservationSelectionDelegate & UserSelectionDelegate {
    func selectedAttachment(_ attachmentUri: URL!) {
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                if let attachmentCoordinator = self.attachmentCoordinator {
                    attachmentCoordinator.setAttachment(attachment: attachment);
                } else if let nav = self.mapViewController?.navigationController {
                    self.attachmentCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme)
                    self.childCoordinators.append(self.attachmentCoordinator!);
                    self.attachmentCoordinator?.start();
                }
            }
        }
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        if let nav = self.mapViewController?.navigationController {
            self.attachmentCoordinator = AttachmentViewCoordinator(rootViewController: nav, url: unsentAttachment["localPath"] as! URL, contentType: unsentAttachment["contentType"] as! String, delegate: self, scheme: self.scheme)
            self.attachmentCoordinator?.start();
            self.childCoordinators.append(self.attachmentCoordinator!);
        }
    }
    
    func selectedNotCachedAttachment(_ attachmentUri: URL!, completionHandler handler: ((Bool) -> Void)!) {
        
    }
    
    func feedItemSelected(_ feedItem: FeedItem) {
        let feedItemViewController: FeedItemViewController = FeedItemViewController(feedItem: feedItem, scheme: self.scheme!);
        self.masterViewController?.pushViewController(feedItemViewController, animated: true);
    }
    
    func selectedObservation(_ observation: Observation!) {
        let observationView = ObservationFullView(viewModel: ObservationViewViewModel(uri: observation.objectID.uriRepresentation())) { favoritesModel in
            guard let favoritesModel = favoritesModel,
                  let favoriteUsers = favoritesModel.favoriteUsers
            else {
                return
            }
            self.showFavorites(userIds: favoriteUsers)
        } moreActions: {
            let actionsSheet: ObservationActionsSheetController = ObservationActionsSheetController(observation: observation, delegate: self);
            actionsSheet.applyTheme(withContainerScheme: self.scheme);
            self.bottomSheet = MDCBottomSheetController(contentViewController: actionsSheet);
            self.navigationController?.present(self.bottomSheet!, animated: true, completion: nil);
        }
    selectedUnsentAttachment: { localPath, contentType in
            
        }
    .environmentObject(router)

        let ovc2 = SwiftUIViewController(swiftUIView: observationView)
        self.masterViewController?.pushViewController(ovc2, animated: true)
    }
    
    func selectedObservation(_ observation: Observation!, region: MKCoordinateRegion) {
        selectedObservation(observation)
    }
    
    func observationDetailSelected(_ observation: Observation!) {
        selectedObservation(observation)
    }
    
    func selectedUser(_ user: User!) {
        let userViewController: UserViewController = UserViewController(userModel: UserModel(user: user), scheme: self.scheme!, router: router);
        self.masterViewController?.pushViewController(userViewController, animated: true);
    }
    
    func selectedUser(_ user: User!, region: MKCoordinateRegion) {
        let userViewController: UserViewController = UserViewController(userModel: UserModel(user: user), scheme: self.scheme!, router: router);
        self.masterViewController?.pushViewController(userViewController, animated: true);
    }
    
    func userDetailSelected(_ user: User!) {
        let userViewController: UserViewController = UserViewController(userModel: UserModel(user: user), scheme: self.scheme!, router: router);
        self.masterViewController?.pushViewController(userViewController, animated: true);
    }
    
    func viewObservation(_ observation: Observation) {
        selectedObservation(observation)
    }
    
    func viewUser(_ user: User) {
        if let uvc = self.masterViewController?.topViewController as? UserViewController, uvc.user == user {
            // already showing
            return
        }
        let userViewController: UserViewController = UserViewController(userModel: UserModel(user: user), scheme: self.scheme!, router: router);
        self.masterViewController?.pushViewController(userViewController, animated: true);
    }
    
    func showFavorites(userIds: [String]) {
        if (userIds.count != 0) {
            let locationViewController = LocationsTableViewController(userIds: userIds, actionsDelegate: nil, scheme: scheme, router: router);
            locationViewController.title = "Favorited By";
            self.masterViewController?.pushViewController(locationViewController, animated: true);
        }
    }

}

extension MageSplitViewController: ObservationEditDelegate {
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
}
