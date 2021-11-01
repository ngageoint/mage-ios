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
    var didSetupConstraints: Bool = false;
    var attachment: Attachment!
    var delegate: AskToDownloadDelegate?
    var url: URL?
    var scheme: MDCContainerScheming?;
    
    private lazy var thumbnail: AttachmentUIImageView = {
        let thumbnail = AttachmentUIImageView(image: nil);
        thumbnail.useDownloadPlaceholder = false;
        return thumbnail;
    }()
    
    private lazy var downloadBlock: UIView = {
        let downloadBlock = UIView(forAutoLayout: ());
        downloadBlock.backgroundColor = .black.withAlphaComponent(0.13);
        return downloadBlock;
    }()
    
    private lazy var emptyContentImage: UIImageView = {
        let emptyContentImage: UIImageView = UIImageView(image: UIImage(named: "big_download"));
        emptyContentImage.contentMode = .scaleAspectFit;
        return emptyContentImage;
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel: UILabel = UILabel();
        descriptionLabel.numberOfLines = 0;
        return descriptionLabel;
    }()
    
    private lazy var viewButton: MDCButton = {
        let viewButton: MDCButton = MDCButton(forAutoLayout: ());
        viewButton.accessibilityLabel = "View";
        viewButton.setTitle("View", for: .normal);
        viewButton.clipsToBounds = true;
        viewButton.addTarget(self, action: #selector(downloadApproved(_:)), for: .touchUpInside);
        return viewButton;
    }()
    
    @objc public convenience init(attachment: Attachment, delegate: AskToDownloadDelegate?) {
        self.init(nibName: nil, bundle: nil);
        self.attachment = attachment;
        self.delegate = delegate;
    }
    
    @objc public convenience init(url: URL, delegate: AskToDownloadDelegate?) {
        self.init(nibName: nil, bundle: nil);
        self.url = url;
        self.delegate = delegate;
    }
    
    @objc public func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme;

        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.viewButton.applyContainedTheme(withScheme: containerScheme);
        self.emptyContentImage.tintColor = containerScheme.colorScheme.onBackgroundColor.withAlphaComponent(0.6);
        self.downloadBlock.backgroundColor = containerScheme.colorScheme.onBackgroundColor.withAlphaComponent(0.6)
        self.descriptionLabel.textColor = containerScheme.colorScheme.backgroundColor;
        self.descriptionLabel.font = containerScheme.typographyScheme.body1;
    }

    override func viewDidLoad() {
        super.viewDidLoad();
        
        view.addSubview(thumbnail);
        view.addSubview(downloadBlock);
        view.addSubview(emptyContentImage);
        
        downloadBlock.addSubview(descriptionLabel);
        downloadBlock.addSubview(viewButton);
        
        thumbnail.autoPinEdgesToSuperviewEdges();
        downloadBlock.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top);
        emptyContentImage.autoCenterInSuperview();
        emptyContentImage.autoMatch(.width, to: .width, of: view, withMultiplier: 0.67);
        
        viewButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .top);
        descriptionLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .bottom);
        viewButton.autoPinEdge(.top, to: .bottom, of: descriptionLabel, withOffset: 16);
        
        self.downloadBlock.isHidden = true;
        if (!DataConnectionUtilities.shouldFetchAttachments()) {
            if (self.attachment.contentType?.hasPrefix("image") == true) {
                self.descriptionLabel.text = "Your attachment fetch settings do not allow auto downloading of images.  Would you like to view the image?";
            } else if (self.attachment.contentType?.hasPrefix("video") == true) {
                self.descriptionLabel.text = String.init(format: "Your attachment fetch settings do not allow auto downloading of videos.  This video is %.2FMB.  Would you like to view the video?", (self.attachment.size!.doubleValue / (1024.0 * 1024.0)));
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        self.showAttachment();
    }
    
    @IBAction func downloadApproved(_ sender: Any) {
        self.delegate?.downloadApproved();
    }
    
    func showAttachment(fullSize: Bool = false, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        
        self.thumbnail.setURL(url: self.url);
        self.thumbnail.setAttachment(attachment: self.attachment);
        if (self.thumbnail.isLargeSizeCached() == true) {
            self.delegate?.downloadApproved();
        } else {
            self.downloadBlock.isHidden = false;
            self.thumbnail.showImage(cacheOnly: true);
            if (self.thumbnail.placeholderIsRealImage == true) {
                self.emptyContentImage.isHidden = true
            }
        }
    }
}
