//
//  AttachmentViewCoordinator.m
//  MAGE
//
//  Created by Daniel Barela on 3/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import AVKit;
import MagicalRecord;

@objc protocol AttachmentViewDelegate {
    @objc func doneViewing(coordinator: NSObject);
}

@objc class AttachmentViewCoordinator: NSObject, MediaLoaderDelegate, NavigationControllerObserverDelegate, AskToDownloadDelegate {
    var scheme: MDCContainerScheming?;

    var attachment: Attachment!
    var delegate: AttachmentViewDelegate?
    var rootViewController: UINavigationController
    var navigationControllerObserver: NavigationControllerObserver
    var tempFile: String?
    
    var playerViewController: AVPlayerViewController?
    var player: AVPlayer?
    var imageViewController: ImageAttachmentViewController?
    var observer: NSKeyValueObservation?
    
    var urlToLoad: URL?
    var fullAudioDataLength: Int = 0;
    
    var mediaLoader: MediaLoader?;
    var activityIndicator: UIActivityIndicatorView!
    var hasPushedViewController: Bool = false;
    var ignoreNextDelegateCall: Bool = false;
    
    @objc public init(rootViewController: UINavigationController, attachment: Attachment, delegate: AttachmentViewDelegate?, scheme: MDCContainerScheming?) {
        self.rootViewController = rootViewController;
        self.attachment = attachment;
        self.delegate = delegate;
        self.scheme = scheme;
        
        if let attachmentUrl = self.attachment.url {
            self.tempFile =  NSTemporaryDirectory() + (URL(string: attachmentUrl)?.lastPathComponent ?? "tempfile");
        } else {
            self.tempFile =  NSTemporaryDirectory() + "tempfile";
        }
        self.navigationControllerObserver = NavigationControllerObserver(navigationController: self.rootViewController);
        super.init();
        self.mediaLoader = MediaLoader(delegate: self);
    }
    
    @objc public init(rootViewController: UINavigationController, url: URL, delegate: AttachmentViewDelegate?, scheme: MDCContainerScheming?) {
        self.rootViewController = rootViewController;
        self.urlToLoad = url;
        self.delegate = delegate;
        self.scheme = scheme;
        
        self.navigationControllerObserver = NavigationControllerObserver(navigationController: self.rootViewController);
        super.init();
    }
    
    @objc public func start() {
        self.start(true);
    }
    
    @objc public func start(_ animated: Bool = true) {
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
            }
        } else if let urlToLoad = self.urlToLoad {
            if (urlToLoad.isFileURL == true || DataConnectionUtilities.shouldFetchAvatars()) {
                return self.loadURL(animated: animated);
            } else {
                let vc: AskToDownloadViewController = AskToDownloadViewController(url: urlToLoad, delegate: self);
                vc.applyTheme(withContainerScheme: scheme);
                self.rootViewController.pushViewController(vc, animated: animated);
                self.navigationControllerObserver.observePopTransition(of: vc, delegate: self);
                self.hasPushedViewController = true;
            }
        }
    }
    
    @objc public func setAttachment(attachment: Attachment) {
        self.attachment = attachment;
        if (hasPushedViewController) {
            self.ignoreNextDelegateCall = true;
            FadeTransitionSegue.addFadeTransition(to: self.rootViewController.view);
            self.rootViewController.popViewController(animated: false);
        }
        start(false);
    }
    
    func loadURL(animated: Bool = false) {
        if let urlToLoad = self.urlToLoad {
            let imageViewController = ImageAttachmentViewController(url: urlToLoad)
            imageViewController.view.backgroundColor = UIColor.black;
            self.rootViewController.pushViewController(imageViewController, animated: animated);
            self.navigationControllerObserver.observePopTransition(of: imageViewController, delegate: self);
            self.hasPushedViewController = true;
            self.imageViewController = imageViewController;
        }
    }
    
    func showAttachment(animated: Bool = false) {
        if let contentType = self.attachment.contentType {
            if contentType.hasPrefix("image") {
                let imageViewController = ImageAttachmentViewController(attachment: self.attachment);
                // not sure if we still need this TODO test
                imageViewController.view.backgroundColor = UIColor.black;
                self.rootViewController.pushViewController(imageViewController, animated: animated);
                self.navigationControllerObserver.observePopTransition(of: imageViewController, delegate: self);
                self.hasPushedViewController = true;
                self.imageViewController = imageViewController;
            } else if contentType.hasPrefix("video") {
                self.playAudioVideo();
            } else if contentType.hasPrefix("audio") {
                self.downloadAudio();
            }
        }
    }
    
    func downloadApproved() {
        print("Download the attachment")
        FadeTransitionSegue.addFadeTransition(to: self.rootViewController.view);
        self.ignoreNextDelegateCall = true;
        self.rootViewController.popViewController(animated: false);
        if (self.attachment != nil) {
            self.showAttachment();
        } else {
            self.loadURL();
        }
    }
    
    func downloadAudio() {
        if let localPath = self.attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
            self.playAudioVideo();
            return;
        }
        if let attachmentUrl = self.attachment.url, let urlToLoad = URL(string: String(format: "%@", attachmentUrl)) {
            print("playing audio:", String(format: "%@", attachmentUrl));
            self.urlToLoad = urlToLoad
            if let name = attachment.name {
                self.tempFile = (self.tempFile ?? "") + "_" + name;
            } else if let contentType = attachment.contentType, let ext = (UTTypeCopyPreferredTagWithClass(contentType as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue()) {
                self.tempFile = (self.tempFile ?? "") + "." + String(ext);
            } else {
                self.tempFile = (self.tempFile ?? "") + ".mp3";
            }
            self.mediaLoader?.downloadAudio(toFile: self.tempFile ?? "", from: urlToLoad);
        }
    }
    
    func playAudioVideo() {
        if let localPath = self.attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
            print("Playing locally", localPath);
            self.urlToLoad = URL(fileURLWithPath: localPath);
        } else if let attachmentUrl = self.attachment.url {
            print("Playing from link");
            self.urlToLoad = URL(string: attachmentUrl);
        }
        
        guard let urlToLoad = self.urlToLoad, let playerItem = self.mediaLoader?.createPlayerItem(from: urlToLoad, toFile: self.tempFile) else {
            return;
        }
        
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        
        let player = AVPlayer(playerItem: playerItem);
        self.player = player;
        
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        player.automaticallyWaitsToMinimizeStalling = false;

        let playerViewController = AVPlayerViewController();
        self.playerViewController = playerViewController;
        playerViewController.player = self.player;
        playerViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth];
        playerViewController.addObserver(self, forKeyPath: "videoBounds", options: [.old, .new], context: nil);

        self.activityIndicator = UIActivityIndicatorView();
        self.activityIndicator.style = .large;

        self.rootViewController.pushViewController(playerViewController, animated: false);
        self.navigationControllerObserver.observePopTransition(of: playerViewController, delegate: self);
        self.hasPushedViewController = true;
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            DispatchQueue.main.async {[weak self] in

                if (newStatus == .waitingToPlayAtSpecifiedRate && !self!.activityIndicator.isAnimating) {
                    self!.activityIndicator.startAnimating();
                }
                if newStatus != oldStatus {
                    if newStatus == .playing || newStatus == .paused {
                        self!.activityIndicator.stopAnimating()
                    } else {
                        self!.activityIndicator.startAnimating()
                    }
                }
            }
        } else if let center = self.playerViewController?.view.center, keyPath == "videoBounds", !center.equalTo(CGPoint(x: 0, y: 0)) {
            self.activityIndicator.center = center;
            self.playerViewController?.view.addSubview(self.activityIndicator);
            self.playerViewController?.view.bringSubviewToFront(self.activityIndicator);
            self.activityIndicator.startAnimating();
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                player?.play()
            case .failed:
                // Player item failed. See error.
                print("Fail")
            case .unknown:
                // Player item is not yet ready.
                print("unknown")
            @unknown default:
                print("fallthrough state")
            }
        }
    }
    
    func navigationControllerObserver(_ observer: NavigationControllerObserver, didObservePopTransitionFor viewController: UIViewController) {
        if let player = self.playerViewController?.player {
            player.pause();
        }
        if (!self.ignoreNextDelegateCall) {
            self.delegate?.doneViewing(coordinator: self);
        }
        self.ignoreNextDelegateCall = false;
    }
    
    // MARK: MediaLoadDelegate
    func mediaLoadComplete(_ filePath: String, withNewFile: Bool) {
        print("Media load complete");
        if (withNewFile) {
            MagicalRecord.save({ (localContext : NSManagedObjectContext!) in
                let localAttachment = self.attachment.mr_(in: localContext);
                localAttachment?.localPath = filePath;
            }) { (success, error) in
                if (self.attachment.contentType?.hasPrefix("audio") == true) {
                    self.playAudioVideo();
                }
            };
        }
    }
}
