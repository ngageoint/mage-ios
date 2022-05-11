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
    
    weak var attachmentDelegate: AttachmentSelectionDelegate?;
    weak var observationActionsDelegate: ObservationActionsDelegate?;
    var scheme: MDCContainerScheming?;
    var childCoordinators: [NSObject] = [];
    var updateTimer: Timer?;
    var listenersSetUp = false;
    var attachmentPushedObserver:Any?
    
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
    
    private lazy var emptyState : EmptyState = {
        let view = EmptyState(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
        view.configure(image: UIImage(named: "outline_not_listed_location"), title: "No Observations", description: "No observations have been submitted within your configured time filter for this event.", buttonText: "Adjust Filter", tapHandler: self, selector: #selector(filterButtonPressed), scheme: scheme)
        
        return view
    }()
    
    public lazy var observationDataStore: ObservationDataStore = {
        var dataStoreAttachmentDelegate = self.attachmentDelegate;
        
        if (self.attachmentDelegate == nil) {
            dataStoreAttachmentDelegate = self;
        }
        if (self.observationActionsDelegate == nil) {
            observationActionsDelegate = self;
        }
        
        let observationDataStore = ObservationDataStore(tableView: self.tableView, observationActionsDelegate: self.observationActionsDelegate, attachmentSelectionDelegate: dataStoreAttachmentDelegate, emptyView: emptyState, scheme: self.scheme);
        
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
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.tableView.separatorStyle = .none;
        
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
                
        self.refreshControl = UIRefreshControl();
        refreshControl?.addTarget(self, action: #selector(refreshObservations), for: .valueChanged);
        self.tableView.refreshControl = self.refreshControl;
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 155;
        self.tableView.contentInset.bottom = 100;
//        self.tableView.tableFooterView = allReturned;
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        if let attachmentPushedObserver = attachmentPushedObserver {
            NotificationCenter.default.removeObserver(attachmentPushedObserver, name: .AttachmentPushed, object: nil)
        }
    }
    
    func setupFilterListeners() {
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterKey), options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterUnitKey), options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterNumberKey), options: [.new], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.importantFilterKey), options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.favoritesFilterKey), options: .new, context: nil);
        attachmentPushedObserver = NotificationCenter.default.addObserver(self, selector: #selector(refreshObservations), name: .AttachmentPushed, object: nil)
        listenersSetUp = true;
    }
    
    func removeFilterListeners() {
        if (listenersSetUp) {
            UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterKey))
            UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterUnitKey))
            UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.observationTimeFilterNumberKey))
            UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.importantFilterKey), context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.favoritesFilterKey), context: nil);
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

        let observationFetchTask = Observation.operationToPullObservations { (_,_) in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing();
            }
        } failure: { _,_ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing();
            }
        }
        if let observationFetchTask = observationFetchTask {
            MageSessionManager.shared()?.addTask(observationFetchTask);
        }
    }
    
    func startCreateNewObservation(location: CLLocation?, provider: String) {
        var point: SFPoint? = nil;
        var accuracy: CLLocationAccuracy = 0;
        var delta: Double = 0.0;
        
        if let location = location {
            if (location.altitude != 0) {
                point = SFPoint(x: NSDecimalNumber(value: location.coordinate.longitude), andY: NSDecimalNumber(value: location.coordinate.latitude), andZ: NSDecimalNumber(value: location.altitude));
            } else {
                point = SFPoint(x: NSDecimalNumber(value: location.coordinate.longitude), andY: NSDecimalNumber(value: location.coordinate.latitude));
            }
            accuracy = location.horizontalAccuracy;
            delta = location.timestamp.timeIntervalSinceNow * -1000;
        }
        
        let edit: ObservationEditCoordinator = ObservationEditCoordinator(rootViewController: self, delegate: self, location: point, accuracy: accuracy, provider: provider, delta: delta);
        edit.applyTheme(withContainerScheme: self.scheme);
        childCoordinators.append(edit);
        edit.start();
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == #keyPath(UserDefaults.observationTimeFilterKey) || keyPath == #keyPath(UserDefaults.observationTimeFilterNumberKey) || keyPath == #keyPath(UserDefaults.observationTimeFilterUnitKey)) {
            self.observationDataStore.updatePredicates();
            setNavBarTitle();
        } else if (keyPath == #keyPath(UserDefaults.importantFilterKey) || keyPath == #keyPath(UserDefaults.favoritesFilterKey)) {
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
    
    func favoriteObservation(_ observation: Observation, completion: ((Observation?) -> Void)?) {
        observation.toggleFavorite { (_, _) in
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            completion?(observation);
        }
    }
    
    func copyLocation(_ locationString: String) {
        UIPasteboard.general.string = locationString;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location \(locationString) copied to clipboard"))
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView?) {
        guard let location = observation.location else {
            return;
        }
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: ObservationImage.image(observation: observation), coordinate: location.coordinate))
        }));
        
        ObservationActionHandler.getDirections(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, title: observation.primaryFeedFieldText ?? "Observation", viewController: self, extraActions: extraActions, sourceView: sourceView);
    }
}
