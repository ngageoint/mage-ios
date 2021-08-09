//
//  AttachmentCell.m
//  Mage
//
//
import UIKit
import Kingfisher

@objc class AttachmentCell: UICollectionViewCell {
    
    private var button: MDCFloatingButton?;
    
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
        if let safeButton = button {
            safeButton.removeFromSuperview();
        }
    }

    func getAttachmentUrl(size: Int, attachment: Attachment) -> URL {
        if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
            return URL(fileURLWithPath: attachment.localPath!);
        } else {
            return URL(string: String(format: "%@?size=%ld", attachment.url!, size))!;
        }
    }
    
    override func removeFromSuperview() {
        self.imageView.cancel();
    }
    
    @objc public func setImage(newAttachment: [String : AnyHashable], button: MDCFloatingButton? = nil, scheme: MDCContainerScheming? = nil) {
        layoutSubviews();
        self.button = button;
        self.imageView.setImage(url: URL(fileURLWithPath: newAttachment["localPath"] as! String), cacheOnly: !DataConnectionUtilities.shouldFetchAttachments());
        self.imageView.accessibilityLabel = "attachment \(newAttachment["localPath"] as! String) loaded";
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4);
        self.imageView.contentMode = .scaleAspectFit;
        
        if let safeButton = button {
            self.addSubview(safeButton);
            safeButton.autoPinEdge(.bottom, to: .bottom, of: self.imageView, withOffset: -8);
            safeButton.autoPinEdge(.right, to: .right, of: self.imageView, withOffset: -8);
        }
    }
    
    @objc public func setImage(attachment: Attachment, formatName:NSString, button: MDCFloatingButton? = nil, scheme: MDCContainerScheming? = nil) {
        layoutSubviews();
        self.button = button;
        self.imageView.kf.indicatorType = .activity;
        let imageSize: Int = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
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
            let url = self.getAttachmentUrl(size: imageSize, attachment: attachment);
            var localPath: String? = nil;
            if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
                localPath = attachment.localPath;
            }
            let provider: VideoImageProvider = VideoImageProvider(url: url, localPath: localPath);
            self.imageView.contentMode = .scaleAspectFit;
            self.imageView.kf.setImage(with: provider, placeholder: UIImage(named: "play_overlay"), options: [
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
                        let overlay: UIImageView = UIImageView(image: UIImage(named: "play_overlay"));
                        overlay.contentMode = .scaleAspectFit;
                        self.imageView.addSubview(overlay);
                        overlay.autoCenterInSuperview();
                    case .failure(let error):
                        print(error);
                        self.imageView.backgroundColor = UIColor.init(white: 0, alpha: 0.06);
                        let overlay: UIImageView = UIImageView(image: UIImage.init(named: "play_overlay"));
                        overlay.contentMode = .scaleAspectFit;
                        self.imageView.addSubview(overlay);
                    }
                });
            
        } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
            self.imageView.image = UIImage(named: "audio_thumbnail");
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded";
            self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4);
            self.imageView.contentMode = .scaleAspectFit;
        } else {
            self.imageView.image = UIImage(named: "paperclip_thumbnail");
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded";
            self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4);
            self.imageView.contentMode = .scaleAspectFit;
        }
        
        if let safeButton = button {
            self.addSubview(safeButton);
            safeButton.autoPinEdge(.bottom, to: .bottom, of: self.imageView, withOffset: -8);
            safeButton.autoPinEdge(.right, to: .right, of: self.imageView, withOffset: -8);
        }
    }
}
