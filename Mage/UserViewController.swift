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
    var scheme : MDCContainerScheming;
    
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
    
    @objc public init(user:User, scheme: MDCContainerScheming) {
        self.user = user
        self.scheme = scheme;
        super.init(style: .grouped)
        self.title = user.name;
        self.tableView.register(cellClass: ObservationListCardCell.self);
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
        self.navigationController?.navigationBar.barTintColor = self.scheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.tintColor = self.scheme.colorScheme.onPrimaryColor;
        self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160;
        tableView.setAndLayoutTableHeaderView(header: userTableHeaderView);
        applyTheme(withContainerScheme: self.scheme);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        userTableHeaderView.navigationController = self.navigationController;
        observationDataStore.startFetchController(observations: Observations(for: user));
    }
}

extension UserViewController : ObservationActionsDelegate {
    func viewObservation(_ observation: Observation) {
        let ovc = ObservationViewCardCollectionViewController(observation: observation, scheme: self.scheme);
        self.navigationController?.pushViewController(ovc, animated: true);
    }
    
    func favorite(_ observation: Observation) {
        observation.toggleFavorite { (_, _) in
            self.tableView.reloadData();
        }
    }
    
    func copyLocation(_ locationString: String) {
        UIPasteboard.general.string = locationString;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location copied to clipboard"))
    }
    
    func getDirections(_ observation: Observation) {
        ObservationActionHandler.getDirections(latitude: observation.location().coordinate.latitude, longitude: observation.location().coordinate.longitude, title: observation.primaryFeedFieldText(), viewController: self);
    }
}

extension UserViewController : AttachmentSelectionDelegate {
    func selectedAttachment(_ attachment: Attachment!) {
        let attachmentCoordinator: AttachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self);
        childCoordinators.append(attachmentCoordinator);
        attachmentCoordinator.start();
    }
}

extension UserViewController : AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        if let i = childCoordinators.firstIndex(of: coordinator) {
            childCoordinators.remove(at: i);
        }
    }
}
