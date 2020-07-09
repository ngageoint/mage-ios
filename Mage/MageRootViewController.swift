//
//  MageRootViewController.m
//  Mage
//

import Foundation
import Kingfisher

@objc class MageRootViewController : UITabBarController {
    
    var profileTabBarItem: UITabBarItem?;
    var moreTabBarItem: UITabBarItem?;
    
    private lazy var offlineObservationManager: MageOfflineObservationManager = {
        let manager: MageOfflineObservationManager = MageOfflineObservationManager(delegate: self);
        return manager;
    }();
    
    override func viewDidLoad() {
        Mage.singleton()?.startServices(asInitial: true);
        super.viewDidLoad();
        
        for viewController in self.viewControllers! {
            if (viewController.tabBarItem.tag == 3) {
                self.profileTabBarItem = viewController.tabBarItem;
            } else if (viewController.tabBarItem.tag == 4) {
                self.moreTabBarItem = viewController.tabBarItem;
            }
        }
        createOrderedTabs();
        registerForThemeChanges();
        
        self.delegate = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        offlineObservationManager.start()
        setServerConnectionStatus();
        UserDefaults.standard.addObserver(self, forKeyPath: "loginType", options: .new, context: nil);
    }
    
    func createOrderedTabs() {
        var allTabs: [UIViewController] = self.viewControllers ?? [];
        allTabs.append(createSettingsTabItem());
        
        for feed in Feed.mr_findAll()! as! [Feed] {
            allTabs.append(createFeedViewController(feed: feed));
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
    
    func createSettingsTabItem() -> UINavigationController {
        let svc = SettingsTableViewController();
        let nc = UINavigationController(rootViewController: svc);
        setNavigationControllerAppearance(nc: nc);
        nc.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings_tab"), tag: 4);
        return nc;
    }
    
    func createFeedViewController(feed: Feed) -> UINavigationController {
        let size = 24;
        let fvc = FeedItemsViewController(feed: feed);
        let nc = UINavigationController(rootViewController: fvc);
        setNavigationControllerAppearance(nc: nc);
        nc.tabBarItem = UITabBarItem(title: feed.title, image: nil, tag: feed.id!.intValue + 5);
        nc.tabBarItem.image = UIImage(named: "marker")?.aspectResize(to: CGSize(width: size, height: size));

        if let url: URL = feed.iconURL() {
            let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
            KingfisherManager.shared.retrieveImage(with: url, options: [
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
        if (Authentication.authenticationType(toString: .LOCAL) ==
            UserDefaults.standard.string(forKey: "loginType")) {
            moreTabBarItem?.badgeValue = "!";
            moreTabBarItem?.badgeColor = UIColor.orange;
        } else {
            moreTabBarItem?.badgeValue = nil;
            moreTabBarItem?.badgeColor = nil;
        }
    }
    
    func setNavigationControllerAppearance(nc: UINavigationController) {
        nc.navigationBar.isTranslucent = false;
        nc.navigationBar.barTintColor = UIColor.primary();
        nc.navigationBar.tintColor = UIColor.navBarPrimaryText();
        nc.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.navBarPrimaryText()!,
                                                                           NSAttributedString.Key.backgroundColor : UIColor.primary()!];
        nc.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.navBarPrimaryText()!,
                                                                                NSAttributedString.Key.backgroundColor : UIColor.primary()!];
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground();
            appearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.navBarPrimaryText()!,
                NSAttributedString.Key.backgroundColor: UIColor.primary()!
            ];
            appearance.largeTitleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.navBarPrimaryText()!,
                NSAttributedString.Key.backgroundColor: UIColor.primary()!
            ];
            
            nc.navigationBar.standardAppearance = appearance;
            nc.navigationBar.scrollEdgeAppearance = appearance;
            nc.navigationBar.standardAppearance.backgroundColor = UIColor.primary();
            nc.navigationBar.scrollEdgeAppearance?.backgroundColor = UIColor.primary();
            nc.navigationBar.prefersLargeTitles = true;
            
            nc.navigationItem.largeTitleDisplayMode = .automatic;
        }
    }
    
    override func themeDidChange(_ theme: MageTheme) {
        self.tabBar.barTintColor = UIColor.tabBarTint();
        self.tabBar.tintColor = UIColor.activeTabIcon();
        self.tabBar.unselectedItemTintColor = UIColor.inactiveTabIcon();
        
        setNavigationControllerAppearance(nc: self.moreNavigationController);
        
        if let topViewController = self.moreNavigationController.topViewController {
            if let tableView = topViewController.view as? UITableView {
                tableView.tintColor = UIColor.primary();
            }
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
