//
//  AttachmentCell.m
//  Mage
//
//
import UIKit
import Kingfisher
import Persistence
import MaterialComponents.MaterialRipple

@objc class AttachmentCell: UICollectionViewCell {

    private var button: MDCFloatingButton?;
    private var attachment: Attachment?;
    private var messageExpanded = false;
    private var hintLabel: UILabel?;
    private var hintLabelHeightConstraint: NSLayoutConstraint?;
    private var failureIcon: UIImageView?;

    private lazy var imageView: AttachmentUIImageView = {
        let imageView: AttachmentUIImageView = AttachmentUIImageView(image: nil);
        imageView.configureForAutoLayout();
        imageView.clipsToBounds = true;
        return imageView;
    }();

    // Driven manually from touchesBegan/Ended/Cancelled below, same technique MDCCard uses -
    // there's no gesture recognizer here to hang a ripple off of since taps on this cell are
    // handled a few different ways (collection view selection, the failure-message toggle).
    private lazy var rippleView: MDCRippleView = {
        let ripple = MDCRippleView(forAutoLayout: ());
        ripple.rippleStyle = .bounded;
        ripple.isUserInteractionEnabled = false;
        return ripple;
    }();

    override init(frame: CGRect) {
        super.init(frame: frame);
        self.configureForAutoLayout();
        self.addSubview(imageView);
        imageView.autoPinEdgesToSuperviewEdges();
        self.addSubview(rippleView);
        rippleView.autoPinEdgesToSuperviewEdges();
        setNeedsLayout();
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event);
        if let point = touches.first?.location(in: rippleView) {
            rippleView.beginRippleTouchDown(at: point, animated: true, completion: nil);
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event);
        rippleView.beginRippleTouchUp(animated: true, completion: nil);
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event);
        rippleView.beginRippleTouchUp(animated: true, completion: nil);
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        self.imageView.kf.cancelDownloadTask();
        self.imageView.image = nil;
        for view in self.imageView.subviews{
            view.removeFromSuperview()
        }
        button?.removeFromSuperview();
        self.attachment = nil;
        self.messageExpanded = false;
        self.hintLabel = nil;
        self.hintLabelHeightConstraint = nil;
        self.failureIcon = nil;
        for recognizer in self.imageView.gestureRecognizers ?? [] {
            self.imageView.removeGestureRecognizer(recognizer);
        }
    }

    @objc func toggleFailureMessage() {
        guard let hintLabel = hintLabel, let hintLabelHeightConstraint = hintLabelHeightConstraint else { return }
        messageExpanded.toggle();
        failureIcon?.isHidden = messageExpanded;
        if (messageExpanded) {
            hintLabel.text = attachment?.processingMessage ?? "Upload failed";
            hintLabel.numberOfLines = 0;
        } else {
            hintLabel.text = "Tap for Details";
            hintLabel.numberOfLines = 1;
        }

        let width = imageView.bounds.width - 16;
        let collapsedHeight = hintLabel.font.pointSize;
        if (messageExpanded && width > 0) {
            let boundingHeight = (hintLabel.text as NSString?)?.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: [.font: hintLabel.font as Any],
                context: nil
            ).height ?? collapsedHeight;
            hintLabelHeightConstraint.constant = ceil(boundingHeight);
        } else {
            hintLabelHeightConstraint.constant = collapsedHeight;
        }

        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded();
        }
    }
    
    func getAttachmentUrl(attachment: Attachment) -> URL? {
        if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath);
        } else if let url = attachment.url {
            return URL(string: url);
        }
        return nil;
    }

    func getAttachmentUrl(size: Int, attachment: Attachment) -> URL? {
        if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath);
        } else if let url = attachment.url {
            return URL(string: String(format: "%@?size=%ld", url, size));
        }
        return nil;
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        self.imageView.cancel();
    }
    
    @objc public func setImage(newAttachment: [String : AnyHashable], button: MDCFloatingButton? = nil, scheme: MDCContainerScheming? = nil) {
        layoutSubviews()
        self.button = button
        self.rippleView.rippleColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.16) ?? UIColor.black.withAlphaComponent(0.16)
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.kf.indicatorType = .none
        guard let contentType = newAttachment["contentType"] as? String, let localPath = newAttachment["localPath"] as? String else {
            return
        }
        if (contentType.hasPrefix("image")) {
            self.imageView.setImage(url: URL(fileURLWithPath: localPath), cacheOnly: !DataConnectionUtilities.shouldFetchAttachments())
            self.imageView.accessibilityLabel = "attachment \(localPath) loaded"
        } else if (contentType.hasPrefix("video")) {
            let provider: VideoImageProvider = VideoImageProvider(localPath: localPath);
            let overlay: UIImageView = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            overlay.contentMode = .scaleAspectFit
            self.imageView.addSubview(overlay)
            overlay.autoCenterInSuperview()
            DispatchQueue.main.async {
                self.imageView.kf.setImage(with: provider, placeholder: UIImage(systemName: "play.circle.fill"), options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .transition(.fade(0.2)),
                    .scaleFactor(UIScreen.main.scale),
                    .processor(DownsamplingImageProcessor(size: self.imageView.frame.size)),
                    .diskCacheExpiration(StorageExpiration.seconds(300)),
                ])
            }
        } else if (contentType.hasPrefix("audio")) {
            self.imageView.image = UIImage(systemName: "speaker.wave.2.fill")
            self.imageView.accessibilityLabel = "audio attachment loaded"
            self.imageView.contentMode = .scaleAspectFit
        } else {
            self.imageView.image = UIImage(systemName: "paperclip")
            self.imageView.accessibilityLabel = "\(contentType) loaded"
            self.imageView.contentMode = .scaleAspectFit
            let label = UILabel.newAutoLayout()
            label.text = newAttachment["contentType"] as? String
            label.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            label.font = scheme?.typographyScheme.overline
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.autoSetDimension(.height, toSize: label.font.pointSize)
            imageView.addSubview(label)
            label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .bottom)
        }
        
        self.backgroundColor = scheme?.colorScheme.surfaceColor

        if let button = button {
            self.addSubview(button);
            button.autoPinEdge(.bottom, to: .bottom, of: self.imageView, withOffset: -8);
            button.autoPinEdge(.right, to: .right, of: self.imageView, withOffset: -8);
        }
    }
    
    @objc public func setImage(attachment: Attachment, formatName:NSString, button: MDCFloatingButton? = nil, scheme: MDCContainerScheming? = nil) {
        layoutSubviews();
        self.button = button;
        self.attachment = attachment;
        self.rippleView.rippleColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.16) ?? UIColor.black.withAlphaComponent(0.16);
        self.imageView.kf.indicatorType = .none;
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4);

        if (attachment.isProcessingFailed) {
            self.imageView.image = nil;
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") upload failed";
            self.imageView.isUserInteractionEnabled = true;
            self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFailureMessage)));
            self.messageExpanded = false;

            let titleLabel = UILabel.newAutoLayout()
            titleLabel.text = "Upload Failed"
            titleLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
            titleLabel.font = scheme?.typographyScheme.subtitle1
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 1
            titleLabel.autoSetDimension(.height, toSize: titleLabel.font.lineHeight)

            let descriptionLabel = UILabel.newAutoLayout()
            descriptionLabel.text = attachment.name
            descriptionLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            descriptionLabel.font = scheme?.typographyScheme.caption
            descriptionLabel.textAlignment = .center
            descriptionLabel.numberOfLines = 1
            descriptionLabel.lineBreakMode = .byTruncatingTail
            descriptionLabel.autoSetDimension(.height, toSize: descriptionLabel.font.lineHeight)

            let iconConfig = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular);
            let icon = UIImageView.newAutoLayout()
            icon.image = UIImage(systemName: "exclamationmark.circle")?.withConfiguration(iconConfig);
            icon.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
            icon.contentMode = .scaleAspectFit;
            icon.autoSetDimensions(to: CGSize(width: 56, height: 56));
            self.failureIcon = icon;

            let hintLabel = UILabel.newAutoLayout()
            hintLabel.text = "Tap for Details"
            hintLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.4)
            hintLabel.font = UIFont.systemFont(ofSize: 10)
            hintLabel.textAlignment = .center
            hintLabel.numberOfLines = 1
            let hintLabelHeightConstraint = hintLabel.autoSetDimension(.height, toSize: hintLabel.font.pointSize)
            self.hintLabel = hintLabel;
            self.hintLabelHeightConstraint = hintLabelHeightConstraint;

            // The whole group is centered as a single unit rather than anchored from any one
            // fixed point, so it stays centered whether or not the icon is showing. UIStackView
            // automatically collapses a hidden arranged subview's space, so hiding the icon on
            // tap re-centers the remaining title/description/hint group for free.
            let group = UIStackView(forAutoLayout: ());
            group.axis = .vertical;
            group.alignment = .center;
            group.spacing = 2;
            group.addArrangedSubview(icon);
            group.setCustomSpacing(8, after: icon);
            group.addArrangedSubview(titleLabel);
            group.addArrangedSubview(descriptionLabel);
            group.addArrangedSubview(hintLabel);
            imageView.addSubview(group);
            group.autoCenterInSuperview();

            // Width constraints against imageView are only legal now that titleLabel/
            // descriptionLabel/hintLabel actually share a view hierarchy with it (via group).
            titleLabel.autoMatch(.width, to: .width, of: imageView, withOffset: -16)
            descriptionLabel.autoMatch(.width, to: .width, of: imageView, withOffset: -16)
            hintLabel.autoMatch(.width, to: .width, of: imageView, withOffset: -16)

            self.backgroundColor = scheme?.colorScheme.backgroundColor

            if let button = button {
                self.addSubview(button);
                button.autoPinEdge(.bottom, to: .bottom, of: self.imageView, withOffset: -8);
                button.autoPinEdge(.right, to: .right, of: self.imageView, withOffset: -8);
            }

            return;
        }

        if (attachment.isUploading) {
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular);
            self.imageView.image = UIImage(systemName: "arrow.up.circle")?.withConfiguration(iconConfig);
            self.imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
            self.imageView.contentMode = .center;
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") uploading";

            let label = UILabel.newAutoLayout()
            label.text = "\(attachment.name ?? "")\nUploading..."
            label.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            label.font = scheme?.typographyScheme.overline
            label.textAlignment = .center
            label.numberOfLines = 2
            label.lineBreakMode = .byTruncatingTail
            label.autoSetDimension(.height, toSize: label.font.lineHeight * 2)
            imageView.addSubview(label)
            label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .top)

            self.backgroundColor = scheme?.colorScheme.backgroundColor
            return;
        }

        if (attachment.isProcessingPending) {
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular);
            self.imageView.image = UIImage(systemName: "icloud.and.arrow.up")?.withConfiguration(iconConfig);
            self.imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
            self.imageView.contentMode = .center;
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") upload pending";

            let label = UILabel.newAutoLayout()
            label.text = "\(attachment.name ?? "")\nUpload pending..."
            label.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            label.font = scheme?.typographyScheme.overline
            label.textAlignment = .center
            label.numberOfLines = 2
            label.lineBreakMode = .byTruncatingTail
            label.autoSetDimension(.height, toSize: label.font.lineHeight * 2)
            imageView.addSubview(label)
            label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .top)

            self.backgroundColor = scheme?.colorScheme.backgroundColor
            return;
        }

        if (attachment.contentType?.hasPrefix("image") ?? false) {
            self.imageView.setAttachment(attachment: attachment);
            self.imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loading";
            self.imageView.showThumbnail(cacheOnly: !DataConnectionUtilities.shouldFetchAttachments(),
                                         completionHandler:
                                            { result in
                                                switch result {
                                                case .success(_):
                                                    self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded";
                                                    NSLog("Loaded the image \(self.imageView.accessibilityLabel ?? "")")
                                                case .failure(let error):
                                                    print(error);
                                                }
                                            });
        } else if (attachment.contentType?.hasPrefix("video") ?? false) {
            guard let url = self.getAttachmentUrl(attachment: attachment) else {
                self.imageView.contentMode = .scaleAspectFit;
                self.imageView.image = UIImage(named: "upload");
                return;
            }
            var localPath: String? = nil;
            if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
                localPath = attachment.localPath;
            }
            let provider: VideoImageProvider = VideoImageProvider(sourceUrl: url, localPath: localPath);
            self.imageView.contentMode = .scaleAspectFit;
            DispatchQueue.main.async {
                self.imageView.kf.setImage(with: provider, placeholder: UIImage(systemName: "play.circle.fill"), options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .transition(.fade(0.2)),
                    .scaleFactor(UIScreen.main.scale),
                    .processor(DownsamplingImageProcessor(size: self.imageView.frame.size)),
                    .cacheOriginalImage
                ], completionHandler:
                    { result in
                        switch result {
                        case .success(_):
                            self.imageView.contentMode = .scaleAspectFill;
                            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded";
                            let overlay: UIImageView = UIImageView(image: UIImage(systemName: "play.circle.fill"));
                            overlay.contentMode = .scaleAspectFit;
                            self.imageView.addSubview(overlay);
                            overlay.autoCenterInSuperview();
                        case .failure(let error):
                            print(error);
                        }
                    });
            }
        } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
            self.imageView.image = UIImage(systemName: "speaker.wave.2.fill");
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded";
            self.imageView.contentMode = .scaleAspectFit;
        } else {
            self.imageView.image = UIImage(systemName: "paperclip");
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded";
            self.imageView.contentMode = .scaleAspectFit;
            let label = UILabel.newAutoLayout()
            label.text = attachment.name
            label.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            label.font = scheme?.typographyScheme.overline
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.autoSetDimension(.height, toSize: label.font.pointSize)
            imageView.addSubview(label)
            label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .bottom)
        }
        
        self.backgroundColor = scheme?.colorScheme.backgroundColor
        
        if let button = button {
            self.addSubview(button);
            button.autoPinEdge(.bottom, to: .bottom, of: self.imageView, withOffset: -8);
            button.autoPinEdge(.right, to: .right, of: self.imageView, withOffset: -8);
        }
    }
}
