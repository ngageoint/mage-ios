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
import UIKit
import CoreLocation

class MageNavStack: UIViewController {
    @Injected(\.currentLocationRepository)
    var currentLocationRepository: CurrentLocationRepository
    
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.locationRepository)
    var locationRepository: LocationRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    var router: MageRouter = MageRouter()
    
    var scheme: MDCContainerScheming?
    var bottomSheet: MDCBottomSheetController?
    var childCoordinators: [NSObject] = []
    
    var navigationControllerObserver: NavigationControllerObserver?
    var cancellables: Set<AnyCancellable> = Set()
    
    var currentPathElementCount = 0
    
    var avatarChooserDelegate: UserAvatarChooserDelegate?
    
    init(scheme: MDCContainerScheming?) {
        self.scheme = scheme
        super.init(nibName: nil, bundle: nil)
        
        // Observe navigation path
        router.$path
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else { return }
                
                if value.count > self.currentPathElementCount, let last = value.last {
                    self.currentPathElementCount = value.count
                    
                    switch last {
                    case let value as ObservationRoute:
                        self.handleObservationRoute(route: value)
                    case let value as FileRoute:
                        self.handleFileRoute(route: value)
                    case let value as MageRoute:
                        self.handleMageRoute(route: value)
                    case let value as UserRoute:
                        self.handleUserRoute(route: value)
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe bottom sheet routing
        router.$bottomSheetRoute
            .receive(on: DispatchQueue.main)
            .sink { [weak self] route in
                guard let self else { return }
                
                if let route {
                    self.handleBottomSheetRoute(route: route)
                } else {
                    self.bottomSheet?.dismiss(animated: true)
                }
            }
            .store(in: &cancellables)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    // MARK: User routing
    func handleUserRoute(route: UserRoute) {
        switch route {
        case .detail(uri: let uri):
            guard let uri else { return }
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                if let user = await self.userRepository.getUser(userUri: uri), let userId = user.userId {
                    let uvc = UserViewWrapperViewController(userUri: userId, scheme: self.scheme, router: self.router)
                    self.pushViewController(vc: uvc)
                }
            }
        case .userFromLocation(locationUri: let locationUri):
            guard let locationUri else { return }
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                if let location = await self.locationRepository.getLocation(locationUri: locationUri), let userId = location.userModel?.userId {
                    let uvc = UserViewWrapperViewController(userUri: userId, scheme: self.scheme, router: self.router)
                    self.pushViewController(vc: uvc)
                }
            }
            
        case .showFavoritedUsers(remoteIds: let remoteIds):
            guard !remoteIds.isEmpty else { return }
            
            let locationViewController = LocationListWrapperViewController(userRemoteIds: remoteIds, scheme: scheme, router: router)
            locationViewController.title = "Favorited By"
            pushViewController(vc: locationViewController)
        }
    }
    
    // MARK: - Bottom sheet rounting
    func handleBottomSheetRoute(route: BottomSheetRoute) {
        switch route {
        case .observationMoreActions(observationUri: let uri):
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                // NOTE: This uses the NSManagedObject path. To fully remove the deprecation warning,
                // switch to a model-based initializer in ObservationActionsSheetController.
                guard let observation = await self.observationRepository.getObservationNSManagedObject(observationUri: uri) else {
                    return
                }
                
                let actionsSheet: ObservationActionsSheetController = ObservationActionsSheetController(observation: observation, delegate: self, router: self.router)
                actionsSheet.applyTheme(withContainerScheme: self.scheme)
                
                self.bottomSheet = MDCBottomSheetController(contentViewController: actionsSheet)
                self.bottomSheet?.delegate = self
                
                if let sheet = self.bottomSheet {
                    self.present(sheet, animated: true)
                }
            }
            
        case .userAvatarActions(userUri: let uri):
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                guard let user = await self.userRepository.getUser(userUri: uri) else {
                    return
                }
                
                let alert = UIAlertController(title: "Avatar", message: "Change or view your avatar", preferredStyle: .actionSheet)
                
                if let avatarUrl = user.avatarUrl {
                    alert.addAction(UIAlertAction(title: "View Avatar", style: .default) { [weak self] _ in
                        self?.router.appendRoute(FileRoute.showCachedImage(cacheKey: avatarUrl))
                    })
                }
                
                alert.addAction(UIAlertAction(title: "New Avatar Photo", style: .default) { [weak self] _ in
                    guard let self else { return }
                    
                    ExternalDevice.checkCameraPermissions(for: self.navigationController) { granted in
                        guard granted else { return }
                        
                        let picker = UIImagePickerController()
                        self.avatarChooserDelegate = UserAvatarChooserDelegate(user: user)
                        picker.delegate = self.avatarChooserDelegate
                        picker.allowsEditing = true
                        picker.sourceType = .camera
                        picker.cameraDevice = .front
                        self.present(picker, animated: true)
                    }
                })
                
                alert.addAction(UIAlertAction(title: "New Avatar From Gallery", style: .default) { [weak self] _ in
                    guard let self else { return }
                    
                    ExternalDevice.checkGalleryPermissions(for: self.navigationController) { granted in
                        guard granted else { return }
                        
                        let picker = UIImagePickerController()
                        self.avatarChooserDelegate = UserAvatarChooserDelegate(user: user)
                        picker.delegate = self.avatarChooserDelegate
                        picker.allowsEditing = true
                        picker.sourceType = .photoLibrary
                        self.present(picker, animated: true)
                    }
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                // iPad popover anchor (safe no-op on iPhone)
                if let pop = alert.popoverPresentationController {
                    pop.sourceView = self.view
                    pop.sourceRect = CGRect(x: self.view.bounds.midX,
                                            y: self.view.bounds.midY,
                                            width: 0, height: 0)
                    pop.permittedArrowDirections = []
                }
                
                self.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - App-level routing
    func handleMageRoute(route: MageRoute) {
        switch route {
        case .observationFilter:
            let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil)
            let fvc: ObservationFilterTableViewController = filterStoryboard.instantiateViewController(identifier: "observationFilter")
            fvc.applyTheme(withContainerScheme: self.scheme)
            pushViewController(vc: fvc)
        case .locationFilter:
            let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil)
            let fvc: LocationFilterTableViewController = filterStoryboard.instantiateViewController(identifier: "locationFilter")
            fvc.applyTheme(withContainerScheme: self.scheme)
            pushViewController(vc: fvc)
        }
    }
    
    // MARK: - File routing
    private func fileURL(from maybePath: String?) -> URL? {
        guard let s = maybePath, !s.isEmpty else { return nil }
        
        if s.hasPrefix("file://") {
            return URL(string: s)            // already a file URL string
        } else {
            return URL(fileURLWithPath: s)   // plain filesystem path
        }
    }
    
    func handleFileRoute(route: FileRoute) {
        switch route {
        case .showCachedImage(cacheKey: let cacheKey):
            let lastIndexOfCache = router.path.lastIndex { element in
                if let r = element as? FileRoute, case let .cacheImage(url) = r {
                    return url.absoluteString == cacheKey
                }
                return false
            }
            
            var vcs: [UIViewController]?
            if let lastIndexOfCache {
                // we were told to cache this, pop it off the path and replace the view controller without animation
                vcs = navigationController?.viewControllers
                _ = vcs?.popLast()
                router.path.remove(at: lastIndexOfCache)
                currentPathElementCount -= 1
            }
            
            if let cacheKey {
                let cache = ImageCache.default
                
                cache.retrieveImage(forKey: cacheKey) { result in
                    switch result {
                    case .success(let value):
                        if let image = value.image, let imageData = image.pngData() {
                            let docsUrl = URL.documentsDirectory
                            let filename = docsUrl.appendingPathComponent("image.png")
                            
                            try? imageData.write(to: filename)
                            
                            if var stack = vcs {
                                let ql = DocumentController.shared.getQuickLookViewController(url: filename)
                                self.navigationControllerObserver?.observePopTransition(of: ql, delegate: self)
                                stack.append(ql)
                                self.navigationController?.viewControllers = stack
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
            guard let url = fileURL(from: filePath) else {
                MageLogger.misc.error("Could not convert filePath to URL: \(filePath)")
                return
            }
            DocumentController.shared.presentQL(url: url, viewControllerToPresentFrom: self)
            
        case .showLocalVideo(filePath: let filePath):
            guard let url = fileURL(from: filePath) else {
                MageLogger.misc.error("Could not convert filePath to URL: \(filePath)")
                return
            }
            
            let vc = SwiftUIViewController(swiftUIView: VideoView(videoUrl: url))
            self.pushViewController(vc: vc)
            
        case .showRemoteVideo(url: let url):
            var url2 = AccessTokenURL.tokenized(url)
            let vc = SwiftUIViewController(swiftUIView: VideoView(videoUrl: url2))
            self.pushViewController(vc: vc)
            
        case .showLocalAudio(filePath: let filePath):
            guard let url = fileURL(from: filePath) else {
                MageLogger.misc.error("Could not convert filePath to URL: \(filePath)")
                return
            }
            
            let vc = SwiftUIViewController(swiftUIView: VideoView(videoUrl: url))
            self.pushViewController(vc: vc)
            
        case .showRemoteAudio(url: let url):
            var url2 = AccessTokenURL.tokenized(url)
            let vc = SwiftUIViewController(swiftUIView: VideoView(videoUrl: url2))
            self.pushViewController(vc: vc)
            
        case .askToDownload(url: let url):
            let vc = SwiftUIViewController(swiftUIView: AskToDownloadFileView(url: url).environmentObject(router))
            self.pushViewController(vc: vc)
            
        case .downloadFile(url: let url):
            let target = url
            
            let lastIndexOfAsk = router.path.lastIndex { element in
                if let r = element as? FileRoute, case let .askToDownload(u) = r {
                    return u == target
                }
                return false
            }
            
            var vcs: [UIViewController]?
            
            if let lastIndexOfAsk {
                vcs = navigationController?.viewControllers
                _ = vcs?.popLast()
                router.path.remove(at: lastIndexOfAsk)
                currentPathElementCount -= 1
            }
            
            let ovc2 = SwiftUIViewController(swiftUIView: DownloadingFileView(viewModel: DownloadingFileViewModel(url: url, router: router)))
            if var stack = vcs {
                navigationControllerObserver?.observePopTransition(of: ovc2, delegate: self)
                stack.append(ovc2)
                navigationController?.viewControllers = stack
            } else {
                pushViewController(vc: ovc2)
            }
            
        case .showDownloadedFile(fileUrl: let fileUrl, url: let url):
            let lastIndexOfDownload = router.path.lastIndex { element in
                if let r = element as? FileRoute, case let .downloadFile(downloadedUrl) = r {
                    return downloadedUrl == url
                }
                return false
            }
            
            var vcs: [UIViewController]?
            if let lastIndexOfDownload {
                vcs = navigationController?.viewControllers
                _ = vcs?.popLast()
                router.path.remove(at: lastIndexOfDownload)
                currentPathElementCount -= 1
            }
            
            if var stack = vcs {
                let ql = DocumentController.shared.getQuickLookViewController(url: fileUrl)
                navigationControllerObserver?.observePopTransition(of: ql, delegate: self)
                stack.append(ql)
                navigationController?.viewControllers = stack
            } else {
                DocumentController.shared.presentQL(url: fileUrl, viewControllerToPresentFrom: self)
            }
            
        case .cacheImage(url: let url):
            let target = url
            
            let lastIndexOfAsk = router.path.lastIndex { element in
                if let r = element as? FileRoute, case let .askToCache(u) = r {
                    return u == target
                }
                return false
            }
            
            var vcs: [UIViewController]?
            if let lastIndexOfAsk {
                vcs = navigationController?.viewControllers
                _ = vcs?.popLast()
                router.path.remove(at: lastIndexOfAsk)
                currentPathElementCount -= 1
            }
            
            let ovc2 = SwiftUIViewController(swiftUIView: DownloadingImageView(viewModel: DownloadingImageViewModel(imageUrl: url, router: router)))
            if var stack = vcs {
                navigationControllerObserver?.observePopTransition(of: ovc2, delegate: self)
                stack.append(ovc2)
                navigationController?.viewControllers = stack
            } else {
                pushViewController(vc: ovc2)
            }
            
        case .askToCache(url: let url):
            let vc = SwiftUIViewController(swiftUIView: AskToCacheImageView(imageUrl: url).environmentObject(router))
            pushViewController(vc: vc)
        }
    }
    
    // MARK: - Observation routing
    func handleObservationRoute(route: ObservationRoute) {
        switch route {
        case .detail(uri: let uri):
            if let uri { viewObservation(uri: uri) }
        case .create:
            startCreateNewObservation(location: currentLocationRepository.getLastLocation(), provider: "gps")
        case .edit(uri: let uri):
            if let uri {
                Task { [weak self] in
                    await self?.editObservation(uri: uri)
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if let nav = navigationController {
            navigationControllerObserver = NavigationControllerObserver(navigationController: nav)
        }
    }
    
    @objc func launchFilter() { }
    
    func pushViewController(vc: UIViewController) {
        bottomSheet?.dismiss(animated: true)
        navigationController?.pushViewController(vc, animated: true)
        navigationControllerObserver?.observePopTransition(of: vc, delegate: self)
    }
    
    func startCreateNewObservation(location: CLLocation?, provider: String) {
        var point: SFPoint? = nil
        var accuracy: CLLocationAccuracy = 0
        var delta: Double = 0.0
        
        if let location = location ?? currentLocationRepository.getLastLocation() {
            if location.altitude != 0 {
                point = SFPoint(x: NSDecimalNumber(value: location.coordinate.longitude), andY: NSDecimalNumber(value: location.coordinate.latitude), andZ: NSDecimalNumber(value: location.altitude))
            } else {
                point = SFPoint(x: NSDecimalNumber(value: location.coordinate.longitude), andY: NSDecimalNumber(value: location.coordinate.latitude))
            }
            accuracy = location.horizontalAccuracy
            delta = location.timestamp.timeIntervalSinceNow * -1000
        }
        
        let edit = ObservationEditCoordinator(rootViewController: self, delegate: self, location: point, accuracy: accuracy, provider: provider, delta: delta)
        edit.applyTheme(withContainerScheme: scheme)
        childCoordinators.append(edit)
        edit.start()
    }
    
    func viewObservation(uri: URL) {
        let observationView = ObservationFullView(viewModel: ObservationViewViewModel(uri: uri)) { localPath, contentType in
            // no-op for now
        }
        .environmentObject(router)
        
        let ovc2 = SwiftUIViewController(swiftUIView: observationView)
        pushViewController(vc: ovc2)
    }
}

// MARK: - AttachmentViewDelegate
extension MageNavStack: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        router.path.removeLast()
        currentPathElementCount = router.path.count
    }
}

// MARK: - ObservationActionsDelegate
extension MageNavStack: ObservationActionsDelegate {
    func deleteObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true)
        ObservationActionHandler.deleteObservation(observation: observation, viewController: self) { _, _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func editObservation(uri: URL) async {
        bottomSheet?.dismiss(animated: true)
        // NOTE: NSManagedObject path; see note above to remove deprecation by switching to a model API.
        
        guard let observation = await observationRepository.getObservationNSManagedObject(observationUri: uri) else {
            return
        }
        
        let observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: observation)
        observationEditCoordinator.applyTheme(withContainerScheme: scheme)
        observationEditCoordinator.start()
        childCoordinators.append(observationEditCoordinator)
    }
    
    func editObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true)
        router.appendRoute(ObservationRoute.edit(uri: observation.objectID.uriRepresentation()))
    }
    
    func cancelAction() {
        bottomSheet?.dismiss(animated: true)
    }
}

// MARK: - ObservationEditDelegate
extension MageNavStack: ObservationEditDelegate {
    func editCancel(_ coordinator: NSObject) {
        removeChildCoordinator(coordinator)
        router.path.removeLast()
        currentPathElementCount = router.path.count
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        removeChildCoordinator(coordinator)
        router.path.removeLast()
        currentPathElementCount = router.path.count
    }
    
    func removeChildCoordinator(_ coordinator: NSObject) {
        if let index = self.childCoordinators.firstIndex(where: { $0 == coordinator}) {
            childCoordinators.remove(at: index)
        }
    }
}

// MARK: - NavigationControllerObserverDelegate
extension MageNavStack: NavigationControllerObserverDelegate {
    func navigationControllerObserver(_ observer: NavigationControllerObserver, didObservePopTransitionFor viewController: UIViewController) {
        router.path.removeLast()
        currentPathElementCount = router.path.count
    }
}

// MARK: - MDCBottomSheetControllerDelegate
extension MageNavStack: MDCBottomSheetControllerDelegate {
    func bottomSheetControllerDidDismissBottomSheet(_ controller: MDCBottomSheetController) {
        router.bottomSheetRoute = nil
    }
}
