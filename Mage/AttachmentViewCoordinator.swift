//
//  AttachmentViewCoordinator.m
//  MAGE
//
//  Created by Daniel Barela on 3/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import AVKit
import MagicalRecord
import Kingfisher
import QuickLook

@objc protocol AttachmentViewDelegate {
    @objc func doneViewing(coordinator: NSObject)
}

@objc class AttachmentViewCoordinator: NSObject, NavigationControllerObserverDelegate, AskToDownloadDelegate {
    @Injected(\.attachmentRepository) var attachmentRepository: AttachmentRepository
    @Injected(\.attachmentLocalDataSource) private var localSD: AttachmentLocalDataSource

    var scheme: MDCContainerScheming?

    var attachment: AttachmentModel?
    weak var delegate: AttachmentViewDelegate?
    var rootViewController: UINavigationController
    var navigationControllerObserver: NavigationControllerObserver
    var tempFile: String?
    var contentType: String?

    var mediaPreviewController: MediaPreviewController?
    var imageViewController: ImageAttachmentViewController?
    var observer: NSKeyValueObservation?

    var urlToLoad: URL?
    var fullAudioDataLength: Int = 0

    var hasPushedViewController: Bool = false
    var ignoreNextDelegateCall: Bool = false

    // MARK: - Helpers

    private func healedLocalURL(for att: AttachmentModel?) -> URL? {
        guard let att else { return nil }
        return AttachmentPath.localURL(fromStored: att.localPath, fileName: att.name)
    }

    @inline(__always)
    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    // MARK: - Init

    @objc public init(rootViewController: UINavigationController, attachment: AttachmentModel, delegate: AttachmentViewDelegate?, scheme: MDCContainerScheming?, navigationControllerObserver: NavigationControllerObserver? = nil) {
        self.rootViewController = rootViewController
        self.attachment = attachment
        self.delegate = delegate
        self.scheme = scheme
        contentType = attachment.contentType

        if let attachmentUrl = self.attachment?.url {
            self.tempFile = NSTemporaryDirectory() + (URL(string: attachmentUrl)?.lastPathComponent ?? "tempfile")
        } else {
            self.tempFile = NSTemporaryDirectory() + "tempfile"
        }
        self.navigationControllerObserver = navigationControllerObserver ?? NavigationControllerObserver(navigationController: self.rootViewController)
        super.init()
    }

    @objc public init(rootViewController: UINavigationController, url: URL, contentType: String, delegate: AttachmentViewDelegate?, scheme: MDCContainerScheming?, navigationControllerObserver: NavigationControllerObserver? = nil) {
        self.rootViewController = rootViewController
        self.urlToLoad = url
        self.delegate = delegate
        self.scheme = scheme
        self.contentType = contentType
        self.tempFile = NSTemporaryDirectory() + url.lastPathComponent

        self.navigationControllerObserver = navigationControllerObserver ?? NavigationControllerObserver(navigationController: self.rootViewController)
        super.init()
    }

    // MARK: - Flow

    @objc public func start() { start(true) }

    @objc public func start(_ animated: Bool = true) {
        onMain {
            if UIDevice.current.userInterfaceIdiom == .pad {
                let navigationController = UINavigationController()
                navigationController.view.backgroundColor = self.scheme?.colorScheme.surfaceColor
                self.rootViewController.present(navigationController, animated: animated, completion: nil)
                self.rootViewController = navigationController
            }
            if let theAttachment = self.attachment {
                // Prefer healed local URL over raw string checks
                if self.healedLocalURL(for: theAttachment) != nil || DataConnectionUtilities.shouldFetchAttachments() {
                    self.showAttachment(animated: animated)
                } else {
                    let vc = AskToDownloadViewController(attachment: theAttachment, delegate: self)
                    vc.applyTheme(withContainerScheme: self.scheme)
                    self.rootViewController.pushViewController(vc, animated: animated)
                    self.navigationControllerObserver.observePopTransition(of: vc, delegate: self)
                    self.hasPushedViewController = true
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
                            image: UIImage(systemName: "xmark"), style: .plain,
                            target: self, action: #selector(self.dismiss(_:))
                        )
                    }
                }
            } else if let urlToLoad = self.urlToLoad {
                if urlToLoad.isFileURL || DataConnectionUtilities.shouldFetchAvatars() || ImageCache.default.isCached(forKey: urlToLoad.absoluteString) {
                    self.loadURL(animated: animated)
                } else {
                    let vc = AskToDownloadViewController(url: urlToLoad, delegate: self)
                    vc.applyTheme(withContainerScheme: self.scheme)
                    self.rootViewController.pushViewController(vc, animated: animated)
                    self.navigationControllerObserver.observePopTransition(of: vc, delegate: self)
                    self.hasPushedViewController = true
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
                            image: UIImage(systemName: "xmark"), style: .plain,
                            target: self, action: #selector(self.dismiss(_:))
                        )
                    }
                }
            }
        }
    }

    @objc public func setAttachment(attachment: AttachmentModel) {
        self.attachment = attachment
        onMain {
            if self.hasPushedViewController {
                self.ignoreNextDelegateCall = true
                FadeTransitionSegue.addFadeTransition(to: self.rootViewController.view)
                self.rootViewController.popViewController(animated: false)
            }
            self.start(false)
        }
    }

    private func loadURL(animated: Bool = false) {
        guard let urlToLoad = self.urlToLoad, let contentType = self.contentType else { return }
        onMain {
            if contentType.isImageContentType {
                let imageVC = ImageAttachmentViewController(url: urlToLoad)
                imageVC.view.backgroundColor = .black
                self.rootViewController.pushViewController(imageVC, animated: animated)
                self.navigationControllerObserver.observePopTransition(of: imageVC, delegate: self)
                self.hasPushedViewController = true
                self.imageViewController = imageVC
                if UIDevice.current.userInterfaceIdiom == .pad {
                    imageVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
                        image: UIImage(systemName: "xmark"), style: .plain,
                        target: self, action: #selector(self.dismiss(_:))
                    )
                }
            } else if contentType.isVideoContentType || contentType.isAudioContentType {
                self.playAudioVideo()
            }
        }
    }

    func downloadApproved() {
        MageLogger.misc.debug("Download the attachment")
        onMain {
            FadeTransitionSegue.addFadeTransition(to: self.rootViewController.view)
            self.ignoreNextDelegateCall = true
            self.rootViewController.popViewController(animated: false)
            if self.attachment != nil {
                self.showAttachment()
            } else {
                self.loadURL()
            }
        }
    }

    private func showAttachment(animated: Bool = false) {
        guard let attachment = self.attachment, let contentType = attachment.contentType else { return }
        onMain {
            if contentType.isImageContentType {
                let imageVC = ImageAttachmentViewController(attachment: attachment)
                imageVC.view.backgroundColor = .black
                self.rootViewController.pushViewController(imageVC, animated: animated)
                self.navigationControllerObserver.observePopTransition(of: imageVC, delegate: self)
                self.hasPushedViewController = true
                self.imageViewController = imageVC
                if UIDevice.current.userInterfaceIdiom == .pad {
                    imageVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
                        image: UIImage(systemName: "xmark"), style: .plain,
                        target: self, action: #selector(self.dismiss(_:))
                    )
                }
                return
            }

            if contentType.isVideoContentType || contentType.isAudioContentType {
                self.playAudioVideo()
                return
            }

            // Other file types
            var url: URL?
            if let localURL = self.healedLocalURL(for: attachment) {
                url = localURL
            } else if let s = attachment.url, let remote = URL(string: s) {
                url = AccessTokenURL.tokenized(remote)
            }

            if let url {
                self.mediaPreviewController = MediaPreviewController(
                    fileName: attachment.name ?? "file",
                    mediaTitle: attachment.name ?? "file",
                    data: nil,
                    url: url,
                    mediaLoaderDelegate: self,
                    scheme: self.scheme
                )
                self.rootViewController.pushViewController(self.mediaPreviewController!, animated: true)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    self.mediaPreviewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(
                        image: UIImage(systemName: "xmark"), style: .plain,
                        target: self, action: #selector(self.dismiss(_:))
                    )
                }
            } else {
                MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Unable to open attachment \(attachment.name ?? "file")"))
            }
        }
    }

    private func playAudioVideo() {
        var name = "file"
        if let attachment = self.attachment {
            name = attachment.name ?? "file"
            if let localURL = healedLocalURL(for: attachment) {
                MageLogger.misc.debug("Playing locally: \(localURL.path)")
                self.urlToLoad = localURL
            } else if let s = attachment.url, let remote = URL(string: s) {
                MageLogger.misc.debug("Playing from link \(remote.absoluteString)")
                self.urlToLoad = AccessTokenURL.tokenized(remote)
            }
        }

        guard let urlToLoad = self.urlToLoad else { return }

        onMain {
            self.mediaPreviewController = MediaPreviewController(
                fileName: name, mediaTitle: name, data: nil, url: urlToLoad,
                mediaLoaderDelegate: self, scheme: self.scheme
            )
            self.rootViewController.pushViewController(self.mediaPreviewController!, animated: true)
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.mediaPreviewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: "xmark"), style: .plain,
                    target: self, action: #selector(self.dismiss(_:))
                )
            }
        }
    }

    // MARK: - NavigationControllerObserverDelegate (must remain nonisolated)

    func navigationControllerObserver(_ observer: NavigationControllerObserver, didObservePopTransitionFor viewController: UIViewController) {
        onMain {
            if !self.ignoreNextDelegateCall {
                self.delegate?.doneViewing(coordinator: self)
            }
            self.ignoreNextDelegateCall = false
        }
    }

    @objc func dismiss(_ sender: UIBarButtonItem) {
        onMain {
            self.rootViewController.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - AVAssetResourceLoaderDelegate
extension AttachmentViewCoordinator: AVAssetResourceLoaderDelegate {}

// MARK: - MediaLoaderDelegate (must remain nonisolated)
extension AttachmentViewCoordinator: MediaLoaderDelegate {
    func mediaLoadComplete(filePath: String, newFile: Bool) {
        MageLogger.misc.debug("BBB: Media load complete")
        guard newFile else { return }

        // Update in-memory model for immediate UI
        let relative = AttachmentPath.stripToDocumentsRelative(filePath)
        self.attachment?.localPath = relative

        // Persist to Core Data (normalization happens inside)
        attachmentRepository.saveLocalPath(attachmentUri: attachment?.attachmentUri, localPath: filePath)
        // or: localSD.saveLocalPath(attachmentUri: attachment?.attachmentUri, localPath: filePath)
    }
}
