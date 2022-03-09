//
//  MageSplitViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 9/7/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class MageSplitViewController : UISplitViewController {
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
        
        if let masterViewController = self.masterViewController {
            masterViewController.navigationBar.barTintColor = containerScheme.colorScheme.primaryColorVariant;
            masterViewController.navigationBar.tintColor = containerScheme.colorScheme.onPrimaryColor
            masterViewController.navigationBar.titleTextAttributes =
                [.foregroundColor:containerScheme.colorScheme.onPrimaryColor];
        
            masterViewController.navigationBar.prefersLargeTitles = false;
            masterViewController.navigationItem.largeTitleDisplayMode = .never;
        }
        
        if let detailViewController = self.detailViewController {
            detailViewController.navigationBar.barTintColor = containerScheme.colorScheme.primaryColorVariant;
            detailViewController.navigationBar.tintColor = containerScheme.colorScheme.onPrimaryColor;
            detailViewController.navigationBar.titleTextAttributes =
                [.foregroundColor :containerScheme.colorScheme.onPrimaryColor];
            
            detailViewController.navigationBar.prefersLargeTitles = false;
            detailViewController.navigationItem.largeTitleDisplayMode = .never;
        }
        
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
    func selectedAttachment(_ attachment: Attachment!) {
        if let attachmentCoordinator = self.attachmentCoordinator {
            attachmentCoordinator.setAttachment(attachment: attachment);
        } else if let nav = self.mapViewController?.navigationController {
            self.attachmentCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme)
            self.childCoordinators.append(self.attachmentCoordinator!);
            self.attachmentCoordinator?.start();
        }
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        if let nav = self.mapViewController?.navigationController {
            self.attachmentCoordinator = AttachmentViewCoordinator(rootViewController: nav, url: unsentAttachment["localPath"] as! URL, contentType: unsentAttachment["contentType"] as! String, delegate: self, scheme: self.scheme)
            self.attachmentCoordinator?.start();
            self.childCoordinators.append(self.attachmentCoordinator!);
        }
    }
    
    func selectedNotCachedAttachment(_ attachment: Attachment!, completionHandler handler: ((Bool) -> Void)!) {
        
    }
    
    func feedItemSelected(_ feedItem: FeedItem) {
        let feedItemViewController: FeedItemViewController = FeedItemViewController(feedItem: feedItem, scheme: self.scheme!);
        self.masterViewController?.pushViewController(feedItemViewController, animated: true);
    }
    
    func selectedObservation(_ observation: Observation!) {
        let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: self.scheme!);
        self.masterViewController?.pushViewController(observationViewController, animated: true);
    }
    
    func selectedObservation(_ observation: Observation!, region: MKCoordinateRegion) {
        let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: self.scheme!);
        self.masterViewController?.pushViewController(observationViewController, animated: true);    }
    
    func observationDetailSelected(_ observation: Observation!) {
        let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: self.scheme!);
        self.masterViewController?.pushViewController(observationViewController, animated: true);
    }
    
    func selectedUser(_ user: User!) {
        let userViewController: UserViewController = UserViewController(user: user, scheme: self.scheme!);
        self.masterViewController?.pushViewController(userViewController, animated: true);
    }
    
    func selectedUser(_ user: User!, region: MKCoordinateRegion) {
        let userViewController: UserViewController = UserViewController(user: user, scheme: self.scheme!);
        self.masterViewController?.pushViewController(userViewController, animated: true);
    }
    
    func userDetailSelected(_ user: User!) {
        let userViewController: UserViewController = UserViewController(user: user, scheme: self.scheme!);
        self.masterViewController?.pushViewController(userViewController, animated: true);
    }
    
    func viewObservation(_ observation: Observation) {
        let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: self.scheme!);
        self.masterViewController?.pushViewController(observationViewController, animated: true);
    }
    
    func viewUser(_ user: User) {
        let userViewController: UserViewController = UserViewController(user: user, scheme: self.scheme!);
        self.masterViewController?.pushViewController(userViewController, animated: true);
    }

}
