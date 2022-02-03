//
//  ExportableVideoViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 2/1/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import AVKit

class ExportableVideoViewController: AVPlayerViewController {
    
    var mediaLoader: MediaLoader?
    var mediaLoaderDelegate: MediaLoaderDelegate?
    var url: URL?
    var contentType: String?
    var tempFile: String?
    
    public convenience init() {
        self.init(nibName: nil, bundle: nil);
        self.mediaLoader = MediaLoader(delegate: self);
    }
    
    func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
    
    func playAudioVideo(url: URL?, contentType: String?, mediaLoaderDelegate: MediaLoaderDelegate? = nil) {
        self.tempFile =  NSTemporaryDirectory() + (url?.lastPathComponent ?? "tempfile");
        guard let url = url, let contentType = contentType else {
            return
        }
        
        self.url = url
        self.contentType = contentType
        self.mediaLoaderDelegate = mediaLoaderDelegate
        
        if contentType.hasPrefix("audio") {
            if url.isFileURL {
                // the file is local, play it
                play(url: url)
            } else {
                // download it then play it
                let uttype = UTType(mimeType: contentType)
                
                if let ext = uttype?.preferredFilenameExtension {
                    self.tempFile = (self.tempFile ?? "") + "." + ext;
                } else {
                    self.tempFile = (self.tempFile ?? "") + ".mp3";
                }
                downloadAudio(url: url, fileToWrite: self.tempFile)
            }
        } else {
            // play it
            play(url: url)
        }
    }
    
    func play(url: URL) {
        let player = AVPlayer(url: url);
        self.player = player;
        self.player?.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        // even though we are not going to do anything with the delegate, it must be set so we can later export the video if the user wants
        (self.player?.currentItem?.asset as? AVURLAsset)?.resourceLoader.setDelegate(self, queue: .main)
        
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        player.automaticallyWaitsToMinimizeStalling = true;
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveVideo))
        
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismiss(_ :)))
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth];
        addObserver(self, forKeyPath: "videoBounds", options: [.old, .new], context: nil);
        
        player.play();
    }
    
    func downloadAudio(url: URL?, fileToWrite: String?) {
        guard let url = url, let fileToWrite = fileToWrite else {
            return
        }
        self.mediaLoader?.downloadAudio(toFile: fileToWrite, from: url);
    }
    
    @objc func dismiss(_ sender: UIBarButtonItem) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.dismiss(animated: true, completion: nil);
        } else {
            self.presentingViewController?.navigationController?.popViewController(animated: true)
        }
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
    
    @objc func saveVideo(fileName: String? = nil) {
        let name = fileName ?? {
            if let contentType = contentType {
                let uttype = UTType(mimeType: contentType)
                return "movie.\(uttype?.preferredFilenameExtension ?? "mov")"
            }
            return "movie.mov"
        }()
        
        self.navigationItem.rightBarButtonItem?.title = "Saving..."
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        guard let asset: AVURLAsset = player?.currentItem?.asset as? AVURLAsset , let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            self.navigationItem.rightBarButtonItem?.title = "Save"
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            return;
        }
        
        var fileUrl: URL = URL(fileURLWithPath: self.getDocumentsDirectory());
        fileUrl = fileUrl.appendingPathComponent(name);
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
                self.navigationItem.rightBarButtonItem?.title = "Save"
                self.navigationItem.rightBarButtonItem?.isEnabled = true
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
extension ExportableVideoViewController : AVAssetResourceLoaderDelegate {
    
}

extension ExportableVideoViewController : MediaLoaderDelegate {
    func mediaLoadComplete(_ filePath: String, withNewFile: Bool) {
        print("Media load complete");
        if let mediaLoaderDelegate = mediaLoaderDelegate {
            mediaLoaderDelegate.mediaLoadComplete(filePath, withNewFile: withNewFile)
        }
        if contentType?.hasPrefix("audio") == true {
            playAudioVideo(url: URL(fileURLWithPath: filePath), contentType: contentType, mediaLoaderDelegate: mediaLoaderDelegate)
        }
    }
}
