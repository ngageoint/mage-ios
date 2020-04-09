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
    @objc func downloadAttachment()
}

@objc class AskToDownloadViewController: UIViewController {
    
    var attachment: Attachment!
    var delegate: AskToDownloadDelegate?
    @IBOutlet weak var thumbnail: AttachmentUIImageView?
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var downloadBlock: UIView!
    
    @objc public convenience init(attachment: Attachment, delegate: AskToDownloadDelegate?) {
        self.init(nibName: "AskToDownload", bundle: nil);
        self.attachment = attachment;
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
    
    @IBAction func downloadAttachment(_ sender: Any) {
        self.delegate?.downloadAttachment();
    }
    
    func showAttachment(fullSize: Bool = false, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.thumbnail?.setAttachment(attachment: self.attachment);
        if (self.thumbnail?.isLargeSizeCached() == true) {
            self.delegate?.downloadAttachment();
        } else {
            self.downloadBlock.isHidden = false;
            self.thumbnail?.showImage(cacheOnly: true);
        }
    }
}
