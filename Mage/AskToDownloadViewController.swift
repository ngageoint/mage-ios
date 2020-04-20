//
//  AskToDownloadViewController.m
//  MAGE
//
//  Created by Daniel Barela on 3/11/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

@objc protocol AskToDownloadDelegate {
    @objc func downloadApproved()
}

@objc class AskToDownloadViewController: UIViewController {
    
    var attachment: Attachment!
    var delegate: AskToDownloadDelegate?
    var url: URL?
    @IBOutlet weak var thumbnail: AttachmentUIImageView?
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var downloadBlock: UIView!
    @IBOutlet weak var emptyContentImage: UIImageView!
    
    @objc public convenience init(attachment: Attachment, delegate: AskToDownloadDelegate?) {
        self.init(nibName: "AskToDownload", bundle: nil);
        self.attachment = attachment;
        self.delegate = delegate;
    }
    
    @objc public convenience init(url: URL, delegate: AskToDownloadDelegate?) {
        self.init(nibName: "AskToDownload", bundle: nil);
        self.url = url;
        self.delegate = delegate;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.downloadBlock.isHidden = true;
        if (!DataConnectionUtilities.shouldFetchAttachments()) {
            if (self.attachment.contentType?.hasPrefix("image") == true) {
                self.descriptionLabel.text = "Your attachment fetch settings do not allow auto downloading of images.  Would you like to download the image?";
            } else if (self.attachment.contentType?.hasPrefix("video") == true) {
                self.descriptionLabel.text = String.init(format: "Your attachment fetch settings do not allow auto downloading of videos.  This video is %.2FMB.  Would you like to download the video?", (self.attachment.size!.doubleValue / (1024.0 * 1024.0)));
            }
        }
        self.showAttachment();
    }
    
    @IBAction func downloadApproved(_ sender: Any) {
        self.delegate?.downloadApproved();
    }
    
    func showAttachment(fullSize: Bool = false, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.thumbnail?.useDownloadPlaceholder = false;
        self.thumbnail?.setURL(url: self.url);
        self.thumbnail?.setAttachment(attachment: self.attachment);
        if (self.thumbnail?.isLargeSizeCached() == true) {
            self.delegate?.downloadApproved();
        } else {
            self.downloadBlock.isHidden = false;
            self.thumbnail?.showImage(cacheOnly: true);
            if (self.thumbnail?.placeholderIsRealImage == true) {
                // this will cause the "do you want to download the image" block to stay close to the bottom of the screen
                // so that the thumbnail image is not covered as much
                self.emptyContentImage.removeFromSuperview();
            }
        }
    }
}
