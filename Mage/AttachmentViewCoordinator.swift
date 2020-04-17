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
    var observer: NSKeyValueObservation?
    
    var urlToLoad: URL?
    var fullAudioDataLength: Int = 0;
    
    var mediaLoader: MediaLoader!;
    
    @objc public init(rootViewController: UINavigationController, attachment: Attachment, delegate: AttachmentViewDelegate?) {
        self.rootViewController = rootViewController;
        self.attachment = attachment;
        self.delegate = delegate;
        
        self.tempFile =  NSTemporaryDirectory() + URL.init(string: self.attachment.url!)!.lastPathComponent;
        self.navigationControllerObserver = NavigationControllerObserver(navigationController: self.rootViewController);
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
            let ac: ImageAttachmentViewController = ImageAttachmentViewController(attachment: self.attachment);
            // not sure if we still need this TODO test
            ac.view.backgroundColor = UIColor.black;
            self.rootViewController.pushViewController(ac, animated: animated);
            self.navigationControllerObserver.observePopTransition(of: ac, delegate: self);
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
        self.mediaLoader = MediaLoader(urlToLoad: self.urlToLoad!, andTempFile: self.tempFile, andDelegate: self);
        self.mediaLoader.downloadAudio();
    }
    
    func playAudioVideo() {
        if ((self.attachment.localPath != nil) && FileManager.default.fileExists(atPath: self.attachment.localPath!)) {
            print("Playing locally", attachment.localPath!);
            self.urlToLoad = URL(fileURLWithPath: attachment.localPath!);
        } else {
            print("Playing from link");
            self.urlToLoad = URL(string: String.init(format: "%@?access_token=%@", self.attachment.url!, StoredPassword.retrieveStoredToken()));
        }
        let components = NSURLComponents(url: self.urlToLoad!, resolvingAgainstBaseURL: false);
        components?.scheme = "streaming";
        
        self.mediaLoader = MediaLoader(urlToLoad: self.urlToLoad!, andTempFile: self.tempFile, andDelegate: self);

        let asset = AVURLAsset(url: (components?.url)!);
        asset.resourceLoader.setDelegate(self.mediaLoader, queue: DispatchQueue.main);
        
        let playerItem = AVPlayerItem(asset: asset)
        
        self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
            switch (playerItem.status) {
            case .readyToPlay:
                self.player?.play();
                break;
            case .failed:
                print("failed %@", playerItem.error?.localizedDescription ?? "");
                break;
            case .unknown:
                print("unknown");
                break;
            @unknown default:
                break;
            }
        })
        
        self.player = AVPlayer(playerItem: playerItem);
        
        self.playerViewController = AVPlayerViewController();
        self.playerViewController?.player = self.player;
        self.playerViewController?.view.autoresizingMask = [.flexibleHeight, .flexibleWidth];
        
        self.rootViewController.pushViewController(self.playerViewController!, animated: false);
        self.navigationControllerObserver.observePopTransition(of: self.playerViewController!, delegate: self);
    }
    
    func navigationControllerObserver(_ observer: NavigationControllerObserver, didObservePopTransitionFor viewController: UIViewController) {
        self.delegate?.doneViewing(coordinator: self);
    }
    
    // MARK: MediaLoadDelegate
    func mediaLoadComplete(_ filePath: String) {
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
