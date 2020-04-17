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

    var attachment: Attachment!
    var delegate: AttachmentViewDelegate?
    var rootViewController: UINavigationController
    var navigationControllerObserver: NavigationControllerObserver
    var tempFile: String
    
    var player: AVPlayer!
    var playerViewController: AVPlayerViewController?
    var imageViewController: ImageAttachmentViewController?
    var observer: NSKeyValueObservation?
    
    var urlToLoad: URL?
    var fullAudioDataLength: Int = 0;
    
    var mediaLoader: MediaLoader?;
    var activityIndicator: UIActivityIndicatorView!
    
    @objc public init(rootViewController: UINavigationController, attachment: Attachment, delegate: AttachmentViewDelegate?) {
        self.rootViewController = rootViewController;
        self.attachment = attachment;
        self.delegate = delegate;
        
        self.tempFile =  NSTemporaryDirectory() + URL.init(string: self.attachment.url!)!.lastPathComponent;
        self.navigationControllerObserver = NavigationControllerObserver(navigationController: self.rootViewController);
        super.init();
        self.mediaLoader = MediaLoader(delegate: self);
    }
    
    @objc public func start() {
        // if the file exists locally, just show it
        if ((self.attachment.localPath != nil
            && FileManager.default.fileExists(atPath: self.attachment.localPath!) == true)
            || DataConnectionUtilities.shouldFetchAttachments()) {
            return self.showAttachment(animated: true);
        } else {
            let vc: AskToDownloadViewController = AskToDownloadViewController(attachment: self.attachment, delegate: self);
            self.rootViewController.pushViewController(vc, animated: true);
            self.navigationControllerObserver.observePopTransition(of: vc, delegate: self);
        }
    }
    
    func showAttachment(animated: Bool = false) {
        if (self.attachment.contentType!.hasPrefix("image")) {
            self.imageViewController = ImageAttachmentViewController(attachment: self.attachment);
            // not sure if we still need this TODO test
            self.imageViewController?.view.backgroundColor = UIColor.black;
            self.rootViewController.pushViewController(self.imageViewController!, animated: animated);
            self.navigationControllerObserver.observePopTransition(of: self.imageViewController!, delegate: self);
        } else if (self.attachment.contentType!.hasPrefix("video")) {
            self.playAudioVideo();
        } else if (self.attachment.contentType!.hasPrefix("audio")) {
            self.downloadAudio();
        }
    }
    
    func downloadAttachment() {
        print("Download the attachment")
        FadeTransitionSegue.addFadeTransition(to: self.rootViewController.view);
        self.rootViewController.popViewController(animated: false);
        
        self.showAttachment();
    }
    
    func downloadAudio() {
        if ((self.attachment.localPath != nil) && FileManager.default.fileExists(atPath: self.attachment.localPath!)) {
            self.playAudioVideo();
            return;
        }
        print("playing audio:", String.init(format: "%@", self.attachment.url!));
        self.urlToLoad = URL(string: String.init(format: "%@", self.attachment.url!));
        if (attachment.name != nil) {
            self.tempFile = self.tempFile + "_" + attachment.name!;
        } else if let ext = (UTTypeCopyPreferredTagWithClass(attachment.contentType! as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue()) {
            self.tempFile = self.tempFile + "." + String(ext);
        } else {
            self.tempFile = self.tempFile + ".mp3";
        }
        self.mediaLoader?.downloadAudio(toFile: self.tempFile, from: self.urlToLoad!);
    }
    
    func playAudioVideo() {
        if ((self.attachment.localPath != nil) && FileManager.default.fileExists(atPath: self.attachment.localPath!)) {
            print("Playing locally", attachment.localPath!);
            self.urlToLoad = URL(fileURLWithPath: attachment.localPath!);
        } else {
            print("Playing from link");
            self.urlToLoad = URL(string: String.init(format: "%@?access_token=%@", self.attachment.url!, StoredPassword.retrieveStoredToken()));
        }
        
        let playerItem = self.mediaLoader?.createPlayerItem(from: self.urlToLoad!, toFile: self.tempFile);
        
        self.player = AVPlayer(playerItem: playerItem);
        
        self.player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        self.player?.play();

        self.playerViewController = AVPlayerViewController();
        self.playerViewController?.player = self.player;
        self.playerViewController?.view.autoresizingMask = [.flexibleHeight, .flexibleWidth];
        self.playerViewController?.addObserver(self, forKeyPath: "videoBounds", options: [.old, .new], context: nil);

        self.activityIndicator = UIActivityIndicatorView();
        self.activityIndicator.style = .whiteLarge;

        self.rootViewController.pushViewController(self.playerViewController!, animated: false);
        self.navigationControllerObserver.observePopTransition(of: self.playerViewController!, delegate: self);
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                DispatchQueue.main.async {[weak self] in
                    if newStatus == .playing || newStatus == .paused {
                        self!.activityIndicator.stopAnimating()
                    } else {
                        self!.activityIndicator.startAnimating()
                    }
                }
            }
        } else if keyPath == "videoBounds" {
            if (!self.playerViewController!.contentOverlayView!.center.equalTo(CGPoint(x: 0, y: 0))) {
                self.activityIndicator.center = self.playerViewController!.contentOverlayView!.center;
                self.playerViewController?.view.addSubview(self.activityIndicator);
                self.playerViewController?.view.bringSubviewToFront(self.activityIndicator);
                self.activityIndicator.startAnimating();
            }
        }
    }
    
    func navigationControllerObserver(_ observer: NavigationControllerObserver, didObservePopTransitionFor viewController: UIViewController) {
        self.delegate?.doneViewing(coordinator: self);
    }
    
    // MARK: MediaLoadDelegate
    func mediaLoadComplete(_ filePath: String, withNewFile: Bool) {
        print("Media load complete");
        if (withNewFile) {
            MagicalRecord.save({ (localContext : NSManagedObjectContext!) in
                print("saving the attachment");
                let localAttachment = self.attachment.mr_(in: localContext);
                localAttachment?.localPath = filePath;
            }) { (success, error) in
                print("In the complete of magical record")
                if (self.attachment.contentType?.hasPrefix("audio") == true) {
                    self.playAudioVideo();
                }
            };
        }
    }
}
