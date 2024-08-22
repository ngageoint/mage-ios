//
//  MageSplitViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 9/7/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class MageSplitViewController : UISplitViewController {
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
        
        self.sideBarController = MageSideBarController(scheme: self.scheme);
        self.masterViewController = UINavigationController(rootViewController: self.sideBarController!);

        self.mapViewController = MapViewController_iPad(delegate: nil, scheme: self.scheme!);
        self.detailViewController = UINavigationController(rootViewController: self.mapViewController!)

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
