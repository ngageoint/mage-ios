//
//  ObservationTableViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 1/26/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MaterialSnackbar

class ObservationTableViewController: UITableViewController {
    
    var attachmentDelegate: AttachmentSelectionDelegate?;
    var observationActionsDelegate: ObservationActionsDelegate?;
    var scheme: MDCContainerScheming?;
    var childCoordinators: [NSObject] = [];
    var updateTimer: Timer?;
    var listenersSetUp = false;
    
    private lazy var createFab : MDCFloatingButton = {
        let fab = MDCFloatingButton(shape: .default);
        fab.setImage(UIImage(named: "add_location"), for: .normal);
        fab.addTarget(self, action: #selector(createNewObservation), for: .touchUpInside);
        return fab;
    }()
    
    private lazy var allReturned : UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30));
        label.textAlignment = .center;
        label.text = "All observations have been returned."
        return label;
    }()
    
    public lazy var observationDataStore: ObservationDataStore = {
        var dataStoreAttachmentDelegate = self.attachmentDelegate;
        
        if (self.attachmentDelegate == nil) {
            dataStoreAttachmentDelegate = self;
        }
        if (self.observationActionsDelegate == nil) {
            observationActionsDelegate = self;
        }
        
        let observationDataStore = ObservationDataStore(tableView: self.tableView, observationActionsDelegate: self.observationActionsDelegate, attachmentSelectionDelegate: dataStoreAttachmentDelegate, scheme: self.scheme);
        
        return observationDataStore;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    public init(attachmentDelegate: AttachmentSelectionDelegate? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        super.init(style: .grouped);
        self.attachmentDelegate = attachmentDelegate;
        self.observationActionsDelegate = observationActionsDelegate;
        self.scheme = scheme;
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.tableView.separatorStyle = .none;
        
        self.navigationController?.navigationBar.isTranslucent = false;
        self.navigationController?.navigationBar.barTintColor = containerScheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.tintColor = containerScheme.colorScheme.onPrimaryColor;
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : containerScheme.colorScheme.onPrimaryColor];
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor];
        let appearance = UINavigationBarAppearance();
        appearance.configureWithOpaqueBackground();
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor
        ];
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor:  containerScheme.colorScheme.onPrimaryColor
        ];
        
        self.navigationController?.navigationBar.standardAppearance = appearance;
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController?.navigationBar.standardAppearance.backgroundColor = containerScheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = containerScheme.colorScheme.primaryColorVariant;
        
        self.navigationItem.titleLabel?.textColor = containerScheme.colorScheme.onPrimaryColor;
        self.navigationItem.subtitleLabel?.textColor = containerScheme.colorScheme.onPrimaryColor;
        
        self.navigationController?.navigationBar.prefersLargeTitles = false;
        
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh observations", attributes: [NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onBackgroundColor])
        refreshControl?.tintColor = containerScheme.colorScheme.onBackgroundColor;
        
        createFab.applySecondaryTheme(withScheme: containerScheme);
        allReturned.font = containerScheme.typographyScheme.caption;
        allReturned.textColor = containerScheme.colorScheme.onBackgroundColor;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filterButtonPressed));
        
        self.tableView.backgroundView = nil;
        self.tableView.register(cellClass: ObservationListCardCell.self);
        self.tableView.register(UINib(nibName: "TableSectionHeader", bundle: nil), forCellReuseIdentifier: "TableSectionHeader");
                
        self.refreshControl = UIRefreshControl();
        refreshControl?.addTarget(self, action: #selector(refreshObservations), for: .valueChanged);
        self.tableView.refreshControl = self.refreshControl;
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 155;
        self.tableView.contentInset.bottom = 100;
        self.tableView.tableFooterView = allReturned;
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func setupFilterListeners() {
        UserDefaults.standard.addObserver(self, forKeyPath: kObservationTimeFilterKey, options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: kObservationTimeFilterNumberKey, options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: kObservationTimeFilterUnitKey, options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: kImportantFilterKey, options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: kFavortiesFilterKey, options: .new, context: nil);
        listenersSetUp = true;
    }
    
    func removeFilterListeners() {
        if (listenersSetUp) {
            UserDefaults.standard.removeObserver(self, forKeyPath: kObservationTimeFilterKey, context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: kObservationTimeFilterNumberKey, context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: kObservationTimeFilterUnitKey, context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: kImportantFilterKey, context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: kFavortiesFilterKey, context: nil);
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
        
        self.setNavBarTitle();
        self.startUpdateTimer();
        self.navigationController?.view.addSubview(createFab);
        self.createFab.autoPinEdge(toSuperviewMargin: .right);
        self.createFab.autoPinEdge(toSuperviewMargin: .bottom, withInset: 25);
        self.applyTheme(withContainerScheme: self.scheme);
        setupFilterListeners();
        
        observationDataStore.startFetchController();
        self.tableView.reloadData();
    }
    
    // This is all here so that we will purge old results from the list
    // for example if the time filter is set to "Today" when the observations fall off of the list
    // they will be purged from the view  TODO determine if there is a better way to do this, maybe just update far less
    // often, like once every 10 minutes because the flash on the feed is annoying
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        self.stopUpdateTimer();
        self.observationDataStore.observations?.delegate = nil;
        removeFilterListeners();
        createFab.removeFromSuperview();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        self.startUpdateTimer();
    }
    
    func startUpdateTimer() {
        if (self.updateTimer != nil) {
            return;
        }
        self.updateTimer = Timer(timeInterval: 60, target: self, selector: #selector(onUpdateTimerFire), userInfo: nil, repeats: true);
        RunLoop.main.add(self.updateTimer!, forMode: .default);
        self.observationDataStore.updatePredicates();
    }
    
    func stopUpdateTimer() {
        guard let timer = self.updateTimer else { return }
        timer.invalidate();
        self.updateTimer = nil;
    }
    
    @objc func onUpdateTimerFire() {
        self.observationDataStore.updatePredicates();
    }
    
    func setNavBarTitle() {
        let timeFilterString = MageFilter.getString();
        self.navigationItem.setTitle("Observations", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
    }
    
    @objc func filterButtonPressed() {
        let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil);
        let fvc: ObservationFilterTableViewController = filterStoryboard.instantiateViewController(identifier: "observationFilter");
        fvc.applyTheme(withContainerScheme: self.scheme);
        self.navigationController?.pushViewController(fvc, animated: true);
    }
    
    @objc func createNewObservation() {
        startCreateNewObservation(location: LocationService.singleton()?.location(), provider: "gps");
    }
    
    @objc func refreshObservations() {
        refreshControl?.beginRefreshing();
        let observationFetchTask: URLSessionDataTask = Observation.operationToPullObservations {
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing();
            }
        } failure: { (_) in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing();
            }
        }
        MageSessionManager.shared()?.addTask(observationFetchTask);
    }
    
    func startCreateNewObservation(location: CLLocation?, provider: String) {
        var point: SFPoint? = nil;
        var accuracy: CLLocationAccuracy = 0;
        var delta: Double = 0.0;
        
        if let safeLocation = location {
            if (safeLocation.altitude != 0) {
                point = SFPoint(x: NSDecimalNumber(value: safeLocation.coordinate.longitude), andY: NSDecimalNumber(value: safeLocation.coordinate.latitude), andZ: NSDecimalNumber(value: safeLocation.altitude));
            } else {
                point = SFPoint(x: NSDecimalNumber(value: safeLocation.coordinate.longitude), andY: NSDecimalNumber(value: safeLocation.coordinate.latitude));
            }
            accuracy = safeLocation.horizontalAccuracy;
            delta = safeLocation.timestamp.timeIntervalSinceNow * -1000;
        }
        
        let edit: ObservationEditCoordinator = ObservationEditCoordinator(rootViewController: self, delegate: self, location: point, accuracy: accuracy, provider: provider, delta: delta);
        edit.applyTheme(withContainerScheme: self.scheme);
        childCoordinators.append(edit);
        edit.start();
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == kObservationTimeFilterKey || keyPath == kObservationTimeFilterNumberKey || keyPath == kObservationTimeFilterUnitKey) {
            self.observationDataStore.updatePredicates();
            setNavBarTitle();
        } else if (keyPath == kImportantFilterKey || keyPath == kFavortiesFilterKey) {
            self.observationDataStore.updatePredicates();
        }
    }
    
    func removeChildCoordinator(_ coordinator: NSObject) {
        if let index = self.childCoordinators.firstIndex(where: { (child) -> Bool in
            return coordinator == child;
        }) {
            self.childCoordinators.remove(at: index);
        }
    }
}

extension ObservationTableViewController: ObservationEditDelegate {
    func editCancel(_ coordinator: NSObject) {
        removeChildCoordinator(coordinator);
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        removeChildCoordinator(coordinator);
    }
}

extension ObservationTableViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        removeChildCoordinator(coordinator);
    }
}

extension ObservationTableViewController: AttachmentSelectionDelegate {
    func selectedAttachment(_ attachment: Attachment!) {
        if let attachmentDelegate = self.attachmentDelegate {
            attachmentDelegate.selectedAttachment(attachment);
        } else {
            let attachmentCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self, scheme: scheme);
            self.childCoordinators.append(attachmentCoordinator);
            attachmentCoordinator.start();
        }
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        if let attachmentDelegate = self.attachmentDelegate {
            attachmentDelegate.selectedUnsentAttachment(unsentAttachment);
        } else {
            let attachmentCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, url: URL(fileURLWithPath: unsentAttachment["localPath"] as! String), contentType: (unsentAttachment["contentType"] as! String), delegate: self, scheme: scheme);
            self.childCoordinators.append(attachmentCoordinator);
            attachmentCoordinator.start();
        }
    }

    func selectedNotCachedAttachment(_ attachment: Attachment!, completionHandler handler: ((Bool) -> Void)!) {
        if let attachmentDelegate = self.attachmentDelegate {
            attachmentDelegate.selectedNotCachedAttachment(attachment, completionHandler: handler);
        } else {
            if (!DataConnectionUtilities.shouldFetchAttachments()) {
                if (attachment.contentType?.hasPrefix("image") == true) {
                    let alert = UIAlertController(title: "View Image", message: "Your attachment fetch settings do not allow auto downloading of images.  Would you like to view the image?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                        handler(true);
                    }))
                    alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil));
                    self.present(alert, animated: true, completion: nil);
                } else if (attachment.contentType?.hasPrefix("video") == true) {
                    if (attachment.url == nil) {
                        return;
                    }
                    let attachmentCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self, scheme: scheme);
                    self.childCoordinators.append(attachmentCoordinator);
                    attachmentCoordinator.start();
                }
            }
        }
    }
}

extension ObservationTableViewController: ObservationActionsDelegate {
    func viewObservation(_ observation: Observation) {
        let ovc = ObservationViewCardCollectionViewController(observation: observation, scheme: self.scheme!);
        self.navigationController?.pushViewController(ovc, animated: true);
    }
    
    func favoriteObservation(_ observation: Observation) {
        observation.toggleFavorite { (_, _) in
            self.tableView.reloadData();
        }
    }
    
    func copyLocation(_ locationString: String) {
        UIPasteboard.general.string = locationString;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location copied to clipboard"))
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView?) {
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: ObservationImage.image(for: observation), coordinate: observation.location().coordinate))
        }));
        
        ObservationActionHandler.getDirections(latitude: observation.location().coordinate.latitude, longitude: observation.location().coordinate.longitude, title: observation.primaryFeedFieldText(), viewController: self, extraActions: extraActions, sourceView: sourceView);
    }
}
