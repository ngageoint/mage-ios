//
//  AttachmentCell.swift
//  Mage
//

import UIKit
import Kingfisher

@objc class AttachmentCell: UICollectionViewCell {

    private var button: MDCFloatingButton?

    private lazy var imageView: AttachmentUIImageView = {
        let imageView = AttachmentUIImageView(image: nil)
        imageView.configureForAutoLayout()
        imageView.clipsToBounds = true
        return imageView
    }()

    /// Centralized toggle derived from app’s policy (Wi-Fi only, etc.)
    /// If `false`, we’ll pass `.onlyFromCache` so Kingfisher won’t hit the network.
    private var allowRemoteFetch: Bool {
        DataConnectionUtilities.shouldFetchAttachments()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureForAutoLayout()
        self.addSubview(imageView)
        imageView.autoPinEdgesToSuperviewEdges()
        setNeedsLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        self.imageView.kf.cancelDownloadTask()
        self.imageView.image = nil
        for view in self.imageView.subviews {
            view.removeFromSuperview()
        }
        button?.removeFromSuperview()
    }

    override func removeFromSuperview() {
        self.imageView.cancel()
        super.removeFromSuperview()
    }

    // MARK: - Helpers

    /// Prefer local (healed) URL if it exists; else remote.
    func getAttachmentUrl(attachment: AttachmentModel) -> URL? {
        if let localURL = AttachmentPath.localURL(fromStored: attachment.localPath,
                                                 fileName: attachment.name) {
            return localURL
        }
        if let urlString = attachment.url { return URL(string: urlString) }
        return nil
    }

    /// Prefer local (healed) URL if it exists; else remote with `?size=...`.
    func getAttachmentUrl(size: Int, attachment: AttachmentModel) -> URL? {
        if let localURL = AttachmentPath.localURL(fromStored: attachment.localPath,
                                                 fileName: attachment.name) {
            return localURL
        }
        if let urlString = attachment.url {
            return URL(string: String(format: "%@?size=%ld", urlString, size))
        }
        return nil
    }

    // MARK: - Dictionary-based API

    @objc public func setImage(newAttachment: [String : AnyHashable],
                              button: MDCFloatingButton? = nil,
                              scheme: MDCContainerScheming? = nil) {
        self.button = button
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.kf.indicatorType = .none

        guard let contentType = newAttachment["contentType"] as? String else { return }
        let storedLocalPath = newAttachment["localPath"] as? String
        let fileName       = newAttachment["name"] as? String

        if contentType.hasPrefix("image") {
            let healedURL = AttachmentPath.localURL(fromStored: storedLocalPath, fileName: fileName)

            if let localURL = healedURL {
                self.imageView.setImage(url: localURL, cacheOnly: !allowRemoteFetch)
                self.imageView.accessibilityLabel = "attachment \(localURL.lastPathComponent) loaded"
            } else if
                let remote = newAttachment["url"] as? String,
                let remoteURL = URL(string: remote) {
                self.imageView.setImage(url: remoteURL, cacheOnly: !allowRemoteFetch)
                self.imageView.accessibilityLabel = "attachment \(remoteURL.lastPathComponent) loaded"
            } else {
                self.imageView.image = UIImage(systemName: "photo")
                self.imageView.contentMode = .scaleAspectFit
                self.imageView.accessibilityLabel = "image attachment placeholder"
            }

        } else if contentType.hasPrefix("video") {
            // Prefer a normalized local poster frame if present
            let normalizedLocal = AttachmentPath.localURL(fromStored: storedLocalPath, fileName: fileName)
            let normalizedLocalPath = normalizedLocal?.path ?? storedLocalPath ?? ""
            let provider = VideoImageProvider(localPath: normalizedLocalPath)

            let overlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            overlay.contentMode = .scaleAspectFit
            self.imageView.addSubview(overlay)
            overlay.autoCenterInSuperview()

            DispatchQueue.main.async {
                var opts: KingfisherOptionsInfo = [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .transition(.fade(0.2)),
                    .scaleFactor(UIScreen.main.scale),
                    .processor(DownsamplingImageProcessor(size: self.imageView.frame.size)),
                    .diskCacheExpiration(.seconds(300))
                ]
                if !self.allowRemoteFetch {
                    opts.append(.onlyFromCache)
                }

                self.imageView.kf.setImage(
                    with: provider,
                    placeholder: UIImage(systemName: "play.circle.fill"),
                    options: opts
                )
            }

        } else if contentType.hasPrefix("audio") {
            self.imageView.image = UIImage(systemName: "speaker.wave.2.fill")
            self.imageView.contentMode = .scaleAspectFit
            self.imageView.accessibilityLabel = "audio attachment loaded"

        } else {
            self.imageView.image = UIImage(systemName: "paperclip")
            self.imageView.contentMode = .scaleAspectFit
            self.imageView.accessibilityLabel = "\(contentType) loaded"

            let label = UILabel.newAutoLayout()
            label.text = fileName ?? contentType
            label.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            label.font = scheme?.typographyScheme.overline
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.autoSetDimension(.height, toSize: label.font.pointSize)
            imageView.addSubview(label)
            label.autoPinEdgesToSuperviewEdges(
                with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
                excludingEdge: .bottom
            )
        }

        self.backgroundColor = scheme?.colorScheme.surfaceColor

        if let button = button {
            self.addSubview(button)
            button.autoPinEdge(.bottom, to: .bottom, of: self.imageView, withOffset: -8)
            button.autoPinEdge(.right,  to: .right,  of: self.imageView, withOffset: -8)
        }
    }

    // MARK: - Model-based API

    @objc public func setImage(attachment: AttachmentModel,
                               formatName: NSString,
                               button: MDCFloatingButton? = nil,
                               scheme: MDCContainerScheming? = nil) {
        self.button = button
        self.imageView.kf.indicatorType = .none
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4)

        if (attachment.contentType?.hasPrefix("image") ?? false) {
            // Local-first; AttachmentUIImageView handles thumb/full selection
            self.imageView.setAttachment(attachment: attachment)
            self.imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loading"
            self.imageView.showThumbnail(
                cacheOnly: !allowRemoteFetch,
                completionHandler: { [weak self] result in
                    switch result {
                    case .success:
                        self?.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded"
                        NSLog("Loaded the image \(self?.imageView.accessibilityLabel ?? "")")
                    case .failure(let error):
                        print(error)
                    }
                }
            )

        } else if (attachment.contentType?.hasPrefix("video") ?? false) {
            guard let sourceURL = self.getAttachmentUrl(attachment: attachment) else {
                self.imageView.contentMode = .scaleAspectFit
                self.imageView.image = UIImage(named: "upload")
                return
            }

            let normalizedLocal = AttachmentPath.localURL(fromStored: attachment.localPath,
                                                          fileName: attachment.name)?.path
            let provider = VideoImageProvider(sourceUrl: sourceURL, localPath: normalizedLocal)

            self.imageView.contentMode = .scaleAspectFit
            DispatchQueue.main.async {
                var opts: KingfisherOptionsInfo = [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .transition(.fade(0.2)),
                    .scaleFactor(UIScreen.main.scale),
                    .processor(DownsamplingImageProcessor(size: self.imageView.frame.size)),
                    .cacheOriginalImage
                ]
                if !self.allowRemoteFetch {
                    opts.append(.onlyFromCache)
                }

                self.imageView.kf.setImage(
                    with: provider,
                    placeholder: UIImage(systemName: "play.circle.fill"),
                    options: opts
                ) { result in
                    switch result {
                    case .success:
                        self.imageView.contentMode = .scaleAspectFill
                        self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded"
                        let overlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                        overlay.contentMode = .scaleAspectFit
                        self.imageView.addSubview(overlay)
                        overlay.autoCenterInSuperview()
                    case .failure(let error):
                        print(error)
                    }
                }
            }

        } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
            self.imageView.image = UIImage(systemName: "speaker.wave.2.fill")
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded"
            self.imageView.contentMode = .scaleAspectFit

        } else {
            self.imageView.image = UIImage(systemName: "paperclip")
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded"
            self.imageView.contentMode = .scaleAspectFit
            let label = UILabel.newAutoLayout()
            label.text = attachment.name
            label.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            label.font = scheme?.typographyScheme.overline
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.autoSetDimension(.height, toSize: label.font.pointSize)
            imageView.addSubview(label)
            label.autoPinEdgesToSuperviewEdges(
                with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
                excludingEdge: .bottom
            )
        }

        self.backgroundColor = scheme?.colorScheme.backgroundColor

        if let button = button {
            self.addSubview(button)
            button.autoPinEdge(.bottom, to: .bottom, of: self.imageView, withOffset: -8)
            button.autoPinEdge(.right, to: .right, of: self.imageView, withOffset: -8)
        }
    }
}
