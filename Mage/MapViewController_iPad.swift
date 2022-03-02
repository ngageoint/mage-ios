//
//  MapViewController_iPad.m
//  MAGE
//
//

import Foundation
import PureLayout

@objc class MapViewController_iPad : MageMapViewController {
    
    typealias Delegate = ObservationActionsDelegate & UserActionsDelegate & FeedItemSelectionDelegate
    weak var delegate: Delegate?;
    var settingsCoordinator: MapSettingsCoordinator?
    
    private lazy var profileButton : UIButton = {
        let profileButton = UIButton();
        profileButton.setTitle("Profile", for: .normal);
        profileButton.addTarget(self, action: #selector(profileButtonTapped(_:)), for: .touchUpInside)
        return profileButton;
    }()
    
    private lazy var badge : UILabel = {
        let badge: UILabel = UILabel.newAutoLayout();
        badge.autoSetDimensions(to: CGSize(width: 20, height: 20))
        badge.layer.cornerRadius = badge.bounds.size.height / 2
        badge.textAlignment = .center
        badge.layer.masksToBounds = true
        badge.textColor = .white
        badge.font = .boldSystemFont(ofSize: 14)
        badge.backgroundColor = .systemRed
        return badge;
    }()

    private var offlineObservationManager : MageOfflineObservationManager?;
    
    convenience public init(delegate: Delegate?, scheme: MDCContainerScheming) {
        self.init(scheme: scheme);
        self.delegate = delegate;
    }
    
    override func setupNavigationBar() {
        let profileBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: profileButton);
        let filterBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filterTapped(_:)))
        let moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(moreTapped(_:)))
        self.navigationItem.rightBarButtonItems = [moreBarButtonItem, self.createSeparator(), profileBarButtonItem, self.createSeparator(), filterBarButtonItem];
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.navigationController?.navigationBar.isTranslucent = false;
        
        self.offlineObservationManager = MageOfflineObservationManager(delegate: self);
        self.offlineObservationManager?.start()
        setupNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        self.offlineObservationManager?.stop();
    }

    func createSeparator() -> UIBarButtonItem {
        let separator: UIView = UIView(frame: CGRect(x: self.navigationController?.navigationBar.frame.size.height ?? 0 * 0.166, y: 0, width: 1, height: self.navigationController?.navigationBar.frame.size.height ?? 0 * 0.66))
        separator.backgroundColor = .white.withAlphaComponent(0.13)
        let separatorItem: UIBarButtonItem = UIBarButtonItem(customView: separator);
        return separatorItem;
    }
    
    @objc func profileButtonTapped(_ sender: UIView) {
        if let user: User = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()) {
            delegate?.viewUser?(user);
        }
    }
    
    @objc func mapSettingsTapped(_ sender: UIView) {
        settingsCoordinator = MapSettingsCoordinator(rootViewController: self.navigationController, andSourceView: sender, scheme: self.scheme);
        settingsCoordinator?.delegate = self;
        settingsCoordinator?.start();
    }
    
    @objc func moreTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet);
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
            let settingsViewController: SettingsViewController = SettingsViewController(scheme: self.scheme);
            settingsViewController.dismissable = true;
            self.present(settingsViewController, animated: true, completion: nil);
        }));
        
        alert.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { action in
            if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.logout();
            }
        }));
        
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true, completion: nil);
    }
    
    func calloutTapped(_ calloutItem: Any!) {
        if let user = calloutItem as? User {
            delegate?.viewUser?(user);
        } else if let observation = calloutItem as? Observation {
            delegate?.viewObservation?(observation);
        } else if let feedItem = calloutItem as? FeedItem {
            delegate?.feedItemSelected(feedItem);
        }
    }
}

extension MapViewController_iPad : OfflineObservationDelegate {
    func offlineObservationsDidChangeCount(_ count: Int) {
        var text = "\(count)"
        if (count > 99) {
            text = "99+"
        }
        self.badge.text = "\(text)";
    
        self.profileButton.addSubview(self.badge);
        self.badge.autoPinEdge(toSuperviewEdge: .top, withInset: -4)
        if (count <= 0) {
            self.badge.autoSetDimensions(to: CGSize(width: 0, height: 0))
        } else if (count < 10) {
            self.badge.autoPinEdge(toSuperviewEdge: .right, withInset: 14);
            self.badge.autoSetDimensions(to: CGSize(width: 20, height: 20));
        } else if (count < 100) {
            self.badge.autoPinEdge(toSuperviewEdge: .right, withInset: 24);
            self.badge.autoSetDimensions(to: CGSize(width: 30, height: 20));
        } else {
            self.badge.autoPinEdge(toSuperviewEdge: .right, withInset: 34);
            self.badge.autoSetDimensions(to: CGSize(width: 40, height: 20));
        }
    }
}

extension MapViewController_iPad : MapSettingsCoordinatorDelegate {
    func mapSettingsComplete(_ coordinator: NSObject!) {
        settingsCoordinator = nil
    }
}
