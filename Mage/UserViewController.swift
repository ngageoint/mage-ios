//
//  UserViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class UserViewWrapperViewController: SwiftUIViewController {
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    var attachmentViewCoordinator: AttachmentViewCoordinator?
    
    var bottomSheet: MDCBottomSheetController?
    var childCoordinators: [NSObject] = []
    
    var scheme: MDCContainerScheming?
    var viewModel: UserViewViewModel
    
    var cancellables: Set<AnyCancellable> = Set()
    
    init(userUri: URL, scheme: MDCContainerScheming?) {
        self.scheme = scheme
        self.viewModel = UserViewViewModel(uri: userUri)
        super.init()
        swiftUIView = AnyView( UserViewSwiftUI(
            viewModel: self.viewModel,
            selectedAttachment: { [weak self] attachmentUri in
                self?.selectedAttachment(attachmentUri)
           },
            selectedObservation: { [weak self] observationUri in
                self?.viewObservation(uri: observationUri)
            },
            viewImage: { [weak self] imageUrl in
                if self?.viewModel.currentUserIsMe ?? false {
                    print("ITS MEEE")
                } else {
                    if let saveNavigationController = self?.navigationController {
                        let coordinator: AttachmentViewCoordinator = AttachmentViewCoordinator(
                            rootViewController: saveNavigationController,
                            url: imageUrl,
                            contentType: "image",
                            delegate: nil,
                            scheme: scheme
                        )
                        self?.childCoordinators.append(coordinator)
                        coordinator.start()
                    }
                }
            }
            /**
             let alert = UIAlertController(title: "Avatar", message: "Change or view your avatar", preferredStyle: .actionSheet);
             alert.addAction(UIAlertAction(title: "View Avatar", style: .default, handler: { (action) in
                 self.presentAvatar();
             }));
             alert.addAction(UIAlertAction(title: "New Avatar Photo", style: .default, handler: { (action) in
                 ExternalDevice.checkCameraPermissions(for: self.navigationController) { (granted) in
                     let picker = UIImagePickerController();
                     picker.delegate = self;
                     picker.allowsEditing = true;
                     picker.sourceType = .camera;
                     picker.cameraDevice = .front;
                     self.navigationController?.present(picker, animated: true, completion: nil);
                 }
             }));
             alert.addAction(UIAlertAction(title: "New Avatar From Gallery", style: .default, handler: { (action) in
                 ExternalDevice.checkGalleryPermissions(for: self.navigationController) { (granted) in
                     let picker = UIImagePickerController();
                     picker.delegate = self;
                     picker.allowsEditing = true;
                     picker.sourceType = .photoLibrary;
                     self.navigationController?.present(picker, animated: true, completion: nil);
                 }
             }));
             alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));

             if let popoverController = alert.popoverPresentationController {
                 popoverController.sourceView = self
                 popoverController.sourceRect = CGRect(x: self.bounds.midX, y: self.bounds.midY, width: 0, height: 0)
                 popoverController.permittedArrowDirections = []
             }
             
             UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.present(alert, animated: true, completion: nil)
             */
        ))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.$user
            .receive(on: DispatchQueue.main)
            .sink { value in
                if let name = value?.name {
                    self.title = name
                }
            }
            .store(in: &cancellables)
    }
    
    func selectedAttachment(_ attachmentUri: URL!) {
        guard let nav = self.navigationController else {
            return;
        }
        Task {
            if let attachment = await attachmentRepository.getAttachment(attachmentUri: attachmentUri) {
                attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: nav, attachment: attachment, delegate: self, scheme: scheme);
                attachmentViewCoordinator?.start();
            }
        }
    }
    
    func viewObservation(uri: URL) {
        let observationView = ObservationFullView(viewModel: ObservationViewViewModel(uri: uri)) { favoritesModel in
            guard let favoritesModel = favoritesModel,
                  let favoriteUsers = favoritesModel.favoriteUsers
            else {
                return
            }
            self.showFavorites(userIds: favoriteUsers)
        } moreActions: {
            Task {
                guard let observation = await self.observationRepository.getObservation(observationUri: uri) else {
                    return
                }
                let actionsSheet: ObservationActionsSheetController = ObservationActionsSheetController(observation: observation, delegate: self);
                actionsSheet.applyTheme(withContainerScheme: self.scheme);
                self.bottomSheet = MDCBottomSheetController(contentViewController: actionsSheet);
                self.navigationController?.present(self.bottomSheet!, animated: true, completion: nil);
            }
        } editObservation: { observationUri in
            Task {
                guard let observation = await self.observationRepository.getObservation(observationUri: observationUri) else {
                    return;
                }
                self.editObservation(observation)
            }
        } selectedAttachment: { attachmentUri in
            self.selectedAttachment(attachmentUri)
        } selectedUnsentAttachment: { localPath, contentType in
            
        }
        
        let ovc2 = SwiftUIViewController(swiftUIView: observationView)
        navigationController?.pushViewController(ovc2, animated: true)
    }
    
    func showFavorites(userIds: [String]) {
        if (userIds.count != 0) {
            let locationViewController = LocationsTableViewController(userIds: userIds, actionsDelegate: nil, scheme: scheme);
            locationViewController.title = "Favorited By";
            self.navigationController?.pushViewController(locationViewController, animated: true);
        }
    }
    
    @objc func editObservation(_ observation: Observation) {
        self.bottomSheet?.dismiss(animated: true, completion: nil);
        let observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: observation);
        observationEditCoordinator.applyTheme(withContainerScheme: self.scheme);
        observationEditCoordinator.start();
        self.childCoordinators.append(observationEditCoordinator)
    }
    
    @objc func cancelAction() {
        bottomSheet?.dismiss(animated: true, completion: nil);
    }
    
}

extension UserViewWrapperViewController: ObservationActionsDelegate {
    
}

extension UserViewWrapperViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil;
    }
}

extension UserViewWrapperViewController: ObservationEditDelegate {
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

@available(*, deprecated, message: "use the swiftui class instead")
class UserViewController : UITableViewController {
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    let user : User?
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
    
    init(userModel:UserModel, scheme: MDCContainerScheming?) {
        let context = NSManagedObjectContext.mr_default()
        self.user = context.performAndWait {
            if let userUri = userModel.userId,
                let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri)
            {
                return try? context.existingObject(with: id) as? User
            }
            return nil
        }
//        self.user = user
        self.scheme = scheme;
        super.init(style: .grouped)
        self.title = user?.name;
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
        let uvc = UserViewController(userModel: UserModel(user: user), scheme: scheme)
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
