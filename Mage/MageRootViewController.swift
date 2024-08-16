//
//  MageRootViewController.m
//  Mage
//

import Foundation
import Kingfisher
import MaterialViews

@objc class MageRootViewController : UITabBarController {
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    var profileTabBarItem: UITabBarItem?;
    var moreTabBarItem: UITabBarItem?;
    var moreTableViewDelegate: UITableViewDelegate?;
    var scheme: MDCContainerScheming?;
    var feedViewControllers: [UINavigationController] = [];
    var mapRequestFocusObserver: Any?
    var snackbarNotificationObserver: Any?
    var attachmentViewCoordinator: AttachmentViewCoordinator?
    
    private lazy var offlineObservationManager: MageOfflineObservationManager = {
        let manager: MageOfflineObservationManager = MageOfflineObservationManager(delegate: self);
        return manager;
    }();
    
    private lazy var settingsTabItem: UINavigationController = {
        let svc = SettingsTableViewController(scheme: scheme)!;
        let nc = UINavigationController(rootViewController: svc);
        nc.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 4);
        return nc;
    }();
    
    private lazy var locationsTab: UINavigationController = {
        let locationTableViewController = LocationListWrapperViewController(scheme: scheme, router: MageRouter())
        
        let nc = UINavigationController()
        nc.tabBarItem = UITabBarItem(title: "People", image: UIImage(systemName: "person.2.fill"), tag: 2);
        nc.pushViewController(locationTableViewController, animated: false)

        return nc
    }()
    
    func selectedAttachment(_ attachmentUri: URL!, navigationController: UINavigationController) {
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: navigationController, attachment: attachment, delegate: self, scheme: scheme);
                attachmentViewCoordinator?.start();
            }
        }
    }
    
    private lazy var observationsTab: UINavigationController = {
//        let observationTableViewController = ObservationListWrapperViewController(scheme: scheme)
        let observationTableViewController = ObservationListNavStack(scheme: scheme)
        let nc = UINavigationController(rootViewController: observationTableViewController);
        nc.tabBarItem = UITabBarItem(title: "Observations", image: UIImage(named: "observations"), tag: 1);
        return nc;
    }()
    
    private lazy var mapTab: UINavigationController = {
        let mapViewController: MageMapViewController = MageMapViewController(scheme: scheme)
        let nc = UINavigationController(rootViewController: mapViewController);
        nc.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map.fill"), tag: -1);
        return nc;
    }()
    
    private lazy var meTab: UINavigationController? = {
        guard let user = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()) else {
            return nil
        }
//        return nil
        let uvc = UserViewWrapperViewController(userUri: user.objectID.uriRepresentation(), scheme: scheme, router: MageRouter())
        let nc = UINavigationController(rootViewController: uvc);
        nc.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.fill"), tag: 3);
        return nc;
    }()
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc public init(containerScheme: MDCContainerScheming?) {
        self.scheme = containerScheme;
        super.init(nibName: nil, bundle: nil);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        self.view.tintColor = scheme.colorScheme.primaryColor.withAlphaComponent(0.87);
        
        if let topViewController = self.moreNavigationController.topViewController {
            if let tableView = topViewController.view as? UITableView {
                tableView.tintColor = scheme.colorScheme.primaryColor
                tableView.backgroundColor = scheme.colorScheme.backgroundColor
            }
        }
        
        self.view.backgroundColor = scheme.colorScheme.backgroundColor;
    }
    
    override func viewDidLoad() {
        Mage.singleton.startServices(initial: true);
        super.viewDidLoad();
        
        createOrderedTabs();
        
        self.delegate = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        applyTheme(withScheme: self.scheme);
        if let moreTableView = moreNavigationController.topViewController?.view as? UITableView {
            if let proxyDelegate = moreTableView.delegate {
                moreTableViewDelegate = MoreTableViewDelegate(proxyDelegate: proxyDelegate, containerScheme: scheme)
                moreTableView.delegate = moreTableViewDelegate
            }
        }
        offlineObservationManager.start()
        setServerConnectionStatus();
        UserDefaults.standard.addObserver(self, forKeyPath: "loginType" , options: .new, context: nil);
        
        mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { [weak self]  notification in
            self?.mapTab.popToRootViewController(animated: false);
            self?.selectedViewController = self?.mapTab;
            
        }
        
        snackbarNotificationObserver = NotificationCenter.default.addObserver(forName: .SnackbarNotification, object: nil, queue: .main, using: { notification in
            if let object = notification.object as? SnackbarNotification,
               let message = object.snackbarModel?.message
            {
                MDCSnackbarManager.default.show(MDCSnackbarMessage(text: message))
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        mapTab.viewControllers.removeAll()
        Mage.singleton.stopServices();
        offlineObservationManager.stop();
        offlineObservationManager.delegate = nil
        if let mapRequestFocusObserver = mapRequestFocusObserver {
            NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil);
        }
        
        if let snackbarNotificationObserver = snackbarNotificationObserver {
            NotificationCenter.default.removeObserver(snackbarNotificationObserver, name: .SnackbarNotification, object: nil);
        }
        self.delegate = nil
        UserDefaults.standard.removeObserver(self, forKeyPath: "loginType")
    }
    
    func createOrderedTabs() {
        var allTabs: [UIViewController] = self.viewControllers ?? [];
        allTabs.append(mapTab);
        allTabs.append(settingsTabItem);
        if let meTab = meTab {
            allTabs.append(meTab);
        }
        allTabs.append(locationsTab);
        allTabs.append(observationsTab);
        
        if let currentEventId = Server.currentEventId() {
            for feed in Feed.getEventFeeds(eventId: currentEventId) {
                let nc = createFeedViewController(feed: feed);
                allTabs.append(nc);
                feedViewControllers.append(nc);
            }
        }
        
        var orderedTabs: [UIViewController] = [];
        orderedTabs = allTabs.sorted { (controller, controller2) -> Bool in
            let position1 = UserDefaults.standard.object(forKey: "rootViewTabPosition\(controller.tabBarItem.tag)");
            let position2 = UserDefaults.standard.object(forKey: "rootViewTabPosition\(controller2.tabBarItem.tag)");
            if (position1 == nil && position2 == nil) {
                return controller.tabBarItem.tag < controller2.tabBarItem.tag;
            } else if (position1 == nil) {
                return false;
            } else if (position2 == nil) {
                return true;
            }
            return (position1 as! Int) < (position2 as! Int);
        }

        self.viewControllers = orderedTabs;
    }
    
    func createFeedViewController(feed: Feed) -> UINavigationController {
        let size = 24;
        let fvc = FeedItemsViewController(feed: feed, scheme: self.scheme);
        let nc = UINavigationController(rootViewController: fvc);
        nc.tabBarItem = UITabBarItem(title: feed.title, image: nil, tag: feed.tag!.intValue + 5);
        nc.tabBarItem.image = UIImage(systemName: "dot.radiowaves.up.forward")?.aspectResize(to: CGSize(width: size, height: size));

        if let url: URL = feed.tabIconURL {
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
                    let image: UIImage = value.image.aspectResize(to: CGSize(width: size, height: size));
                    nc.tabBarItem.image = image;
                case .failure(let error):
                    print(error);
                }
            }
        }
        return nc;
    }
    
    func setServerConnectionStatus() {
        if ("offline" == UserDefaults.standard.loginType) {
            moreTabBarItem?.badgeValue = "!";
            moreTabBarItem?.badgeColor = UIColor.systemOrange;
        } else {
            moreTabBarItem?.badgeValue = nil;
            moreTabBarItem?.badgeColor = nil;
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        setServerConnectionStatus();
    }
}

extension MageRootViewController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didEndCustomizing items: [UITabBarItem], changed: Bool) {
        if changed {
            for (i, viewController) in viewControllers!.enumerated() {
                UserDefaults.standard.set(i, forKey: "rootViewTabPosition\(viewController.tabBarItem.tag)")
            }
        }
    }
}

extension MageRootViewController: OfflineObservationDelegate {
    func offlineObservationsDidChangeCount(_ count: Int) {
        if (count > 0) {
            self.profileTabBarItem?.badgeValue = count > 99 ? "99+" : String(count);
        } else {
            self.profileTabBarItem?.badgeValue = nil;
        }
    }
}

extension MageRootViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil;
    }
}
