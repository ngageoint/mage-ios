//
//  AttachmentViewCoordinator.m
//  MAGE
//
//  Created by Daniel Barela on 3/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import AVKit;
import Kingfisher
import QuickLook

@objc protocol AttachmentViewDelegate {
    @objc func doneViewing(coordinator: NSObject);
}

@objc class AttachmentViewCoordinator: NSObject, NavigationControllerObserverDelegate, AskToDownloadDelegate {
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    var scheme: MDCContainerScheming?;

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
    var fullAudioDataLength: Int = 0;
    
    var hasPushedViewController: Bool = false;
    var ignoreNextDelegateCall: Bool = false;
    
    @objc public init(rootViewController: UINavigationController, attachment: AttachmentModel, delegate: AttachmentViewDelegate?, scheme: MDCContainerScheming?, navigationControllerObserver: NavigationControllerObserver? = nil) {
        self.rootViewController = rootViewController;
        self.attachment = attachment;
        self.delegate = delegate;
        self.scheme = scheme;
        contentType = attachment.contentType
        
        if let attachmentUrl = self.attachment?.url {
            self.tempFile =  NSTemporaryDirectory() + (URL(string: attachmentUrl)?.lastPathComponent ?? "tempfile");
        } else {
            self.tempFile =  NSTemporaryDirectory() + "tempfile";
        }
        self.navigationControllerObserver = navigationControllerObserver ?? NavigationControllerObserver(navigationController: self.rootViewController);
        super.init();
    }
    
    @objc public init(rootViewController: UINavigationController, url: URL, contentType: String, delegate: AttachmentViewDelegate?, scheme: MDCContainerScheming?, navigationControllerObserver: NavigationControllerObserver? = nil) {
        self.rootViewController = rootViewController;
        self.urlToLoad = url;
        self.delegate = delegate;
        self.scheme = scheme;
        self.contentType = contentType;
        self.tempFile =  NSTemporaryDirectory() + url.lastPathComponent;
        
        self.navigationControllerObserver = navigationControllerObserver ?? NavigationControllerObserver(navigationController: self.rootViewController);
        super.init();
    }
    
    @objc public func start() {
        self.start(true);
    }
    
    @objc public func start(_ animated: Bool = true) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let navigationController = UINavigationController();
            navigationController.view.backgroundColor = scheme?.colorScheme.surfaceColor
            self.rootViewController.present(navigationController, animated: animated, completion: nil);
            self.rootViewController = navigationController;
        }
        if let theAttachment = self.attachment {
            if ((theAttachment.localPath != nil
                && FileManager.default.fileExists(atPath: theAttachment.localPath!) == true)
                || DataConnectionUtilities.shouldFetchAttachments()) {
                return self.showAttachment(animated: animated);
            } else {
                let vc: AskToDownloadViewController = AskToDownloadViewController(attachment: theAttachment, delegate: self);
                vc.applyTheme(withContainerScheme: scheme);
                self.rootViewController.pushViewController(vc, animated: animated);
                self.navigationControllerObserver.observePopTransition(of: vc, delegate: self);
                self.hasPushedViewController = true;
                if UIDevice.current.userInterfaceIdiom == .pad {
                    vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
                }
            }
        } else if let urlToLoad = self.urlToLoad {
            if (urlToLoad.isFileURL == true || DataConnectionUtilities.shouldFetchAvatars() ||
                ImageCache.default.isCached(forKey: urlToLoad.absoluteString)
            ) {
                return self.loadURL(animated: animated);
            } else {
                let vc: AskToDownloadViewController = AskToDownloadViewController(url: urlToLoad, delegate: self);
                vc.applyTheme(withContainerScheme: scheme);
                self.rootViewController.pushViewController(vc, animated: animated);
                self.navigationControllerObserver.observePopTransition(of: vc, delegate: self);
                self.hasPushedViewController = true;
                if UIDevice.current.userInterfaceIdiom == .pad {
                    vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
                }
            }
        }
    }
    
    @objc public func setAttachment(attachment: AttachmentModel) {
        self.attachment = attachment;
        if (hasPushedViewController) {
            self.ignoreNextDelegateCall = true;
            FadeTransitionSegue.addFadeTransition(to: self.rootViewController.view);
            self.rootViewController.popViewController(animated: false);
        }
        start(false);
    }
    
    func loadURL(animated: Bool = false) {
        if let urlToLoad = self.urlToLoad, let contentType = self.contentType {
            if contentType.hasPrefix("image") {
                let imageViewController = ImageAttachmentViewController(url: urlToLoad)
                imageViewController.view.backgroundColor = UIColor.black;
                self.rootViewController.pushViewController(imageViewController, animated: animated);
                self.navigationControllerObserver.observePopTransition(of: imageViewController, delegate: self);
                self.hasPushedViewController = true;
                self.imageViewController = imageViewController;
                if UIDevice.current.userInterfaceIdiom == .pad {
                    self.imageViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
                }
            } else if contentType.hasPrefix("video") {
                self.playAudioVideo();
            } else if contentType.hasPrefix("audio") {
                self.playAudioVideo();
            }
        }
    }
    
    func showAttachment(animated: Bool = false) {
        if let attachment = self.attachment, let contentType = attachment.contentType {
            if contentType.hasPrefix("image") {
                let imageViewController = ImageAttachmentViewController(attachment: attachment);
                // not sure if we still need this TODO test
                imageViewController.view.backgroundColor = UIColor.black;
                self.rootViewController.pushViewController(imageViewController, animated: animated);
                self.navigationControllerObserver.observePopTransition(of: imageViewController, delegate: self);
                self.hasPushedViewController = true;
                self.imageViewController = imageViewController;
                if UIDevice.current.userInterfaceIdiom == .pad {
                    self.imageViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
                }
            } else if contentType.hasPrefix("video") {
                self.playAudioVideo();
            } else if contentType.hasPrefix("audio") {
                self.playAudioVideo();
            } else {
                var url: URL?
                if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
                    url = URL(fileURLWithPath: localPath)
                } else if let attachmentUrl = attachment.url {
                    if let attachmentUrl = URL(string: attachmentUrl) {
                        let token: String = StoredPassword.retrieveStoredToken()

                        var urlComponents: URLComponents? = URLComponents(url: attachmentUrl, resolvingAgainstBaseURL: false);
                        if (urlComponents?.queryItems) != nil {
                            urlComponents?.queryItems?.append(URLQueryItem(name: "access_token", value: token));
                        } else {
                            urlComponents?.queryItems = [URLQueryItem(name:"access_token", value:token)];
                        }
                        url = (urlComponents?.url)!;
                    }
                }
                if let url = url {
                    mediaPreviewController = MediaPreviewController(fileName: attachment.name ?? "file", mediaTitle: attachment.name ?? "file", data: nil, url: url, mediaLoaderDelegate: self, scheme: scheme)
                    self.rootViewController.pushViewController(mediaPreviewController!, animated: true)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        self.mediaPreviewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
                    }
                } else {
                    MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Unable to open attachment \(attachment.name ?? "file")"))
                }
            }
        }
    }
    
    func downloadApproved() {
        MageLogger.misc.debug("Download the attachment")
        FadeTransitionSegue.addFadeTransition(to: self.rootViewController.view);
        self.ignoreNextDelegateCall = true;
        self.rootViewController.popViewController(animated: false);
        if (self.attachment != nil) {
            self.showAttachment();
        } else {
            self.loadURL();
        }
    }
    
    func playAudioVideo() {
        var name = "file"
        if let attachment = self.attachment {
            name = attachment.name ?? "file"
            if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
                MageLogger.misc.debug("Playing locally: \(localPath)");
                self.urlToLoad = URL(fileURLWithPath: localPath);
            } else if let attachmentUrl = attachment.url {
                MageLogger.misc.debug("Playing from link \(attachmentUrl)");
                let token: String = StoredPassword.retrieveStoredToken();

                if let url = URL(string: attachmentUrl) {
                    var urlComponents: URLComponents? = URLComponents(url: url, resolvingAgainstBaseURL: false);
                    if (urlComponents?.queryItems) != nil {
                        urlComponents?.queryItems?.append(URLQueryItem(name: "access_token", value: token));
                    } else {
                        urlComponents?.queryItems = [URLQueryItem(name:"access_token", value:token)];
                    }
                    self.urlToLoad = (urlComponents?.url)!;
                }
            }
        }
        
        guard let urlToLoad = self.urlToLoad else {
            return;
        }
        
        mediaPreviewController = MediaPreviewController(fileName: name, mediaTitle: name, data: nil, url: urlToLoad, mediaLoaderDelegate: self, scheme: scheme)
        self.rootViewController.pushViewController(mediaPreviewController!, animated: true)
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.mediaPreviewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.dismiss(_ :)))
        }
    }
 
    func navigationControllerObserver(_ observer: NavigationControllerObserver, didObservePopTransitionFor viewController: UIViewController) {
        if (!self.ignoreNextDelegateCall) {
            self.delegate?.doneViewing(coordinator: self);
        }
        self.ignoreNextDelegateCall = false;
    }
    
    func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
    
    @objc func dismiss(_ sender: UIBarButtonItem) {
        self.rootViewController.dismiss(animated: true, completion: nil)
    }
}

// no implementation of the delegate is needed
// this is only here to allow the export session to not fail if the user wants to export the video
extension AttachmentViewCoordinator : AVAssetResourceLoaderDelegate {
    
}

extension AttachmentViewCoordinator : MediaLoaderDelegate {
    func mediaLoadComplete(filePath: String, newFile: Bool) {
        MageLogger.misc.debug("Media load complete");
        if (newFile) {
            attachmentRepository.saveLocalPath(attachmentUri: attachment?.attachmentUri, localPath: filePath)
        }
    }
}
