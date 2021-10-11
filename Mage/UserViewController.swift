//
//  UserViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class UserViewController : UITableViewController {
    let user : User
    let cellReuseIdentifier = "cell";
    var childCoordinators: Array<NSObject> = [];
    var scheme : MDCContainerScheming?;
    
    private lazy var observationDataStore: ObservationDataStore = {
        let observationDataStore: ObservationDataStore = ObservationDataStore(tableView: self.tableView, observationActionsDelegate: self, attachmentSelectionDelegate: self, scheme: self.scheme);
        return observationDataStore;
    }();
    
    private lazy var userTableHeaderView: UserTableHeaderView = {
        let userTableHeaderView: UserTableHeaderView = UserTableHeaderView(user: user, scheme: self.scheme);
        userTableHeaderView.navigationController = self.navigationController;
        return userTableHeaderView;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public init(user:User, scheme: MDCContainerScheming?) {
        self.user = user
        self.scheme = scheme;
        super.init(style: .grouped)
        self.title = user.name;
        self.tableView.register(cellClass: ObservationListCardCell.self);
        self.tableView.accessibilityIdentifier = "user observations";
        self.tableView.separatorStyle = .none;
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        self.scheme = containerScheme;
        guard let containerScheme = containerScheme else {
            return
        }

        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160;
        applyTheme(withContainerScheme: self.scheme);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        tableView.setAndLayoutTableHeaderView(header: userTableHeaderView);

        userTableHeaderView.navigationController = self.navigationController;
        userTableHeaderView.start();
        observationDataStore.startFetchController(observations: Observations(for: user));
        applyTheme(withContainerScheme: self.scheme);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        userTableHeaderView.stop();
    }
}

extension UserViewController : ObservationActionsDelegate {
    func viewObservation(_ observation: Observation) {
        let ovc = ObservationViewCardCollectionViewController(observation: observation, scheme: self.scheme);
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
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView? = nil) {
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: ObservationImage.image(for: observation), coordinate: observation.location().coordinate))
        }));
        ObservationActionHandler.getDirections(latitude: observation.location().coordinate.latitude, longitude: observation.location().coordinate.longitude, title: observation.primaryFeedFieldText(), viewController: self, extraActions: extraActions, sourceView: sourceView);
    }
}

extension UserViewController : AttachmentSelectionDelegate {
    func selectedAttachment(_ attachment: Attachment!) {
        if (attachment.url != nil) {
            let attachmentCoordinator: AttachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self, scheme: scheme);
            childCoordinators.append(attachmentCoordinator);
            attachmentCoordinator.start();
        }
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        let attachmentCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, url: URL(fileURLWithPath: unsentAttachment["localPath"] as! String), contentType:(unsentAttachment["contentType"] as! String), delegate: self, scheme: scheme);
        self.childCoordinators.append(attachmentCoordinator);
        attachmentCoordinator.start();
    }
    
    func selectedNotCachedAttachment(_ attachment: Attachment!, completionHandler handler: ((Bool) -> Void)!) {
        if (attachment.url != nil) {
            let attachmentCoordinator: AttachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self, scheme: scheme);
            childCoordinators.append(attachmentCoordinator);
            attachmentCoordinator.start();
        }
    }
}

extension UserViewController : AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        if let i = childCoordinators.firstIndex(of: coordinator) {
            childCoordinators.remove(at: i);
        }
    }
}
