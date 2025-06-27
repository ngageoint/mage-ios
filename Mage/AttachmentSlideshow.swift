//
//  AttachmentSlideshow.swift
//  MAGE
//
//  Created by Daniel Barela on 1/22/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

class MDCActivityIndicatorProgress: Indicator {
    private let progressIndicatorView: IndicatorView
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    var view: IndicatorView {
        return progressIndicatorView
    }
    weak var parent: AttachmentUIImageView?
    
    func startAnimatingView() {
        view.isHidden = false
        self.activityIndicator.startAnimating();
    }
    func stopAnimatingView() {
        view.isHidden = true
        activityIndicator.stopAnimating();
    }
    
    func setProgress(progress: Float) {
        activityIndicator.progress = progress;
    }
    
    init(parent: AttachmentUIImageView) {
        self.parent = parent;
        self.progressIndicatorView = UIView(forAutoLayout: ());
        self.progressIndicatorView.layer.zPosition = 1000;
        self.progressIndicatorView.addSubview(activityIndicator);
        activityIndicator.autoCenterInSuperview();
    }
}

class AttachmentSlideShow: UIView {

    private var didSetUpConstraints = false;
    private var height: CGFloat = 150.0;
    private weak var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private var scheme: AppContainerScheming?;
    
    private lazy var slidescroll: UIScrollView = {
        let slidescroll = UIScrollView(forAutoLayout: ());
        slidescroll.isPagingEnabled = true;
        slidescroll.isScrollEnabled = true;
        slidescroll.delegate = self;
        slidescroll.contentSize = CGSize(width: CGFloat(self.bounds.width), height: height)
        slidescroll.isUserInteractionEnabled = true;
        return slidescroll;
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = true;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        stackView.isUserInteractionEnabled = true;
        return stackView;
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl();
        pageControl.currentPage = 0;
        pageControl.hidesForSinglePage = true;
        pageControl.addTarget(self, action: #selector(pageControlChangedValue), for: .valueChanged)
        return pageControl;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init() {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.isUserInteractionEnabled = true;
        slidescroll.addSubview(stackView);
        self.addSubview(slidescroll);
        self.addSubview(pageControl);
        setNeedsUpdateConstraints();
        self.accessibilityLabel = "attachment slideshow";
    }
    
    deinit {
        for subview in stackView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    func getAttachmentUrl(attachment: AttachmentModel) -> URL {
        if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
            return URL(fileURLWithPath: attachment.localPath!);
        } else {
            return URL(string: attachment.url!)!;
        }
    }
    
    func getAttachmentUrl(size: Int, attachment: AttachmentModel) -> URL {
        if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
            return URL(fileURLWithPath: attachment.localPath!);
        } else {
            return URL(string: String(format: "%@?size=%ld", attachment.url!, size))!;
        }
    }
    
    // everything should be set on this already
    func showThumbnail(imageView: AttachmentUIImageView, cacheOnly: Bool = !DataConnectionUtilities.shouldFetchAttachments()) {
        imageView.accessibilityLabel = "attachment \(imageView.attachment?.name ?? "")";

        let progress = UIActivityIndicatorView()
        progress.hidesWhenStopped = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.showThumbnail(cacheOnly: cacheOnly,
                                indicator: progress,
                                progressBlock: {
                                    receivedSize, totalSize in
                                    let percentage = (Float(receivedSize) / Float(totalSize))
                                    i.setProgress(progress: percentage);
                                },
                                completionHandler:
                                    { result in
                                        switch result {
                                        case .success(_):
                                            imageView.accessibilityLabel = "attachment \(imageView.attachment?.name ?? "") loaded";
                                            if (self.attachmentSelectionDelegate != nil) {
                                                imageView.isUserInteractionEnabled = true;
                                                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageViewTapped(sender:)))
                                                imageView.addGestureRecognizer(tapGesture);
                                            }
                                        case .failure(let error):
                                            if (self.attachmentSelectionDelegate != nil) {
                                                imageView.isUserInteractionEnabled = true;
                                                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.notCachedImageViewTapped(sender:)))
                                                imageView.addGestureRecognizer(tapGesture);
                                            }
                                            print(error);
                                        }
                                    });
    }
    
    func clear() {
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview();
        }
    }
    
    func populate(observation: Observation, attachmentSelectionDelegate: AttachmentSelectionDelegate?) {
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        
        guard let attachments = (observation.orderedAttachments)?.filter({ attachment in
            return attachment.url != nil
        }) else {
            return
        }
        // remove deleted attachments
        for view in stackView.arrangedSubviews {
            if let attachmentView: AttachmentUIImageView = view as? AttachmentUIImageView {
                if (attachmentView.attachment != nil && !attachments.contains(attachmentView.attachment!)) {
                    view.removeFromSuperview();
                }
            } else {
                view.removeFromSuperview();
            }
        }
        
        // add new ones
        for (_, attachment) in attachments.enumerated() {
            var imageView: AttachmentUIImageView? = nil;
            
            for view in stackView.arrangedSubviews {
                if let attachmentView: AttachmentUIImageView = view as? AttachmentUIImageView {
                    if (attachmentView.attachment != nil && attachment == attachmentView.attachment! && imageView == nil) {
                        imageView = attachmentView;
                        // already added this image view and loaded the thumbnail
                        if (attachmentView.loadedThumb) {
                            continue;
                        }
                    }
                }
            }
            if (imageView == nil) {
                imageView = AttachmentUIImageView(frame: CGRect(x: 0, y: 0, width: slidescroll.frame.size.width, height: height))
                imageView?.configureForAutoLayout();
                stackView.addArrangedSubview(imageView!);
                imageView?.autoMatch(.width, to: .width, of: slidescroll);
                imageView?.clipsToBounds = true
                imageView?.contentMode = .scaleAspectFill
                imageView?.isUserInteractionEnabled = true;
//                imageView?.kf.indicatorType = .activity;
            }
            
            guard let imageView = imageView else {
                return;
            }
            if (attachment.contentType?.hasPrefix("image") ?? false) {
                imageView.setAttachment(attachment: attachment);
                showThumbnail(imageView: imageView);
            } else if (attachment.contentType?.hasPrefix("video") ?? false) {
                let url = self.getAttachmentUrl(attachment: attachment);
                imageView.setAttachment(attachment: attachment);
                let localPath: String? = (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) ? attachment.localPath : nil
                let provider: VideoImageProvider = VideoImageProvider(sourceUrl: url, localPath: localPath);
                imageView.contentMode = .scaleAspectFit;
                DispatchQueue.main.async {
                    imageView.kf.setImage(with: provider, placeholder: UIImage(systemName: "play.circle.fill"), options: [
                        .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                        .transition(.fade(0.2)),
                        .scaleFactor(UIScreen.main.scale),
                        .cacheOriginalImage
                    ], completionHandler:
                        { result in
                            switch result {
                            case .success(_):
                                imageView.contentMode = .scaleAspectFill;
                                let overlay: UIImageView = UIImageView(image: UIImage(systemName: "play.circle.fill"));
                                overlay.contentMode = .scaleAspectFit;
                                imageView.addSubview(overlay);
                                overlay.autoCenterInSuperview();
                                if (attachmentSelectionDelegate != nil) {
                                    imageView.isUserInteractionEnabled = true;
                                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageViewTapped(sender:)))
                                    imageView.addGestureRecognizer(tapGesture);
                                }
                            case .failure(let error):
                                print(error);
                            }
                        });
                }
            } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
                imageView.image = UIImage(systemName: "speaker.wave.2.fill");
                imageView.contentMode = .scaleAspectFit;
                imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.4)
                imageView.setAttachment(attachment: attachment);
                if (attachmentSelectionDelegate != nil) {
                    imageView.isUserInteractionEnabled = true;
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageViewTapped(sender:)))
                    imageView.addGestureRecognizer(tapGesture);
                }
            } else {
                imageView.image = UIImage(systemName: "paperclip");
                imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.4)
                imageView.contentMode = .scaleAspectFit;
                imageView.setAttachment(attachment: attachment);
                
                let label = UILabel.newAutoLayout()
                label.text = attachment.name
                label.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
                label.font = scheme?.typographyScheme.overline
                label.autoSetDimension(.height, toSize: label.font.pointSize)
                imageView.addSubview(label)
                label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .bottom)
                
                if (attachmentSelectionDelegate != nil) {
                    imageView.isUserInteractionEnabled = true;
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageViewTapped(sender:)))
                    imageView.addGestureRecognizer(tapGesture);
                }
            }
            
        }
        
        slidescroll.contentSize = CGSize(width: CGFloat(attachments.count) * CGFloat(self.bounds.width), height: height)
        pageControl.numberOfPages = attachments.count;
    }
    
    @objc func imageViewTapped(sender: UITapGestureRecognizer) {
        let attachmentImageView:AttachmentUIImageView = sender.view as! AttachmentUIImageView;
        attachmentSelectionDelegate?.selectedAttachment(attachmentImageView.attachment?.attachmentUri);
    }
    
    @objc func notCachedImageViewTapped(sender: UITapGestureRecognizer) {
        let attachmentImageView:AttachmentUIImageView = sender.view as! AttachmentUIImageView;
//        attachmentImageView.kf.indicatorType = .activity;
        attachmentSelectionDelegate?.selectedNotCachedAttachment(attachmentImageView.attachment?.attachmentUri, completionHandler: { forceDownload in
            self.showThumbnail(imageView: attachmentImageView, cacheOnly: !forceDownload);
        });
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            autoSetDimension(.height, toSize: height);
            slidescroll.autoPinEdgesToSuperviewEdges();
            stackView.autoPinEdgesToSuperviewEdges();
            stackView.autoMatch(.height, to: .height, of: slidescroll);
            pageControl.autoPinEdge(toSuperviewEdge: .bottom, withInset: 8);
            pageControl.autoAlignAxis(toSuperviewAxis: .vertical);
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func applyTheme(withScheme scheme: AppContainerScheming?) {
        self.scheme = scheme;
        self.backgroundColor = scheme?.colorScheme.backgroundColor;
        self.pageControl.pageIndicatorTintColor = scheme?.colorScheme.onPrimaryColor.withAlphaComponent(0.6);
        self.pageControl.currentPageIndicatorTintColor = scheme?.colorScheme.primaryColor;
        for view in stackView.arrangedSubviews {
            view.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.4);
        }
    }
    
    @objc func pageControlChangedValue() {
        let currentPage = self.pageControl.currentPage;
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.slidescroll.contentOffset.x = CGFloat(currentPage) * self.slidescroll.frame.size.width
            }, completion: nil)
        }
    }
}

extension AttachmentSlideShow : UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
}
