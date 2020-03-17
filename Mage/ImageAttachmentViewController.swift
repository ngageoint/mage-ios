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

@objc class ImageAttachmentViewController: UIViewController {
    
    @IBOutlet weak var imageActivityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var imageViewHolder: UIView?
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var mediaHolderView: UIView?
    @IBOutlet weak var progressView: UIView?
    @IBOutlet weak var progressPercentLabel: UILabel?
    @IBOutlet weak var downloadProgressBar: UIProgressView?
    @IBOutlet weak var downloadAttachmentView: UIView?
    @IBOutlet weak var downloadingLabel: UILabel!
    
    var attachment: Attachment!
    var accessTokenModifier: AnyModifier!
    
    @objc public convenience init(attachment: Attachment) {
        self.init(nibName: "AttachmentView", bundle: nil);
        
        self.attachment = attachment;
        
        // XXXX TODO temporary for testing
        ImageCache.default.clearMemoryCache();
        ImageCache.default.clearDiskCache();
        
        self.accessTokenModifier = AnyModifier { request in
            var r = request
            r.setValue(String(format: "Bearer %@", StoredPassword.retrieveStoredToken()), forHTTPHeaderField: "Authorization")
            return r
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.showAttachment();
    }
    
    func getAttachmentUrl(size: Int) -> URL {
        if (self.attachment.localPath != nil && FileManager.default.fileExists(atPath: self.attachment.localPath!)) {
            return URL(fileURLWithPath: self.attachment.localPath!);
        } else {
            return URL(string: String(format: "%@?size=%ld", self.attachment.url!, size))!;
        }
    }
    
    func showAttachment() {
        self.imageViewHolder?.isHidden = false;
        self.progressView?.isHidden = true;
        self.imageActivityIndicator?.isHidden = true;
        

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
                let downloadingLabel = self.parent.downloadingLabel;
                downloadingLabel?.layer.shadowColor = UIColor.white.cgColor
                downloadingLabel?.layer.shadowOffset = .zero
                downloadingLabel?.layer.shadowRadius = 2.0
                downloadingLabel?.layer.shadowOpacity = 1.0
                downloadingLabel?.layer.masksToBounds = false
                downloadingLabel?.layer.shouldRasterize = true
                let progressPercentLabel = self.parent.progressPercentLabel;
                progressPercentLabel?.layer.shadowColor = UIColor.white.cgColor
                progressPercentLabel?.layer.shadowOffset = .zero
                progressPercentLabel?.layer.shadowRadius = 2.0
                progressPercentLabel?.layer.shadowOpacity = 1.0
                progressPercentLabel?.layer.masksToBounds = false
                progressPercentLabel?.layer.shouldRasterize = true
            }
        }
        let thumbUrl = self.getAttachmentUrl(size: 100);
        
        let placeholder = PlaceholderImage();
        placeholder.contentMode = .scaleAspectFit;
        // if they had the thumbnail already downloaded for some reason, show that while we go get the big one
        if (ImageCache.default.isCached(forKey: thumbUrl.absoluteString)) {
            placeholder.kf.setImage(with: thumbUrl, options: [.requestModifier(self.accessTokenModifier)])
        } else {
            // otherwise, show a placeholder
            placeholder.image = UIImage.init(named: "people");
        }
        
        let i = MyIndicator(parent: self);
        self.imageView?.kf.indicatorType = .custom(indicator: i);
        let imageSize: Int = Int(max(self.imageView?.frame.size.height ?? 0, self.imageView?.frame.size.width ?? 0) * UIScreen.main.scale);
        let url = self.getAttachmentUrl(size: imageSize);
        // Have to do this so that the placeholder image shows up behind the activity indicator
        DispatchQueue.main.async {
            self.imageView?.kf.setImage(with: url, placeholder: placeholder, options: [.requestModifier(self.accessTokenModifier), .transition(.fade(1.5))], progressBlock: {
                receivedSize, totalSize in
                let percentage = (Float(receivedSize) / Float(totalSize))
                i.setProgress(progress: percentage);
            })
            { result in
                switch result {
                case .success(let value):
                    print(value);
                    print(value.image);
                case .failure(let error):
                    print(error);
                }
            };
        }
        
    }
}
