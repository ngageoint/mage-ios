//
//  UserWrapperViewController.swift
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
    
    var bottomSheet: BottomSheetViewController?
    var childCoordinators: [NSObject] = []
    
    var scheme: AppContainerScheming?
    var viewModel: UserViewViewModel
    
    var router: MageRouter
    
    var cancellables: Set<AnyCancellable> = Set()
    
    init(userUri: URL, scheme: AppContainerScheming?, router: MageRouter) {
        self.router = router
        self.scheme = scheme
        self.viewModel = UserViewViewModel(uri: userUri)
        super.init()
        swiftUIView = AnyView( UserViewSwiftUI(
            viewModel: self.viewModel
        )
            .environmentObject(router)
        )
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
        let observationView = ObservationFullView(viewModel: ObservationViewViewModel(uri: uri)) { localPath, contentType in
            
        }
    .environmentObject(router)
        
        let ovc2 = SwiftUIViewController(swiftUIView: observationView)
        navigationController?.pushViewController(ovc2, animated: true)
    }
    
//    func showFavorites(userIds: [String]) {
//        if (userIds.count != 0) {
//            let locationViewController = LocationsTableViewController(userIds: userIds, actionsDelegate: nil, scheme: scheme, router: router);
//            locationViewController.title = "Favorited By";
//            self.navigationController?.pushViewController(locationViewController, animated: true);
//        }
//    }
    
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
