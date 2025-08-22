//
//  AttachmentController.swift
//  MAGE
//
//  Created by Daniel Barela on 3/13/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

class PlaceholderImage: UIImageView { }
extension PlaceholderImage: Placeholder {}

@objc class ImageAttachmentViewController: UIViewController {
    
    @IBOutlet weak var imageView: AttachmentUIImageView?
    @IBOutlet weak var progressView: UIView?
    @IBOutlet weak var progressPercentLabel: UILabel?
    @IBOutlet weak var downloadProgressBar: UIProgressView?
    @IBOutlet weak var downloadingLabel: UILabel!
    
    var attachment: AttachmentModel? = nil;
    var url: URL? = nil;
    var imageSize: Int!
    
    struct MyIndicator: Indicator {
        let view: UIView
        weak var parent: ImageAttachmentViewController?
        
        func startAnimatingView() { view.isHidden = false }
        func stopAnimatingView() { view.isHidden = true }
        
        func setProgress(progress: Float) {
            self.parent?.downloadProgressBar?.progress = progress;
            self.parent?.progressPercentLabel?.text = String("\(progress * 100)%");
        }
        
        init(parent: ImageAttachmentViewController) {
            self.parent = parent;
            self.view = parent.progressView ?? UIView();
            self.view.layer.zPosition = 1000;
        }
    }
    
    @objc public convenience init(attachment: AttachmentModel) {
        self.init(nibName: "AttachmentView", bundle: nil);
        self.imageSize = 0;
        self.attachment = attachment;
    }
    
    @objc public convenience init(url: URL) {
        self.init(nibName: "AttachmentView", bundle: nil);
        self.imageSize = 0;
        self.url = url;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        if (self.attachment != nil) {
            self.showAttachment(largeSize: true)
        } else if (self.url != nil) {
            self.showImage();
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveToGallery));
    }
    
    func presentShareSheet(url: URL) {
        KingfisherManager.shared.retrieveImage(with: url, options: [.requestModifier(ImageCacheProvider.shared.accessTokenModifier)]) { result in
            switch result {
            case .success(let value):
                let image: UIImage = value.image;
                var data: Data?;
                var fileName: String!;
                if let theAttachment = self.attachment {
                    if ((theAttachment.contentType?.starts(with: "image/jpeg")) == true) {
                        data = image.jpegData(compressionQuality: 0.8);
                        fileName = "attachment.jpeg";
                    } else {
                        // Convert the image into png image data
                        data = image.pngData();
                        fileName = "attachment.png";
                    }
                } else if let theUrl = self.url?.absoluteString {
                    if (theUrl.lowercased().hasSuffix(".png")) {
                        data = image.pngData();
                        fileName = "image.png";
                    } else {
                        data = image.jpegData(compressionQuality: 0.8);
                        fileName = "image.jpeg";
                    }
                    
                }
                let filePath = self.getDocumentsDirectory().appendingPathComponent(fileName)
                
                do {
                    try data?.write(to: URL(fileURLWithPath: filePath))
                    let imageURL: NSURL = NSURL(fileURLWithPath: filePath)
                    var filesToShare = [Any]()
                    filesToShare.append(imageURL)
                    let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                    if let popoverController = activityViewController.popoverPresentationController {
                        popoverController.sourceView = self.view
                        popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                    }
                    self.present(activityViewController, animated: true, completion: nil)
                } catch {
                    // Prints the localized description of the error from the do block
                    MageLogger.misc.error("Error writing the file: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print(error);
            }
        }
    }
    
    @objc func saveToGallery() {
        let alert = UIAlertController(title: "Save Image", message: "Please Select an Option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Save Current Image", style: .default , handler:{ (UIAlertAction)in
            if let url: URL = self.getAttachmentUrl(size: self.imageSize) {
                self.presentShareSheet(url: url);
            }
        }))
        
        if let attachment = self.attachment, !self.isFullSizeCached() {
            let attachmentMbs: Double = ((attachment.size?.doubleValue ?? 0) / (1000.0 * 1024.0));
            alert.addAction(UIAlertAction(title: String.init(format: "Download and Save Full Size Image %.2F MBs", attachmentMbs), style: .default , handler:{ (UIAlertAction)in
                self.showAttachment(fullSize: true)
                { result in
                    switch result {
                    case .success(_):
                        if let attachmentUrl = attachment.url {
                            self.presentShareSheet(url: URL(string: attachmentUrl)!)
                        }
                    case .failure(let error):
                        print(error);
                    }
                };
            }))
        } else if let url = self.url {
            self.presentShareSheet(url: url);
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func getAttachmentUrl(size: Int) -> URL? {
        if let localPath = self.attachment?.localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath);
        } else if let attachmentUrl = self.attachment?.url {
            return URL(string: String(format: "%@?size=%ld", attachmentUrl, size))!;
        }
        return nil;
    }
    
    func isFullSizeCached() -> Bool {
        if let attachmentUrl = self.attachment?.url {
            return ImageCache.default.isCached(forKey: attachmentUrl);
        }
        return false;
    }
    
    func showAttachment(largeSize: Bool = false, fullSize: Bool = false, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.progressView?.isHidden = true;
        let i = MyIndicator(parent: self);

        self.imageView?.setAttachment(attachment: self.attachment!);
        self.imageView?.showImage(
            fullSize: fullSize,
            largeSize: largeSize,
            indicator: i,
            progressBlock: {
                receivedSize, totalSize in
                let percentage = (Float(receivedSize) / Float(totalSize))
                i.setProgress(progress: percentage);
            },
            completionHandler: completionHandler);
        self.imageView?.contentMode = .scaleAspectFit
    }
    
    func showImage() {
        self.progressView?.isHidden = true;
        let i = MyIndicator(parent: self);
        
        self.imageView?.setURL(url: self.url);
        self.imageView?.showImage(
            indicator: i,
            progressBlock: {
                receivedSize, totalSize in
                let percentage = (Float(receivedSize) / Float(totalSize))
                i.setProgress(progress: percentage);
        });
        self.imageView?.contentMode = .scaleAspectFit
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
}
