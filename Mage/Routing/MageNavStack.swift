//
//  MageNavStack.swift
//  MAGE
//
//  Created by Dan Barela on 8/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import Kingfisher

class MageNavStack: UIViewController {
    @Injected(\.currentLocationRepository)
    var currentLocationRepository: CurrentLocationRepository
    
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    var router: MageRouter = MageRouter()
    
    var scheme: MDCContainerScheming?
    var bottomSheet: MDCBottomSheetController?
    var childCoordinators: [NSObject] = []
    
    var navigationControllerObserver: NavigationControllerObserver?
    var cancellables: Set<AnyCancellable> = Set()
    
    var currentPathElementCount = 0
    
    init(scheme: MDCContainerScheming?) {
        self.scheme = scheme
        super.init(nibName: nil, bundle: nil)
        
        router.$path
            .receive(on: DispatchQueue.main)
            .sink { value in
                if value.count > self.currentPathElementCount, let last = value.last {
                    self.currentPathElementCount = value.count
                    switch (last) {
                    case let value as ObservationRoute:
                        self.handleObservationRoute(route: value)
                    case let value as AttachmentRoute:
                        self.handleAttachmentRoute(route: value)
                    case let value as FileRoute:
                        self.handleFileRoute(route: value)
                    default:
                        print("something else")
                    }
                }
                
                print("new value in router path \(value)")
            }
            .store(in: &cancellables)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func handleFileRoute(route: FileRoute) {
        switch(route) {
        case .showCachedImage(cacheKey: let cacheKey):
            let lastIndexOfCache = router.path.lastIndex(where: { element in
                switch element {
                case let value as FileRoute:
                    switch(value) {
                    case .cacheImage(url: let url):
                        if url.absoluteString == cacheKey {
                            return true
                        }
                    default:
                        break
                    }
                default:
                    break
                }
                return false
            })
            
            var vcs: [UIViewController]?
            if let lastIndexOfCache = lastIndexOfCache {
                // we were told to cache this, pop it off the path and replace the view controller without animation
                vcs = navigationController?.viewControllers
                let _ = vcs?.popLast()
                router.path.remove(at: lastIndexOfCache)
                currentPathElementCount = currentPathElementCount - 1
            }
            if let cacheKey = cacheKey {
                let cache = ImageCache.default
                cache.retrieveImage(forKey: cacheKey) { result in
                    switch result {
                    case .success(let value):
                        if let image = value.image, let imageData = image.pngData() {
                            let docsUrl = URL.documentsDirectory
                            
                            let filename = docsUrl.appendingPathComponent("image.png")
                            try? imageData.write(to: filename)
                            if vcs != nil {
                                let ql = DocumentController.shared.getQuickLookViewController(url: filename)
                                self.navigationControllerObserver?.observePopTransition(of: ql, delegate: self)
                                vcs?.append(ql)
                                self.navigationController?.viewControllers = vcs!
                            } else {
                                DocumentController.shared.presentQL(url: filename, viewControllerToPresentFrom: self)
                            }
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        case .showFileImage(filePath: let filePath):
            if let url = URL(string: filePath) {
                DocumentController.shared.presentQL(url: url, viewControllerToPresentFrom: self)
            }
        case .showLocalVideo(filePath: let filePath):
            if let url = URL(string: filePath) {
                let vc = SwiftUIViewController(swiftUIView: VideoView(videoUrl: url))
                self.pushViewController(vc: vc)
            }
        case .showRemoteVideo(url: let url):
            var url2 = url
            url2.append(queryItems: [URLQueryItem(name: "access_token", value: StoredPassword.retrieveStoredToken())])
            let vc = SwiftUIViewController(swiftUIView: VideoView(videoUrl: url2))
            self.pushViewController(vc: vc)
            
        case .showLocalAudio(filePath: let filePath):
            if let url = URL(string: filePath) {
                let vc = SwiftUIViewController(swiftUIView: VideoView(videoUrl: url))
                self.pushViewController(vc: vc)
            }
        case .showRemoteAudio(url: let url):
            var url2 = url
            url2.append(queryItems: [URLQueryItem(name: "access_token", value: StoredPassword.retrieveStoredToken())])
            let vc = SwiftUIViewController(swiftUIView: VideoView(videoUrl: url2))
            self.pushViewController(vc: vc)
            
        case .askToDownload(url: let url):
            let vc = SwiftUIViewController(swiftUIView: AskToDownloadFileView(url: url).environmentObject(router))
            self.pushViewController(vc: vc)
        
        case .downloadFile(url: let url):
            let lastIndexOfCache = router.path.lastIndex(where: { element in
                switch element {
                case let value as FileRoute:
                    switch(value) {
                    case .askToDownload(url: let url):
                        if url == url {
                            return true
                        }
                    default:
                        break
                    }
                default:
                    break
                }
                return false
            })
            
            var vcs: [UIViewController]?
            if let lastIndexOfCache = lastIndexOfCache {
                // we were told to cache this, pop it off the path and replace the view controller without animation
                vcs = navigationController?.viewControllers
                let _ = vcs?.popLast()
                router.path.remove(at: lastIndexOfCache)
                currentPathElementCount = currentPathElementCount - 1
            }
            
            let ovc2 = SwiftUIViewController(swiftUIView: DownloadingFileView(viewModel: DownloadingFileViewModel(url: url, router: router)))
            if vcs != nil {
                self.navigationControllerObserver?.observePopTransition(of: ovc2, delegate: self)
                vcs?.append(ovc2)
                self.navigationController?.viewControllers = vcs!
            } else {
                self.pushViewController(vc: ovc2)
            }
        case .showDownloadedFile(fileUrl: let fileUrl, url: let url):
            let lastIndexOfDownload = router.path.lastIndex(where: { element in
                switch element {
                case let value as FileRoute:
                    switch(value) {
                    case .downloadFile(url: let downloadedUrl):
                        if downloadedUrl == url {
                            return true
                        }
                    default:
                        break
                    }
                default:
                    break
                }
                return false
            })
            
            var vcs: [UIViewController]?
            if let lastIndexOfDownload = lastIndexOfDownload {
                // we were told to download this, pop it off the path and replace the view controller without animation
                vcs = navigationController?.viewControllers
                let _ = vcs?.popLast()
                router.path.remove(at: lastIndexOfDownload)
                currentPathElementCount = currentPathElementCount - 1
            }
            if vcs != nil {
                let ql = DocumentController.shared.getQuickLookViewController(url: fileUrl)
                self.navigationControllerObserver?.observePopTransition(of: ql, delegate: self)
                vcs?.append(ql)
                self.navigationController?.viewControllers = vcs!
            } else {
                DocumentController.shared.presentQL(url: fileUrl, viewControllerToPresentFrom: self)
            }
        case .cacheImage(url: let url):
            let lastIndexOfCache = router.path.lastIndex(where: { element in
                switch element {
                case let value as FileRoute:
                    switch(value) {
                    case .askToCache(url: let url):
                        if url == url {
                            return true
                        }
                    default:
                        break
                    }
                default:
                    break
                }
                return false
            })
            
            var vcs: [UIViewController]?
            if let lastIndexOfCache = lastIndexOfCache {
                // we were told to cache this, pop it off the path and replace the view controller without animation
                vcs = navigationController?.viewControllers
                let _ = vcs?.popLast()
                router.path.remove(at: lastIndexOfCache)
                currentPathElementCount = currentPathElementCount - 1
            }
            
            let ovc2 = SwiftUIViewController(swiftUIView: DownloadingImageView(viewModel: DownloadingImageViewModel(imageUrl: url, router: router)))
            if vcs != nil {
                self.navigationControllerObserver?.observePopTransition(of: ovc2, delegate: self)
                vcs?.append(ovc2)
                self.navigationController?.viewControllers = vcs!
            } else {
                self.pushViewController(vc: ovc2)
            }
        case .askToCache(url: let url):
            let vc = SwiftUIViewController(swiftUIView: AskToCacheImageView(imageUrl: url).environmentObject(router))
            self.pushViewController(vc: vc)
        }
    }
    
    func handleAttachmentRoute(route: AttachmentRoute) {
        switch(route) {
        
        case .askToDownload(attachmentUri: let attachmentUri):
            print("askToDownload")
        case .showVideo(attachmentUri: let attachmentUri):
            print("showVideo")
        case .showAudio(attachmentUri: let attachmentUri):
            print("showAudio")
        case .showFilePreview(attachmentUri: let attachmentUri):
            print("showFilePreview")
        }
    }
    
    func handleObservationRoute(route: ObservationRoute) {
        switch(route) {
            
        case .detail(uri: let uri):
            if let uri = uri {
                self.viewObservation(uri: uri)
            }
        case .create:
            self.startCreateNewObservation(location: self.currentLocationRepository.getLastLocation(), provider: "gps")
        case .edit(uri: let uri):
            if let uri = uri {
                Task { [weak self] in
                    await self?.editObservation(uri: uri)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let nav = self.navigationController {
            self.navigationControllerObserver = NavigationControllerObserver(navigationController: nav)
        }
    }
    
    @objc func launchFilter() {
        let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil);
        let fvc: ObservationFilterTableViewController = filterStoryboard.instantiateViewController(identifier: "observationFilter");
        fvc.applyTheme(withContainerScheme: self.scheme);
        self.pushViewController(vc: fvc)
    }
    
    func pushViewController(vc: UIViewController) {
        self.navigationController?.pushViewController(vc, animated: true)
        self.navigationControllerObserver?.observePopTransition(of: vc, delegate: self)
        
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
    
    func viewObservation(uri: URL) {
        let observationView = ObservationFullView(
            viewModel: ObservationViewViewModel(uri: uri)
//            router: router
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
        self.pushViewController(vc: ovc2)
    }
    
    func showFavorites(userIds: [String]) {
        if (userIds.count != 0) {
            let locationViewController = LocationsTableViewController(userIds: userIds, actionsDelegate: nil, scheme: scheme, router: router);
            locationViewController.title = "Favorited By";
            self.pushViewController(vc: locationViewController)
        }
    }
}

extension MageNavStack: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        router.path.removeLast()
        self.currentPathElementCount = router.path.count
    }
}

extension MageNavStack: ObservationActionsDelegate {
    func deleteObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        ObservationActionHandler.deleteObservation(observation: observation, viewController: self) { (success, error) in
            self.navigationController?.popViewController(animated: true);
        }
    }
    
    func editObservation(uri: URL) async {
        guard let observation = await self.observationRepository.getObservation(observationUri: uri) else {
            return;
        }
        self.editObservation(observation)
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
        self.pushViewController(vc: uvc)
    }
    
    func cancelAction() {
        bottomSheet?.dismiss(animated: true, completion: nil);
    }
    
}

extension MageNavStack: ObservationEditDelegate {
    func editCancel(_ coordinator: NSObject) {
        removeChildCoordinator(coordinator);
        router.path.removeLast()
        self.currentPathElementCount = router.path.count
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        removeChildCoordinator(coordinator);
        router.path.removeLast()
        self.currentPathElementCount = router.path.count
    }
    
    func removeChildCoordinator(_ coordinator: NSObject) {
        if let index = self.childCoordinators.firstIndex(where: { (child) -> Bool in
            return coordinator == child;
        }) {
            self.childCoordinators.remove(at: index);
        }
    }
}

extension MageNavStack: NavigationControllerObserverDelegate {
    func navigationControllerObserver(
        _ observer: NavigationControllerObserver,
        didObservePopTransitionFor viewController: UIViewController
    ) {
        router.path.removeLast()
        self.currentPathElementCount = router.path.count
    }
}
