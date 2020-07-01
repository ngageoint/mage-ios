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
        
        createSettingsTabItem();
        for feed in Feed.mr_findAll()! as! [Feed] {
            createFeedViewController(feed: feed);
        }
        
        registerForThemeChanges();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        offlineObservationManager.start()
        setServerConnectionStatus();
        UserDefaults.standard.addObserver(self, forKeyPath: "loginType", options: .new, context: nil);
    }
    
    func createSettingsTabItem() {
        let svc = SettingsTableViewController();
        svc.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings_tab"), tag: 4);
        var array = self.viewControllers
        array?.append(svc)
        self.viewControllers = array
    }
    
    func createFeedViewController(feed: Feed) {
        let fvc = FeedItemsViewController(feed: feed);
        fvc.tabBarItem = UITabBarItem(title: feed.title, image: nil, tag: feed.id!.intValue + 5);
        
        if let url: URL = feed.iconURL() {
            let size = 24;
            
            let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
            KingfisherManager.shared.retrieveImage(with: url, options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ]) { result in
                switch result {
                case .success(let value):
                    
                    let image: UIImage = value.image.resized(to: CGSize(width: size, height: size));
                    fvc.tabBarItem.image = image;
                case .failure(let error):
                    print(error);
                }
            }
        } else {
            fvc.tabBarItem.image = UIImage(named: "marker");
        }
        fvc.tabBarItem.image = UIImage(named: "settings_tab");
        var array = self.viewControllers
        array?.append(fvc)
        self.viewControllers = array
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
    
    override func themeDidChange(_ theme: MageTheme) {
        self.tabBar.barTintColor = UIColor.tabBarTint();
        self.tabBar.tintColor = UIColor.activeTabIcon();
        self.tabBar.unselectedItemTintColor = UIColor.inactiveTabIcon();
        
        self.moreNavigationController.navigationBar.isTranslucent = false;
        self.moreNavigationController.navigationBar.barTintColor = UIColor.primary();
        self.moreNavigationController.navigationBar.tintColor = UIColor.navBarPrimaryText();
        self.moreNavigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.navBarPrimaryText()!,
                                                                           NSAttributedString.Key.backgroundColor : UIColor.primary()!];
        self.moreNavigationController.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.navBarPrimaryText()!,
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
    
            self.moreNavigationController.navigationBar.standardAppearance = appearance;
            self.moreNavigationController.navigationBar.scrollEdgeAppearance = appearance;
            self.moreNavigationController.navigationBar.standardAppearance.backgroundColor = UIColor.primary();
            self.moreNavigationController.navigationBar.scrollEdgeAppearance?.backgroundColor = UIColor.primary();
            self.moreNavigationController.navigationBar.prefersLargeTitles = true;
    
            self.moreNavigationController.navigationItem.largeTitleDisplayMode = .always;
        } else {
            // Fallback on earlier versions
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
