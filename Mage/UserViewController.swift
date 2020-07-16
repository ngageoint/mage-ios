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
        header.autoSetDimension(.width, toSize: bounds.size.width)
    }
}

@objc class UserViewController : UITableViewController {
    let user : User
    let cellReuseIdentifier = "cell";
    var childCoordinators: Array<NSObject> = [];
    
    private lazy var observationDataStore: ObservationDataStore = {
        let observationDataStore: ObservationDataStore = ObservationDataStore();
        observationDataStore.tableView = self.tableView;
        observationDataStore.observationSelectionDelegate = self;
        observationDataStore.attachmentSelectionDelegate = self;
        return observationDataStore;
    }();
    
    private lazy var userTableHeaderView: UserTableHeaderView = {
        let userTableHeaderView: UserTableHeaderView = UserTableHeaderView();
        userTableHeaderView.navigationController = self.navigationController;
        userTableHeaderView.populate(user: user);
        return userTableHeaderView;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public init(user:User) {
        self.user = user
        super.init(style: .grouped)
        self.title = user.name;
        tableView.register(UINib(nibName: "ObservationCell", bundle: nil), forCellReuseIdentifier: "obsCell");
    }
    
    override func themeDidChange(_ theme: MageTheme) {
        self.navigationController?.navigationBar.barTintColor = UIColor.primary();
        self.navigationController?.navigationBar.tintColor = UIColor.navBarPrimaryText();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160;
        tableView.setAndLayoutTableHeaderView(header: userTableHeaderView);
        
        self.registerForThemeChanges();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        userTableHeaderView.navigationController = self.navigationController;
        observationDataStore.startFetchController(with: Observations.init(for: user));
    }
}

extension UserViewController : ObservationSelectionDelegate {
    func selectedObservation(_ observation: Observation!) {
        let ovc: ObservationViewController_iPhone = ObservationViewController_iPhone();
        ovc.observation = observation;
        self.navigationController?.pushViewController(ovc, animated: true);
    }
    
    func selectedObservation(_ observation: Observation!, region: MKCoordinateRegion) {
        let ovc: ObservationViewController_iPhone = ObservationViewController_iPhone();
        ovc.observation = observation;
        self.navigationController?.pushViewController(ovc, animated: true);
    }
    
    func observationDetailSelected(_ observation: Observation!) {
        let ovc: ObservationViewController_iPhone = ObservationViewController_iPhone();
        ovc.observation = observation;
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
