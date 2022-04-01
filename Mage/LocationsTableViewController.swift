//
//  UserTableViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher
import MaterialComponents.MaterialSnackbar

class LocationsTableViewController: UITableViewController {
    
    weak var actionsDelegate: UserActionsDelegate?;
    var scheme: MDCContainerScheming?;
    var updateTimer: Timer?;
    var listenersSetUp = false;
    var userIds: [String]?;
    
    private lazy var allReturned : UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30));
        label.textAlignment = .center;
        label.text = "All users have been returned."
        return label;
    }()
    
    public lazy var locationDataStore: LocationDataStore = {
        if (self.actionsDelegate == nil) {
            actionsDelegate = self;
        }

        let locationDataStore = LocationDataStore(tableView: tableView, actionsDelegate: actionsDelegate, scheme: scheme);
        return locationDataStore;
    }()
    
    private lazy var userDataStore: UserDataStore = {
        if (self.actionsDelegate == nil) {
            actionsDelegate = self;
        }
        
        let userDataStore = UserDataStore(tableView: tableView, userIds: userIds, actionsDelegate: actionsDelegate, scheme: scheme);
        return userDataStore;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    public init(userIds: [String]? = nil, actionsDelegate: UserActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        super.init(style: .grouped);
        self.actionsDelegate = actionsDelegate;
        self.scheme = scheme;
        self.userIds = userIds;
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.tableView.separatorStyle = .none;
        
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh users", attributes: [NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onBackgroundColor])
        refreshControl?.tintColor = containerScheme.colorScheme.onBackgroundColor;
        
        allReturned.font = containerScheme.typographyScheme.caption;
        allReturned.textColor = containerScheme.colorScheme.onBackgroundColor;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.tableView.backgroundView = nil;
        self.tableView.register(cellClass: PersonTableViewCell.self)
        self.tableView.register(UINib(nibName: "TableSectionHeader", bundle: nil), forCellReuseIdentifier: "TableSectionHeader");
        
        if (userIds == nil) {
            self.refreshControl = UIRefreshControl();
            refreshControl?.addTarget(self, action: #selector(refreshLocations), for: .valueChanged);
            self.tableView.refreshControl = self.refreshControl;
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filterButtonPressed));
        }
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 155;
        self.tableView.contentInset.bottom = 100;
        self.tableView.tableFooterView = allReturned;
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func setupFilterListeners() {
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.locationTimeFilter), options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.locationTimeFilterNumber), options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.locationTimeFilterUnit), options: .new, context: nil);
        listenersSetUp = true;
    }
    
    func removeFilterListeners() {
        if (listenersSetUp) {
            UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.locationTimeFilter), context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.locationTimeFilterNumber), context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.locationTimeFilterUnit), context: nil);
        }
        listenersSetUp = false;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        // iOS bug fix.
        // For some reason the first view in a TabBarViewController when that TabBarViewController
        // is the master view of a split view the toolbar will not attach to the status bar correctly.
        // Forcing it to relayout seems to fix the issue.
        self.view.setNeedsLayout();
        
        self.applyTheme(withContainerScheme: self.scheme);
        
        if (userIds == nil) {
            setupFilterListeners();
            self.setNavBarTitle();
            self.startUpdateTimer();
            locationDataStore.startFetchController();
        } else {
            userDataStore.startFetchController(userIds: userIds);
        }
        self.tableView.reloadData();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        if (userIds == nil) {
            self.stopUpdateTimer();
            self.locationDataStore.locations?.delegate = nil;
            removeFilterListeners();
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        if (userIds == nil) {
            self.startUpdateTimer();
        }
    }
    
    func startUpdateTimer() {
        if (self.updateTimer != nil) {
            return;
        }
        self.updateTimer = Timer(timeInterval: 60, target: self, selector: #selector(onUpdateTimerFire), userInfo: nil, repeats: true);
        RunLoop.main.add(self.updateTimer!, forMode: .default);
        self.locationDataStore.updatePredicates();
    }
    
    func stopUpdateTimer() {
        guard let timer = self.updateTimer else { return }
        timer.invalidate();
        self.updateTimer = nil;
    }
    
    @objc func onUpdateTimerFire() {
        self.locationDataStore.updatePredicates();
    }
    
    func setNavBarTitle() {
        let timeFilterString = MageFilter.getLocationFilterString()
        self.navigationItem.setTitle("People", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
    }
    
    @objc func filterButtonPressed() {
        let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil);
        let fvc: LocationFilterTableViewController = filterStoryboard.instantiateViewController(identifier: "locationFilter");
        fvc.applyTheme(withContainerScheme: self.scheme);
        self.navigationController?.pushViewController(fvc, animated: true);
    }
    
    @objc func refreshLocations() {
        refreshControl?.beginRefreshing();
        let locationFetchTask: URLSessionDataTask? = Location.operationToPullLocations {_,_ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing();
            }
        } failure: { (_,_)  in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing();
            }
        }
        
        MageSessionManager.shared()?.addTask(locationFetchTask);
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == #keyPath(UserDefaults.locationTimeFilter) || keyPath == #keyPath(UserDefaults.locationTimeFilterNumber) || keyPath == #keyPath(UserDefaults.locationTimeFilterUnit)) {
            self.locationDataStore.updatePredicates();
            setNavBarTitle();
        }
    }
}

extension LocationsTableViewController: UserActionsDelegate {
    
    func viewUser(_ user: User) {
        let uvc = UserViewController(user: user, scheme: self.scheme!);
        self.navigationController?.pushViewController(uvc, animated: true);
    }
    
    func getDirectionsToUser(_ user: User, sourceView: UIView?) {
        guard let location: CLLocationCoordinate2D = user.location?.location?.coordinate else {
            return;
        }
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            
            var image: UIImage? = UIImage(named: "me")
            if let cacheIconUrl = user.cacheIconUrl {
                let url = URL(string: cacheIconUrl)!;
                
                KingfisherManager.shared.retrieveImage(with: url, options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ]) { result in
                    switch result {
                    case .success(let value):
                        let scale = value.image.size.width / 37;
                        image = UIImage(cgImage: value.image.cgImage!, scale: scale, orientation: value.image.imageOrientation);
                    case .failure(_):
                        image = UIImage.init(named: "me")?.withRenderingMode(.alwaysTemplate);
                    }
                    NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: image, coordinate: location, user: user))
                }
            } else {
                NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: image, coordinate: location, user: user))
            }
        }));
        ObservationActionHandler.getDirections(latitude: location.latitude, longitude: location.longitude, title: user.name ?? "User", viewController: self.navigationController!, extraActions: extraActions, sourceView: sourceView);
    }
}
