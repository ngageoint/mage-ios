//
//  ObservationListWrapperViewController.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class ObservationListNavStack: MageNavStack {
    override func viewDidLoad() {
        super.viewDidLoad()
        let svc = SwiftUIViewController(
            swiftUIView: ObservationList(
            launchFilter: { [weak self] in
                self?.launchFilter()
            }
            )
            .environmentObject(router)
        )
        self.view.addSubview(svc.view)
        setNavBarTitle()
    }
    
    func setNavBarTitle() {
        let timeFilterString = MageFilter.getString();
        self.navigationItem.setTitle("Observations", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
    }
}

class ObservationListWrapperViewController: SwiftUIViewController {
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.currentLocationRepository)
    var currentLocationRepository: CurrentLocationRepository
    
    var router: MageRouter
    
    var scheme: MDCContainerScheming?
    var attachmentViewCoordinator: AttachmentViewCoordinator?
    var bottomSheet: MDCBottomSheetController?
    var childCoordinators: [NSObject] = []
    
    init(scheme: MDCContainerScheming?, router: MageRouter) {
        self.scheme = scheme
        self.router = router
        super.init()
        swiftUIView = AnyView( ObservationList(
            launchFilter: { [weak self] in
                self?.launchFilter()
            }
        ).environmentObject(router))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNavBarTitle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(launchFilter))
    }
    
    func setNavBarTitle() {
        let timeFilterString = MageFilter.getString();
        self.navigationItem.setTitle("Observations", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
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
        let observationView = ObservationFullView(
            viewModel: ObservationViewViewModel(uri: uri)
        ) { favoritesModel in
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
        }
    selectedUnsentAttachment: { localPath, contentType in
            
        }
    .environmentObject(router)
        
        let ovc2 = SwiftUIViewController(swiftUIView: observationView)
        navigationController?.pushViewController(ovc2, animated: true)
    }
    
    func showFavorites(userIds: [String]) {
        if (userIds.count != 0) {
            let locationViewController = LocationsTableViewController(userIds: userIds, actionsDelegate: nil, scheme: scheme, router: router);
            locationViewController.title = "Favorited By";
            self.navigationController?.pushViewController(locationViewController, animated: true);
        }
    }
    
    func startCreateNewObservation(location: CLLocation?, provider: String) {
        var point: SFPoint? = nil;
        var accuracy: CLLocationAccuracy = 0;
        var delta: Double = 0.0;
        
        if let location = location ?? currentLocationRepository.getLastLocation() {
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
    
    @objc func launchFilter() {
        let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil);
        let fvc: ObservationFilterTableViewController = filterStoryboard.instantiateViewController(identifier: "observationFilter");
        fvc.applyTheme(withContainerScheme: self.scheme);
        self.navigationController?.pushViewController(fvc, animated: true);
    }
}

extension ObservationListWrapperViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil;
    }
}

extension ObservationListWrapperViewController: ObservationActionsDelegate {
    func deleteObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        ObservationActionHandler.deleteObservation(observation: observation, viewController: self) { (success, error) in
            self.navigationController?.popViewController(animated: true);
        }
    }
    
    func editObservation(_ observation: Observation) {
        self.bottomSheet?.dismiss(animated: true, completion: nil);
        let observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: observation);
        observationEditCoordinator.applyTheme(withContainerScheme: self.scheme);
        observationEditCoordinator.start();
        self.childCoordinators.append(observationEditCoordinator)
    }
    
    func viewUser(_ user: User) {
        self.bottomSheet?.dismiss(animated: true, completion: nil);
        let uvc = UserViewController(userModel: UserModel(user: user), scheme: scheme, router: router)
        navigationController?.pushViewController(uvc, animated: true)
    }
    
    func cancelAction() {
        bottomSheet?.dismiss(animated: true, completion: nil);
    }
    
}

extension ObservationListWrapperViewController: ObservationEditDelegate {
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
