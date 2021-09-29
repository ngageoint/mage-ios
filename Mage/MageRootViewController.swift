//
//  MageRootViewController.m
//  Mage
//

import Foundation
import Kingfisher

@objc class MageRootViewController : UITabBarController {
    
    var profileTabBarItem: UITabBarItem?;
    var moreTabBarItem: UITabBarItem?;
    var moreTableViewDelegate: UITableViewDelegate?;
    var scheme: MDCContainerScheming!;
    var feedViewControllers: [UINavigationController] = [];
    
    private lazy var offlineObservationManager: MageOfflineObservationManager = {
        let manager: MageOfflineObservationManager = MageOfflineObservationManager(delegate: self);
        return manager;
    }();
    
    private lazy var settingsTabItem: UINavigationController = {
        let svc = SettingsTableViewController(scheme: scheme)!;
        let nc = UINavigationController(rootViewController: svc);
        nc.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings_tab"), tag: 4);
        return nc;
    }();
    
    private lazy var locationsTab: UINavigationController = {
        let locationTableViewController: LocationsTableViewController = LocationsTableViewController(scheme: self.scheme);
        let nc = UINavigationController(rootViewController: locationTableViewController);
        nc.tabBarItem = UITabBarItem(title: "People", image: UIImage(named: "people"), tag: 2);
        return nc;
    }()
    
    private lazy var observationsTab: UINavigationController = {
        let observationTableViewController: ObservationTableViewController = ObservationTableViewController(scheme: self.scheme);
        let nc = UINavigationController(rootViewController: observationTableViewController);
        nc.tabBarItem = UITabBarItem(title: "Observations", image: UIImage(named: "observations"), tag: 1);
        return nc;
    }()
    
    private lazy var mapTab: UINavigationController = {
        let mapViewController: MapViewController = MapViewController(scheme: self.scheme);
        let nc = UINavigationController(rootViewController: mapViewController);
        nc.tabBarItem = UITabBarItem(title: "Map", image: UIImage(named: "map"), tag: 0);
        return nc;
    }()
    
    private lazy var meTab: UINavigationController = {
        let user = User.fetchCurrentUser(in: NSManagedObjectContext.mr_default())
        let uvc = UserViewController(user: user, scheme: self.scheme);
        let nc = UINavigationController(rootViewController: uvc);
        nc.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "me"), tag: 3);
        return nc;
    }()
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc public init(containerScheme: MDCContainerScheming) {
        self.scheme = containerScheme;
        super.init(nibName: nil, bundle: nil);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        if (scheme != nil) {
            self.scheme = scheme!;
        }
        self.tabBar.barTintColor = self.scheme.colorScheme.surfaceColor;
        self.tabBar.tintColor = self.scheme.colorScheme.primaryColor.withAlphaComponent(0.87);
        self.tabBar.unselectedItemTintColor = self.scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        self.view.tintColor = self.scheme.colorScheme.primaryColor.withAlphaComponent(0.87);
        
        setNavigationControllerAppearance(nc: self.moreNavigationController);
        setNavigationControllerAppearance(nc: mapTab);
        setNavigationControllerAppearance(nc: observationsTab);
        setNavigationControllerAppearance(nc: locationsTab);
        setNavigationControllerAppearance(nc: meTab);
        setNavigationControllerAppearance(nc: settingsTabItem);
        for navigationController in feedViewControllers {
            setNavigationControllerAppearance(nc: navigationController);
        }
        
        if let topViewController = self.moreNavigationController.topViewController {
            if let tableView = topViewController.view as? UITableView {
                tableView.tintColor = self.scheme.colorScheme.primaryColor
                tableView.backgroundColor = self.scheme.colorScheme.backgroundColor
            }
        }
        
        self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;

    }
    
    func setNavigationControllerAppearance(nc: UINavigationController?) {
        nc?.navigationBar.isTranslucent = false;
        nc?.navigationBar.barTintColor = self.scheme.colorScheme.primaryColorVariant;
        nc?.navigationBar.tintColor = self.scheme.colorScheme.onPrimaryColor;
        nc?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : self.scheme.colorScheme.onPrimaryColor];
        nc?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: self.scheme.colorScheme.onPrimaryColor];
        let appearance = UINavigationBarAppearance();
        appearance.configureWithOpaqueBackground();
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: self.scheme.colorScheme.onPrimaryColor,
            NSAttributedString.Key.backgroundColor: self.scheme.colorScheme.primaryColorVariant
        ];
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: self.scheme.colorScheme.onPrimaryColor,
            NSAttributedString.Key.backgroundColor: self.scheme.colorScheme.primaryColorVariant
        ];
        
        nc?.navigationBar.standardAppearance = appearance;
        nc?.navigationBar.scrollEdgeAppearance = appearance;
        nc?.navigationBar.standardAppearance.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
        nc?.navigationBar.scrollEdgeAppearance?.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    }
    
    override func viewDidLoad() {
        Mage.singleton()?.startServices(asInitial: true);
        super.viewDidLoad();
        
        createOrderedTabs();
        
        self.delegate = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        applyTheme();
        if let moreTableView = moreNavigationController.topViewController?.view as? UITableView {
            if let proxyDelegate = moreTableView.delegate {
                moreTableViewDelegate = MoreTableViewDelegate(proxyDelegate: proxyDelegate, containerScheme: scheme)
                moreTableView.delegate = moreTableViewDelegate
            }
        }
        offlineObservationManager.start()
        setServerConnectionStatus();
        UserDefaults.standard.addObserver(self, forKeyPath: "loginType" , options: .new, context: nil);
        
        NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { [weak self]  notification in
            guard let notificationObject: StraightLineNavigationNotification = notification.object as? StraightLineNavigationNotification else {
                return;
            }
            self?.mapTab.popToRootViewController(animated: false);
            self?.selectedViewController = self?.mapTab;
            
            if let mvc: MapViewController = self?.mapTab.viewControllers[0] as? MapViewController {
                mvc.mapDelegate.feedItemToNavigateTo = nil;
                mvc.mapDelegate.userToNavigateTo = nil;
                if let user = notificationObject.user {
                    mvc.mapDelegate.userToNavigateTo = user;
                } else if let feedItem = notificationObject.feedItem {
                    mvc.mapDelegate.feedItemToNavigateTo = feedItem;
                }
                mvc.mapDelegate.startStraightLineNavigation(notificationObject.coordinate, image: notificationObject.image);
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        mapTab.viewControllers = [];
        Mage.singleton()?.stopServices();
        offlineObservationManager.stop();
        UserDefaults.standard.removeObserver(self, forKeyPath: "loginType", context: nil);
        NotificationCenter.default.removeObserver(self, name: .StartStraightLineNavigation, object: nil);
    }
    
    func createOrderedTabs() {
        var allTabs: [UIViewController] = self.viewControllers ?? [];
        allTabs.append(mapTab);
        allTabs.append(settingsTabItem);
        allTabs.append(meTab);
        allTabs.append(locationsTab);
        allTabs.append(observationsTab);
        
        for feed in Feed.getEventFeeds(Server.currentEventId()) {
            let nc = createFeedViewController(feed: feed);
            allTabs.append(nc);
            feedViewControllers.append(nc);
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
        nc.tabBarItem.image = UIImage(named: "rss")?.aspectResize(to: CGSize(width: size, height: size));

        if let url: URL = feed.iconURL() {
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
