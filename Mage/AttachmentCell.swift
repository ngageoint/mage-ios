//
//  AttachmentCell.m
//  Mage
//
//
import UIKit
import Kingfisher

@objc class AttachmentCell: UICollectionViewCell {
    
    private var button: UIButton?;
    
    private lazy var imageView: AttachmentUIImageView = {
        let imageView: AttachmentUIImageView = AttachmentUIImageView(image: nil);
        imageView.configureForAutoLayout();
        imageView.clipsToBounds = true;
        return imageView;
    }();
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.configureForAutoLayout();
        self.addSubview(imageView);
        imageView.autoPinEdgesToSuperviewEdges();
        setNeedsLayout();
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
    }
    
    func getAttachmentUrl(attachment: AttachmentModel) -> URL? {
        if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath);
        } else if let url = attachment.url {
            return URL(string: url);
        }
        return nil;
    }

    func getAttachmentUrl(size: Int, attachment: AttachmentModel) -> URL? {
        if let localPath = attachment.localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath);
        } else if let url = attachment.url {
            return URL(string: String(format: "%@?size=%ld", url, size));
        }
        return nil;
    }
    
    override func removeFromSuperview() {
        self.imageView.cancel();
    }
    
    @objc public func setImage(newAttachment: [String : AnyHashable], button: UIButton? = nil, scheme: AppContainerScheming? = nil) {
        layoutSubviews()
        self.button = button
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor?.withAlphaComponent(0.4)
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
            label.textColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
//            label.font = scheme?.typographyScheme.overline
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
    
    @objc public func setImage(attachment: AttachmentModel, formatName:NSString, button: UIButton? = nil, scheme: AppContainerScheming? = nil) {
        layoutSubviews();
        self.button = button;
        self.imageView.kf.indicatorType = .none;
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor?.withAlphaComponent(0.4);
        if (attachment.contentType?.hasPrefix("image") ?? false) {
            self.imageView.setAttachment(attachment: attachment);
            self.imageView.tintColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.87);
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loading";
            self.imageView.showThumbnail(cacheOnly: !DataConnectionUtilities.shouldFetchAttachments(),
                                         completionHandler:
                                            { [weak self] result in
                                                switch result {
                                                case .success(_):
                                                    self?.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded";
                                                    NSLog("Loaded the image \(self?.imageView.accessibilityLabel ?? "")")
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
            label.textColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
//            label.font = scheme?.typographyScheme.overline
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
