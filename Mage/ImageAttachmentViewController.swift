//
//  AttachmentController.swift
//  MAGE
//
//  Created by Daniel Barela on 3/13/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

class PlaceholderImage: UIImageView { }
extension PlaceholderImage: Placeholder {}
//extension Data {
//
//    /// Data into file
//    ///
//    /// - Parameters:
//    ///   - fileName: the Name of the file you want to write
//    /// - Returns: Returns the URL where the new file is located in NSURL
//    func dataToFile(fileName: String) -> NSURL? {
//
//        // Make a constant from the data
//        let data = self
//
//        // Make the file path (with the filename) where the file will be loacated after it is created
//        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
//
//        do {
//            // Write the file from data into the filepath (if there will be an error, the code jumps to the catch block below)
//            try data.write(to: URL(fileURLWithPath: filePath))
//
//            // Returns the URL where the new file is located in NSURL
//            return NSURL(fileURLWithPath: filePath)
//
//        } catch {
//            // Prints the localized description of the error from the do block
//            print("Error writing the file: \(error.localizedDescription)")
//        }
//
//        // Returns nil if there was an error in the do-catch -block
//        return nil
//
//    }
//
//}
/// Get the current directory
///
/// - Returns: the Current directory in NSURL
func getDocumentsDirectory() -> NSString {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]
    return documentsDirectory as NSString
}

@objc class ImageAttachmentViewController: UIViewController {
    
    @IBOutlet weak var imageActivityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var imageViewHolder: UIView?
    @IBOutlet weak var imageView: AttachmentUIImageView?
    @IBOutlet weak var mediaHolderView: UIView?
    @IBOutlet weak var progressView: UIView?
    @IBOutlet weak var progressPercentLabel: UILabel?
    @IBOutlet weak var downloadProgressBar: UIProgressView?
    @IBOutlet weak var downloadAttachmentView: UIView?
    @IBOutlet weak var downloadingLabel: UILabel!
    
    var attachment: Attachment!
    var imageSize: Int!
    
    struct MyIndicator: Indicator {
        let view: UIView
        unowned let parent: ImageAttachmentViewController;
        
        func startAnimatingView() { view.isHidden = false }
        func stopAnimatingView() { view.isHidden = true }
        
        func setProgress(progress: Float) {
            self.parent.downloadProgressBar?.progress = progress;
            self.parent.progressPercentLabel?.text = String("\(progress * 100)%");
        }
        
        init(parent: ImageAttachmentViewController) {
            self.parent = parent;
            self.view = parent.progressView ?? UIView();
            self.view.layer.zPosition = 1000;
        }
    }
    
    @objc public convenience init(attachment: Attachment) {
        self.init(nibName: "AttachmentView", bundle: nil);
        self.imageSize = 0;
        self.attachment = attachment;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.showAttachment()
        { result in
            switch result {
            case .success(let value):
                // TODO handle the case where if the downloaded image is the actual full size one (image thumbnailing is off) we should store the image in the cache
                // with the base url as the key

                // if the thumbnail is not cached, cache it now
                if(!ImageCache.default.isCached(forKey: String(format: "%@_thumbnail", self.attachment.url!))) {
                    ImageCache.default.store(value.image, forKey: String(format: "%@_thumbnail", self.attachment.url!));
                }
            case .failure(_): break
            }
        };
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
                if ((self.attachment.contentType?.starts(with: "image/jpeg")) == true) {
                    data = image.jpegData(compressionQuality: 0.8);
                    fileName = "attachment.jpeg";
                } else {
                    // Convert the image into png image data
                    data = image.pngData();
                    fileName = "attachment.png";
                }
                let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
                
                do {
                    try data?.write(to: URL(fileURLWithPath: filePath))
                    let imageURL: NSURL = NSURL(fileURLWithPath: filePath)
                    var filesToShare = [Any]()
                    filesToShare.append(imageURL)
                    let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                    self.present(activityViewController, animated: true, completion: nil)
                } catch {
                    // Prints the localized description of the error from the do block
                    print("Error writing the file: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print(error);
            }
        }
    }
    
    @objc func saveToGallery() {
        let alert = UIAlertController(title: "Save Image", message: "Please Select an Option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Save Current Image", style: .default , handler:{ (UIAlertAction)in
            let url: URL = self.getAttachmentUrl(size: self.imageSize);
            self.presentShareSheet(url: url);
        }))
        
        if (!self.isFullSizeCached()) {
            let attachmentMbs: Double = ((self.attachment.size?.doubleValue ?? 0) / (1000.0 * 1024.0));
            alert.addAction(UIAlertAction(title: String.init(format: "Download and Save Full Size Image %.2F MBs", attachmentMbs), style: .default , handler:{ (UIAlertAction)in
                print("Go Download Full size")
                self.showAttachment(fullSize: true)
                { result in
                    switch result {
                    case .success(_):
                        self.presentShareSheet(url: URL(string: self.attachment.url!)!)
                    case .failure(let error):
                        print(error);
                    }
                };
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    }
    
    func getAttachmentUrl(size: Int) -> URL {
        if (self.attachment.localPath != nil && FileManager.default.fileExists(atPath: self.attachment.localPath!)) {
            return URL(fileURLWithPath: self.attachment.localPath!);
        } else {
            return URL(string: String(format: "%@?size=%ld", self.attachment.url!, size))!;
        }
    }
    
    func isFullSizeCached() -> Bool {
        return ImageCache.default.isCached(forKey: self.attachment.url!);
    }
    
    func showAttachment(fullSize: Bool = false, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.imageViewHolder?.isHidden = false;
        self.progressView?.isHidden = true;
        self.imageActivityIndicator?.isHidden = true;
        let i = MyIndicator(parent: self);

        self.imageView?.setAttachment(attachment: self.attachment);
        self.imageView?.showImage(fullSize: fullSize, indicator: i, progressBlock: {
            receivedSize, totalSize in
            let percentage = (Float(receivedSize) / Float(totalSize))
            i.setProgress(progress: percentage);
        },
        completionHandler: completionHandler);
    }
}
