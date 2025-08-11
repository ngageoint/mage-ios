//
//  AttachmentCell.swift
//  Mage
//

import UIKit
import Kingfisher

@objc class AttachmentCell: UICollectionViewCell {

    private var button: MDCFloatingButton?

    private lazy var imageView: AttachmentUIImageView = {
        let iv = AttachmentUIImageView(image: nil)
        iv.configureForAutoLayout()
        iv.clipsToBounds = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Important: don't call configureForAutoLayout() on the cell itself
        contentView.addSubview(imageView)
        imageView.autoPinEdgesToSuperviewEdges()
        setNeedsLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.subviews.forEach { $0.removeFromSuperview() }
        button?.removeFromSuperview()
        button = nil
    }

    override func removeFromSuperview() {
        imageView.cancel()
        super.removeFromSuperview()
    }

    // MARK: - Helpers (prefer healed local else remote)

    private func healedLocalURL(localPath: String?, name: String?) -> URL? {
        guard let localPath = localPath else { return nil }
        guard let healed = resolveLocalFileURL(from: localPath, fileName: name) else { return nil }
        return FileManager.default.fileExists(atPath: healed.path) ? healed : nil
    }

    private func remoteURLString(_ dict: [String: AnyHashable]) -> String? {
        dict["url"] as? String
    }

    // MARK: - Dictionary-based API

    @objc public func setImage(newAttachment: [String : AnyHashable],
                               button: MDCFloatingButton? = nil,
                               scheme: MDCContainerScheming? = nil) {

        self.button = button
        imageView.kf.indicatorType = .none
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4)

        guard let contentType = newAttachment["contentType"] as? String else { return }
        let storedLocalPath = newAttachment["localPath"] as? String
        let fileName       = newAttachment["name"] as? String

        if contentType.hasPrefix("image") {
            if let localURL = healedLocalURL(localPath: storedLocalPath, name: fileName) {
                imageView.setImage(
                    url: localURL,
                    cacheOnly: !DataConnectionUtilities.shouldFetchAttachments()
                )
                imageView.accessibilityLabel = "attachment \(localURL.lastPathComponent) loaded"
            } else if
                let remote = remoteURLString(newAttachment),
                let remoteURL = URL(string: remote)
            {
                imageView.setImage(url: remoteURL, cacheOnly: false)
                imageView.accessibilityLabel = "attachment \(remoteURL.lastPathComponent) loaded"
            } else {
                imageView.image = UIImage(systemName: "photo")
                imageView.contentMode = .scaleAspectFit
                imageView.accessibilityLabel = "image attachment placeholder"
            }

        } else if contentType.hasPrefix("video") {
            // Prefer a normalized local poster if we have one
            let normalizedLocal = healedLocalURL(localPath: storedLocalPath, name: fileName)
            let provider = VideoImageProvider(localPath: normalizedLocal?.path ?? storedLocalPath ?? "")

            let overlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            overlay.contentMode = .scaleAspectFit
            imageView.addSubview(overlay)
            overlay.autoCenterInSuperview()

            DispatchQueue.main.async {
                self.imageView.kf.setImage(
                    with: provider,
                    placeholder: UIImage(systemName: "play.circle.fill"),
                    options: [
                        .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                        .transition(.fade(0.2)),
                        .scaleFactor(UIScreen.main.scale),
                        .processor(DownsamplingImageProcessor(size: self.imageView.frame.size)),
                        .diskCacheExpiration(.seconds(300))
                    ]
                )
            }

        } else if contentType.hasPrefix("audio") {
            imageView.image = UIImage(systemName: "speaker.wave.2.fill")
            imageView.contentMode = .scaleAspectFit
            imageView.accessibilityLabel = "audio attachment loaded"

        } else {
            imageView.image = UIImage(systemName: "paperclip")
            imageView.contentMode = .scaleAspectFit
            imageView.accessibilityLabel = "\(contentType) loaded"

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

        backgroundColor = scheme?.colorScheme.surfaceColor

        if let button = button {
            addSubview(button)
            button.autoPinEdge(.bottom, to: .bottom, of: imageView, withOffset: -8)
            button.autoPinEdge(.right,  to: .right,  of: imageView, withOffset: -8)
        }
    }

    // MARK: - Model-based API

    @objc public func setImage(attachment: AttachmentModel,
                               formatName: NSString,
                               button: MDCFloatingButton? = nil,
                               scheme: MDCContainerScheming? = nil) {

        self.button = button
        imageView.kf.indicatorType = .none
        imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4)

        if (attachment.contentType?.hasPrefix("image") ?? false) {
            // Uses AttachmentUIImageView’s existing helpers; they should consult healed local paths internally
            imageView.setAttachment(attachment: attachment)
            imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
            imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loading"

            imageView.showThumbnail(
                cacheOnly: !DataConnectionUtilities.shouldFetchAttachments()
            ) { [weak self] result in
                switch result {
                case .success:
                    self?.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded"
                    NSLog("Loaded the image \(self?.imageView.accessibilityLabel ?? "")")
                case .failure(let error):
                    print(error)
                }
            }

        } else if (attachment.contentType?.hasPrefix("video") ?? false) {
            // Source is remote-or-local URL used by the provider; prefer local if present
            let sourceURL: URL? = {
                if let healed = healedLocalURL(localPath: attachment.localPath, name: attachment.name) {
                    return healed
                }
                // fall back to tokenized remote
                return attachment.urlWithToken
            }()

            guard let src = sourceURL else {
                imageView.contentMode = .scaleAspectFit
                imageView.image = UIImage(named: "upload")
                return
            }

            let normalizedLocalPath = healedLocalURL(localPath: attachment.localPath, name: attachment.name)?.path
            let provider = VideoImageProvider(sourceUrl: src, localPath: normalizedLocalPath)

            imageView.contentMode = .scaleAspectFit
            DispatchQueue.main.async {
                self.imageView.kf.setImage(
                    with: provider,
                    placeholder: UIImage(systemName: "play.circle.fill"),
                    options: [
                        .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                        .transition(.fade(0.2)),
                        .scaleFactor(UIScreen.main.scale),
                        .processor(DownsamplingImageProcessor(size: self.imageView.frame.size)),
                        .cacheOriginalImage
                    ]
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
            imageView.image = UIImage(systemName: "speaker.wave.2.fill")
            imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded"
            imageView.contentMode = .scaleAspectFit

        } else {
            imageView.image = UIImage(systemName: "paperclip")
            imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded"
            imageView.contentMode = .scaleAspectFit

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

        backgroundColor = scheme?.colorScheme.backgroundColor

        if let button = button {
            addSubview(button)
            button.autoPinEdge(.bottom, to: .bottom, of: imageView, withOffset: -8)
            button.autoPinEdge(.right,  to: .right,  of: imageView, withOffset: -8)
        }
    }
}
