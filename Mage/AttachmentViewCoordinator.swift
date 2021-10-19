//
//  AttachmentViewCoordinator.m
//  MAGE
//
//  Created by Daniel Barela on 3/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import AVKit;
import MagicalRecord;
import Kingfisher

@objc protocol AttachmentViewDelegate {
    @objc func doneViewing(coordinator: NSObject);
}

@objc class AttachmentViewCoordinator: NSObject, MediaLoaderDelegate, NavigationControllerObserverDelegate, AskToDownloadDelegate {
    var scheme: MDCContainerScheming?;

    var attachment: Attachment?
    var delegate: AttachmentViewDelegate?
    var rootViewController: UINavigationController
    var navigationControllerObserver: NavigationControllerObserver
    var tempFile: String?
    var contentType: String?
    
    var playerViewController: AVPlayerViewController?
    var player: AVPlayer?
    var imageViewController: ImageAttachmentViewController?
    var observer: NSKeyValueObservation?
    
    var urlToLoad: URL?
    var fullAudioDataLength: Int = 0;
    
    var mediaLoader: MediaLoader?;
    var hasPushedViewController: Bool = false;
    var ignoreNextDelegateCall: Bool = false;
    
    @objc public init(rootViewController: UINavigationController, attachment: Attachment, delegate: AttachmentViewDelegate?, scheme: MDCContainerScheming?) {
        self.rootViewController = rootViewController;
        self.attachment = attachment;
        self.delegate = delegate;
        self.scheme = scheme;
        
        if let attachmentUrl = self.attachment?.url {
            self.tempFile =  NSTemporaryDirectory() + (URL(string: attachmentUrl)?.lastPathComponent ?? "tempfile");
        } else {
            self.tempFile =  NSTemporaryDirectory() + "tempfile";
        }
        self.navigationControllerObserver = NavigationControllerObserver(navigationController: self.rootViewController);
        super.init();
        self.mediaLoader = MediaLoader(delegate: self);
    }
    
    @objc public init(rootViewController: UINavigationController, url: URL, contentType: String, delegate: AttachmentViewDelegate?, scheme: MDCContainerScheming?) {
        self.rootViewController = rootViewController;
        self.urlToLoad = url;
        self.delegate = delegate;
        self.scheme = scheme;
        self.contentType = contentType;
        self.tempFile =  NSTemporaryDirectory() + url.lastPathComponent;
        
        self.navigationControllerObserver = NavigationControllerObserver(navigationController: self.rootViewController);
        super.init();
        self.mediaLoader = MediaLoader(delegate: self);
    }
    
    @objc public func start() {
        self.start(true);
    }
    
    @objc public func start(_ animated: Bool = true) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let navigationController = UINavigationController();
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
        if let urlToLoad = self.urlToLoad, let contentType = self.contentType {
            if contentType.hasPrefix("image") {
                let imageViewController = ImageAttachmentViewController(url: urlToLoad)
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
        if let attachment = self.attachment {
            if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
                self.playAudioVideo();
                return;
            }
            if let attachmentUrl = attachment.url, let urlToLoad = URL(string: String(format: "%@", attachmentUrl)) {
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
        } else if let urlToLoad = urlToLoad {
            self.tempFile = (self.tempFile ?? "") + ".mp3";
            self.mediaLoader?.downloadAudio(toFile: self.tempFile ?? "", from: urlToLoad);
        }
    }
    
    func playAudioVideo() {
        if let attachment = self.attachment {
            if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
                print("Playing locally", localPath);
                self.urlToLoad = URL(fileURLWithPath: localPath);
            } else if let attachmentUrl = attachment.url {
                print("Playing from link \(attachmentUrl)");
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
        let player = AVPlayer(url: urlToLoad);
        self.player = player;
        self.player?.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        // even though we are not going to do anything with the delegate, it must be set so we can later export the video if the user wants
        (self.player?.currentItem?.asset as? AVURLAsset)?.resourceLoader.setDelegate(self, queue: .main)
        
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        player.automaticallyWaitsToMinimizeStalling = true;

        let playerViewController = AVPlayerViewController();
        self.playerViewController = playerViewController;
        self.playerViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveVideo))
        
        self.playerViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismiss))
        playerViewController.player = self.player;
        playerViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth];
        playerViewController.addObserver(self, forKeyPath: "videoBounds", options: [.old, .new], context: nil);

        self.rootViewController.pushViewController(playerViewController, animated: false);
        self.navigationControllerObserver.observePopTransition(of: playerViewController, delegate: self);
        self.hasPushedViewController = true;
        player.play();
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
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
                if let error = (object as? AVPlayerItem)?.error?.localizedDescription {
                    MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Failed to play video with error: \(error)"))
                } else {
                    MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Failed to play video"))
                }
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
                if let attachment = self.attachment {
                    let localAttachment = attachment.mr_(in: localContext);
                    localAttachment?.localPath = filePath;
                }
            }) { (success, error) in
                if let attachment = self.attachment {
                    if (attachment.contentType?.hasPrefix("audio") == true) {
                        self.playAudioVideo();
                    }
                }
            };
        }
    }
    
    func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
    
    @objc func dismiss() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.playerViewController?.dismiss(animated: true, completion: nil);
        } else {
            self.rootViewController.popViewController(animated: true);
        }
    }
    
    @objc func saveVideo() {
        
        self.playerViewController?.navigationItem.rightBarButtonItem?.title = "Saving..."
        self.playerViewController?.navigationItem.rightBarButtonItem?.isEnabled = false
        
        guard let asset: AVURLAsset = player?.currentItem?.asset as? AVURLAsset , let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            self.playerViewController?.navigationItem.rightBarButtonItem?.title = "Save"
            self.playerViewController?.navigationItem.rightBarButtonItem?.isEnabled = true
            return;
        }

        var fileUrl: URL = URL(fileURLWithPath: self.getDocumentsDirectory());
        if let name = attachment?.name {
            fileUrl = fileUrl.appendingPathComponent(name);
        } else {
            fileUrl = fileUrl.appendingPathComponent("temp.mov");
        }
        exportSession.outputURL = URL(fileURLWithPath: fileUrl.path)
        exportSession.outputFileType = .mov
        let startTime = CMTimeMake(value: 0, timescale: 1)
        let timeRange = CMTimeRangeMake(start: startTime, duration: asset.duration)
        exportSession.timeRange = timeRange
        print("Exporting to file \(fileUrl)")
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                try FileManager.default.removeItem(at: fileUrl)
            } catch let error {
                print("Failed to delete file with error: \(error)")
            }
        }
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.playerViewController?.navigationItem.rightBarButtonItem?.title = "Save"
                self.playerViewController?.navigationItem.rightBarButtonItem?.isEnabled = true
            }
            switch exportSession.status {
            case .completed:
                UISaveVideoAtPathToSavedPhotosAlbum(fileUrl.path, self, #selector(self.videoExportComplete(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            case .failed:
                if let recoverySuggestion = (exportSession.error as NSError?)?.localizedRecoverySuggestion {
                    MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Failed to save video. \(recoverySuggestion)"))
                } else {
                    MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Failed to save video. \(exportSession.error?.localizedDescription ?? "")"))
                }
            case .cancelled:
                MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Save video cancelled"))
            default: break
            }
        }
    }
    
    @objc func videoExportComplete(videoPath: String, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        do {
            print("Removing file at \(videoPath)")
            try FileManager.default.removeItem(atPath: videoPath);
        } catch {
            print("Error removing item \(error)")
        }
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Saved video to the camera roll"))
    }
}

// no implementation of the delegate is needed
// this is only here to allow the export session to not fail if the user wants to export the video
extension AttachmentViewCoordinator : AVAssetResourceLoaderDelegate {
    
}
