//
//  MageRootViewController.swift
//  Mage
//  Updated on 06/23/2025 by Brent Michalski
//

import Foundation
import Kingfisher
import UIKit

@objcMembers
class MageRootViewController : UITabBarController {
    // Dependency Injection
    @Injected(\.attachmentRepository) var attachmentRepository: AttachmentRepository
    @Injected(\.nsManagedObjectContext) var context: NSManagedObjectContext?
    
    private var mapRequestFocusObserver: Any?
    private var snackbarNoticiasObserver: Any?
    
    private(set) lazy var offlineObservationManager: MageOfflineObservationManager = {
        MageOfflineObservationManager(delegate: self, context: context)
    }()
    
    private var feedViewControllers: [UINavigationController] = []
    
    @objc(initWithContainerScheme:)
    init(containerScheme: AppContainerScheming?) {
        super.init(nibName: nil, bundle: nil)
        self.scheme = containerScheme
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    @objc convenience init(containerScheme: Any?) {
        self.init(containerScheme: containerScheme as? AppContainerScheming)
    }
    
    var scheme: AppContainerScheming?
    private var attachmentViewCoordinator: AttachmentViewCoordinator?
    
    // TODO: BRENT - Remove FORCED unwrap
    private lazy var settingsNav: UINavigationController = {
        let vc = SettingsTableViewController(scheme: scheme, context: context)!
        let nav = UINavigationController(rootViewController: vc)
        
        nav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 4)
        
        return nav
    }()
    
    private lazy var peopleNav: UINavigationController = {
        let vc = LocationListNavStack(scheme: scheme)
        let nav = UINavigationController(rootViewController: vc)
        
        nav.tabBarItem = UITabBarItem(title: "People", image: UIImage(systemName: "person.2.fill"), tag: 2)
        
        return nav
    }()

    private lazy var obsNav: UINavigationController = {
        let root = ObservationListNavStack(scheme: scheme)
        let nav = UINavigationController(rootViewController: root)
        
        nav.tabBarItem = UITabBarItem(title: "Observations", image: UIImage(named: "observations"), tag: 1)
        
        return nav
    }()
    
    private lazy var mapNav: UINavigationController = {
        let root = MageMapViewController(scheme: scheme)
        let nav = UINavigationController(rootViewController: root)
        
        nav.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map.fill"), tag: -1)
        
        return nav
    }()

    private lazy var profileNav: UINavigationController = {
        let root = MeNavStack(scheme: scheme)
        let nav = UINavigationController(rootViewController: root)
        
        nav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.fill"), tag: 3)
        
        return nav
    }()
    
    private var profileTabBarItem: UITabBarItem? {
        return profileNav.tabBarItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Mage.singleton.startServices(initial: true)
        delegate = self
        setupTabs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        applyTheme(scheme: self.scheme)
        observeNotifications()
        offlineObservationManager.start()
        setServerBadge()
        UserDefaults.standard.addObserver(self, forKeyPath: "loginType" , options: .new, context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        cleanupObservers()
        Mage.singleton.stopServices()
        
        offlineObservationManager.stop()
        offlineObservationManager.delegate = nil
    }
    

    // MARK: - Set up tabs
    
    private func setupTabs() {
        var controllers: [UIViewController] = [settingsNav, peopleNav, obsNav, mapNav]
        controllers.append(profileNav)
        
        // Add feed tabs
        if let eventId = Server.currentEventId() {
            for feed in Feed.getEventFeeds(eventId: eventId) {
                let nav = createFeedNav(for: feed)
                controllers.append(nav)
            }
        }
        viewControllers = ordered(controllers)
    }
    
    private func ordered(_ list: [UIViewController]) -> [UIViewController] {
        list.sorted {
            let a = UserDefaults.standard.integer(forKey: "rootViewTabPosition\($0.tabBarItem.tag)")
            let b = UserDefaults.standard.integer(forKey: "rootViewTabPosition\($1.tabBarItem.tag)")
            return a < b
        }
    }

    private func createFeedNav(for feed: Feed) -> UINavigationController {
        let vc = FeedItemsViewController(feed: feed, scheme: scheme)
        let nav = UINavigationController(rootViewController: vc)
        
        nav.tabBarItem = UITabBarItem(title: feed.title, image: UIImage(systemName: "dot.radiowaves.up.forward"), tag: feed.tag?.intValue ?? 5)
        
        // placeholder icon
        if let url = feed.tabIconURL {
            KingfisherManager.shared.retrieveImage(with: url, options: [.processor(DownsamplingImageProcessor(size: CGSize(width: 24, height: 24)))]) { result in
                if case let .success(value) = result {
                    nav.tabBarItem.image = value.image
                }
            }
        }
        return nav
    }
    
    // MARK: - Theming & Badging
    
    @objc func applyTheme(scheme: AppContainerScheming?) {
        guard let scheme else { return }
        
        self.scheme = scheme
        tabBar.tintColor = scheme.colorScheme.primaryColor?.withAlphaComponent(0.87)
        view.backgroundColor = scheme.colorScheme.backgroundColor
    }
    
    private func setServerBadge() {
        let offline = UserDefaults.standard.loginType == "offline"
        let index = viewControllers?.firstIndex { $0.tabBarItem.tag == 4 }
        viewControllers?[index ?? 0].tabBarItem.badgeValue = offline ? "!" : nil
    }
    
    
    // MARK: - Notifications
    
    private func observeNotifications() {
        mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { [weak self] _ in
            self?.selectedViewController = self?.mapNav
        }
        
        snackbarNoticiasObserver = NotificationCenter.default.addObserver(forName: .SnackbarNotification, object: nil, queue: .main) { [weak self] notification in
            if let message = (notification.object as? SnackbarNotification)?.snackbarModel?.message {
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func cleanupObservers() {
        if let mapReqObserver = mapRequestFocusObserver {
            NotificationCenter.default.removeObserver(mapReqObserver)
        }
        
        if let snkbrObserver = snackbarNoticiasObserver {
            NotificationCenter.default.removeObserver(snkbrObserver)
        }
        UserDefaults.standard.removeObserver(self, forKeyPath: "loginType")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        setServerBadge()
    }
    
    // MARK: - Attachment
    
    @objc func selectedAttachment(_ uri: URL, navigationController nav: UINavigationController) {
        Task {
            if let att = await attachmentRepository.getAttachment(attachmentUri: uri) {
                let coordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: att, delegate: self, scheme: scheme)
                coordinator.start()
                self.attachmentViewCoordinator = coordinator
            }
        }
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
            self.profileTabBarItem?.badgeValue = count > 99 ? "99+" : String(count)
        } else {
            self.profileTabBarItem?.badgeValue = nil
        }
    }
}

extension MageRootViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil
    }
}
