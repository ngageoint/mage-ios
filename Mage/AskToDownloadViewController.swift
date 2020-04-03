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
            self.descriptionLabel.text = "Your attachment fetch settings do not allow auto downloading of attachments.  Would you like to download the attachment?";
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
