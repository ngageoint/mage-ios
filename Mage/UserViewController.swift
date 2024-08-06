//
//  UserViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class UserViewController : UITableViewController {
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    let user : User
    let cellReuseIdentifier = "cell";
    var childCoordinators: Array<NSObject> = [];
    var scheme : MDCContainerScheming?;
    var bottomSheet: MDCBottomSheetController?
    
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
    
    init(user:User, scheme: MDCContainerScheming?) {
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
        let observationView = ObservationFullView(viewModel: ObservationViewViewModel(uri: observation.objectID.uriRepresentation())) { favoritesModel in
            guard let favoritesModel = favoritesModel,
                  let favoriteUsers = favoritesModel.favoriteUsers
            else {
                return
            }
            self.showFavorites(userIds: favoriteUsers)
        } moreActions: {
            let actionsSheet: ObservationActionsSheetController = ObservationActionsSheetController(observation: observation, delegate: self);
            actionsSheet.applyTheme(withContainerScheme: self.scheme);
            self.bottomSheet = MDCBottomSheetController(contentViewController: actionsSheet);
            self.navigationController?.present(self.bottomSheet!, animated: true, completion: nil);
        } editObservation: { observationUri in
            Task {
                guard let observation = await self.observationRepository.getObservation(observationUri: observationUri) else {
                    return;
                }
                let observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: observation);
                observationEditCoordinator.applyTheme(withContainerScheme: self.scheme);
                observationEditCoordinator.start();
                self.childCoordinators.append(observationEditCoordinator)

            }
        } selectedAttachment: { attachmentUri in
            self.selectedAttachment(attachmentUri)
        } selectedUnsentAttachment: { localPath, contentType in
            
        }

        let ovc2 = SwiftUIViewController(swiftUIView: observationView)
        navigationController?.pushViewController(ovc2, animated: true)
    }
    
    func favoriteObservation(_ observation: Observation, completion: ((Observation?) -> Void)?) {
        ObservationActions.favorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: userRepository.getCurrentUser()?.remoteId)()
    }
    
    func copyLocation(_ locationString: String) {
        UIPasteboard.general.string = locationString;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location \(locationString) copied to clipboard"))
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView? = nil) {
        guard let observationLocation = observation.location else {
            return;
        }
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: UIImage(named: "observations"), coordinate: observationLocation.coordinate))
        }));
        ObservationActionHandler.getDirections(latitude: observationLocation.coordinate.latitude, longitude: observationLocation.coordinate.longitude, title: "Observation", viewController: self, extraActions: extraActions, sourceView: sourceView);
    }
    
    func showFavorites(userIds: [String]) {
        if (userIds.count != 0) {
            let locationViewController = LocationsTableViewController(userIds: userIds, actionsDelegate: nil, scheme: scheme);
            locationViewController.title = "Favorited By";
            self.navigationController?.pushViewController(locationViewController, animated: true);
        }
    }
    
    func viewUser(_ user: User) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let uvc = UserViewController(user: user, scheme: scheme)
        navigationController?.pushViewController(uvc, animated: true)
    }
}

extension UserViewController : AttachmentSelectionDelegate {
    func selectedAttachment(_ attachmentUri: URL!) {
        guard let nav = self.navigationController else {
            return;
        }
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                let attachmentCoordinator: AttachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self, scheme: scheme);
                childCoordinators.append(attachmentCoordinator);
                attachmentCoordinator.start();
            }
        }
    }
    
    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable : Any]!) {
        let attachmentCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, url: URL(fileURLWithPath: unsentAttachment["localPath"] as! String), contentType:(unsentAttachment["contentType"] as! String), delegate: self, scheme: scheme);
        self.childCoordinators.append(attachmentCoordinator);
        attachmentCoordinator.start();
    }
    
    func selectedNotCachedAttachment(_ attachmentUri: URL!, completionHandler handler: ((Bool) -> Void)!) {
        guard let nav = self.navigationController else {
            return;
        }
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                let attachmentCoordinator: AttachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self, scheme: scheme);
                childCoordinators.append(attachmentCoordinator);
                attachmentCoordinator.start();
            }
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

extension UserViewController: ObservationEditDelegate {
    func editCancel(_ coordinator: NSObject) {
        removeChildCoordinator(coordinator);
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        removeChildCoordinator(coordinator);
    }
    
    func removeChildCoordinator(_ coordinator: NSObject) {
        if let index = self.childCoordinators.firstIndex(where: { (child) -> Bool in
            return coordinator == child;
        }) {
            self.childCoordinators.remove(at: index);
        }
    }
}
