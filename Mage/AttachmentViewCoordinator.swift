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
            self.downloadAudioVideo();
        } else if (self.attachment.contentType!.hasPrefix("audio")) {
//            self.downloadAudioVideo();
            self.playAudio();
        }
    }
    
    func downloadAttachment() {
        print("Download the attachment")
        FadeTransitionSegue.addFadeTransition(to: self.rootViewController.view);
        self.rootViewController.popViewController(animated: false);
        
        self.showAttachment();
    }
    
    func playAudio() {
        print("playing audio:", String.init(format: "%@?access_token=%@", self.attachment.url!, StoredPassword.retrieveStoredToken()));
        self.urlToLoad = URL(string: String.init(format: "%@?access_token=%@", self.attachment.url!, StoredPassword.retrieveStoredToken()));
        self.mediaLoader = MediaLoader(urlToLoad: self.urlToLoad!, andTempFile: self.tempFile, andDelegate: self);

        self.mediaLoader.playAudio();
        
//        if ((self.attachment.localPath != nil) && FileManager.default.fileExists(atPath: self.attachment.localPath!)) {
//            print("Playing locally");
//            self.urlToLoad = URL(fileURLWithPath: attachment.localPath!);
//        } else {
//            print("Playing from link");
//            self.urlToLoad = URL(string: String.init(format: "%@?access_token=%@", self.attachment.url!, StoredPassword.retrieveStoredToken()));
//        }
//        let components = NSURLComponents(url: self.urlToLoad!, resolvingAgainstBaseURL: false);
//        components?.scheme = "streaming";
        
//        self.mediaLoader = MediaLoader(urlToLoad: self.urlToLoad!, andTempFile: self.tempFile, andDelegate: self);
        
//        let asset = AVURLAsset(url: self.urlToLoad!);
////        asset.resourceLoader.setDelegate(self.mediaLoader, queue: DispatchQueue.main);
//
//        let playerItem = AVPlayerItem(asset: asset)
//
//        self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
//            switch (playerItem.status) {
//            case .readyToPlay:
//                self.player?.play();
//                break;
//            case .failed:
//                print("failed", playerItem.error);
//                break;
//            case .unknown:
//                print("unknown");
//            }
//            //            if playerItem.status == .readyToPlay {
//            //                self.player?.play();
//            //            }
//        })
        
//        MageSessionManager *manager = [MageSessionManager manager];
//        NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
//
//        NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * downloadProgress){
//            dispatch_async(dispatch_get_main_queue(), ^{;
//            float progress = downloadProgress.fractionCompleted;
//            weakSelf.downloadProgressBar.progress = progress;
//            weakSelf.progressPercentLabel.text = [NSString stringWithFormat:@"%.2f%%", progress * 100];
//            });
//            } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
//            return [NSURL fileURLWithPath:downloadPath];
//            } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//
//            NSString * fileString = [filePath path];
//
//            if(!error){
//            dispatch_async(dispatch_get_main_queue(), ^{
//            if ([[NSFileManager defaultManager] fileExistsAtPath:fileString]){
//            [weakSelf.progressView setHidden:YES];
//            [weakSelf playMediaType: type FromDocumentsFolder:fileString];
//            }
//            });
//            }else{
//            NSLog(@"Error: %@", error);
//            //delete the file
//            NSError *deleteError;
//            [[NSFileManager defaultManager] removeItemAtPath:fileString error:&deleteError];
//            }
//
//            }];
//
//        NSError *error;
//        if (![[NSFileManager defaultManager] fileExistsAtPath:[downloadPath stringByDeletingLastPathComponent]]) {
//            NSLog(@"Creating directory %@", [downloadPath stringByDeletingLastPathComponent]);
//            [[NSFileManager defaultManager] createDirectoryAtPath:[downloadPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
//        }
//
//        [manager addTask:task];
        
        
//        self.player = AVPlayer(url: self.urlToLoad!);
        
        
        
//        guard let url = URL.init(string: self.urlToLoad) else { return }
//        let playerItem = AVPlayerItem.init(url: self.urlToLoad!)
//        self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
//            switch (playerItem.status) {
//            case .readyToPlay:
//                self.player?.play();
//                break;
//            case .failed:
//                print("failed", playerItem.error);
//                break;
//            case .unknown:
//                print("unknown");
//            }
//            //            if playerItem.status == .readyToPlay {
//            //                self.player?.play();
//            //            }
//        })
//
//        self.player = AVPlayer.init(playerItem: playerItem)
//        do {
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: [.mixWithOthers, .allowAirPlay])
//            print("Playback OK")
//            try AVAudioSession.sharedInstance().setActive(true)
//            print("Session is Active")
//        } catch {
//            print(error)
//        }
        
//        var player: AVPlayer?
        
        
//        var downloadTask:URLSessionDownloadTask
//        downloadTask = URLSession.shared.downloadTask(with: self.urlToLoad!, completionHandler: { [weak self](URL, response, error) -> Void in
//            do {
//                let audioPlayer = try AVAudioPlayer(contentsOf: self!.urlToLoad!)
//                audioPlayer.prepareToPlay()
//                audioPlayer.volume = 1.0
//                audioPlayer.play()
//            } catch let error as NSError {
//                //self.player = nil
//                print(error.localizedDescription)
//            } catch {
//                print("AVAudioPlayer init failed")
//            }
//
//        })
//
//        downloadTask.resume()
//
//        self.playerViewController = AVPlayerViewController();
//        self.playerViewController?.player = player;
//        self.playerViewController?.view.autoresizingMask = [.flexibleHeight, .flexibleWidth];
//
//        self.rootViewController.pushViewController(self.playerViewController!, animated: false);
//        self.navigationControllerObserver.observePopTransition(of: self.playerViewController!, delegate: self);
        
    }
    
    func downloadAudioVideo() {
        if ((self.attachment.localPath != nil) && FileManager.default.fileExists(atPath: self.attachment.localPath!)) {
            print("Playing locally");
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
                print("failed", playerItem.error);
                break;
            case .unknown:
                print("unknown");
            }
//            if playerItem.status == .readyToPlay {
//                self.player?.play();
//            }
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
        });
        print("Content type finished", self.attachment.contentType);
        if (self.attachment.contentType?.hasPrefix("audio") == true) {
            self.downloadAudioVideo();
        }
    }
}
