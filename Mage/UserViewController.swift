//
//  UserViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension UITableView {

    func setAndLayoutTableHeaderView(header: UIView) {
        self.tableHeaderView = header
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let height = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = header.frame
        frame.size.height = height
        header.frame = frame
        self.tableHeaderView = header
        if #available(iOS 14, *) {
            self.tableHeaderView?.autoMatch(.width, to: .width, of: self);
        } else {
            header.autoSetDimension(.width, toSize: bounds.size.width)
        }
    }
}

@objc class UserViewController : UITableViewController {
    let user : User
    let cellReuseIdentifier = "cell";
    var childCoordinators: Array<NSObject> = [];
    var scheme : MDCContainerScheming;
    
    private lazy var observationDataStore: ObservationDataStore = {
        let observationDataStore: ObservationDataStore = ObservationDataStore(scheme: self.scheme);
        observationDataStore.tableView = self.tableView;
        observationDataStore.observationSelectionDelegate = self;
        observationDataStore.attachmentSelectionDelegate = self;
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
        tableView.register(UINib(nibName: "ObservationCell", bundle: nil), forCellReuseIdentifier: "obsCell");
    }
    
    override func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
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
        observationDataStore.startFetchController(with: Observations(for: user));
    }
}

extension UserViewController : ObservationSelectionDelegate {
    func selectedObservation(_ observation: Observation!) {
        let ovc: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme);
        self.navigationController?.pushViewController(ovc, animated: true);
    }
    
    func selectedObservation(_ observation: Observation!, region: MKCoordinateRegion) {
        let ovc: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme);
        self.navigationController?.pushViewController(ovc, animated: true);
    }
    
    func observationDetailSelected(_ observation: Observation!) {
        let ovc: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme);
        self.navigationController?.pushViewController(ovc, animated: true);
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
