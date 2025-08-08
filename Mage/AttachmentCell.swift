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

    // MARK: - Path healing for files saved in an older container

//    private func resolveLocalFileURL(from storedPath: String?, fileName: String?) -> URL? {
//        guard var path = storedPath, !path.isEmpty else { return nil }
//        let fm = FileManager.default
//
//        // If path includes ".../Documents/...", rebuild it under THIS install's Documents
//        if let docsRange = path.range(of: "/Documents/"),
//           let currentDocs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
//            let relative = String(path[docsRange.upperBound...]) // e.g. "attachments/MAGE_ABC123"
//            path = currentDocs.appendingPathComponent(relative).path
//        }
//
//        // If the exact file is missing, treat the last component as a prefix and search the directory
//        if !fm.fileExists(atPath: path) {
//            let candidate = URL(fileURLWithPath: path)
//            let dirURL = candidate.deletingLastPathComponent()
//            let prefix = candidate.lastPathComponent
//
//            if let urls = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil),
//               let match = urls.first(where: { $0.lastPathComponent.hasPrefix(prefix) }) {
//                return match
//            }
//
//            // Try “directory + filename” if we were given one
//            if let name = fileName, !name.isEmpty {
//                let alt = dirURL.appendingPathComponent(name)
//                if fm.fileExists(atPath: alt.path) { return alt }
//            }
//        }
//
//        return URL(fileURLWithPath: path)
//    }

    // MARK: - Existing helpers updated to use normalized path

    func getAttachmentUrl(attachment: AttachmentModel) -> URL? {
        if let localPath = attachment.localPath {
            if let healed = resolveLocalFileURL(from: localPath, fileName: attachment.name),
               FileManager.default.fileExists(atPath: healed.path) {
                return healed
            }
        }
        if let url = attachment.url { return URL(string: url) }
        return nil
    }

    func getAttachmentUrl(size: Int, attachment: AttachmentModel) -> URL? {
        if let localPath = attachment.localPath {
            if let healed = resolveLocalFileURL(from: localPath, fileName: attachment.name),
               FileManager.default.fileExists(atPath: healed.path) {
                return healed
            }
        }
        if let url = attachment.url {
            return URL(string: String(format: "%@?size=%ld", url, size))
        }
        return nil
    }

    override func removeFromSuperview() {
        self.imageView.cancel()
    }

    // MARK: - Dictionary-based API
    @objc public func setImage(newAttachment: [String : AnyHashable],
                              button: MDCFloatingButton? = nil,
                              scheme: MDCContainerScheming? = nil) {
        // 🔧 don’t force a layout pass here
        self.button = button
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.kf.indicatorType = .none

        guard let contentType = newAttachment["contentType"] as? String else { return }
        let storedLocalPath = newAttachment["localPath"] as? String
        let fileName       = newAttachment["name"] as? String

        if contentType.hasPrefix("image") {
            let healedURL = resolveLocalFileURL(from: storedLocalPath, fileName: fileName)
            
            if let localURL = healedURL, FileManager.default.fileExists(atPath: localURL.path) {
                self.imageView.setImage(url: localURL,
                                        cacheOnly: !DataConnectionUtilities.shouldFetchAttachments())
                self.imageView.accessibilityLabel = "attachment \(localURL.lastPathComponent) loaded"
            } else if
                let remote = newAttachment["url"] as? String,
                let remoteURL = URL(string: remote) {
                self.imageView.setImage(url: remoteURL,
                                        cacheOnly: false)
                self.imageView.accessibilityLabel = "attachment \(remoteURL.lastPathComponent) loaded"
            } else {
                self.imageView.image = UIImage(systemName: "photo")
                self.imageView.contentMode = .scaleAspectFit
                self.imageView.accessibilityLabel = "image attachment placeholder"
            }

        } else if contentType.hasPrefix("video") {
            // Use normalized local path if we have it (poster frame), otherwise the stored string
//            let healedURL = resolveLocalFileURL(from: storedLocalPath, fileName: fileName)
//            let normalizedLocalPath = healedURL?.path ?? storedLocalPath ?? ""
//            let provider = VideoImageProvider(localPath: normalizedLocalPath)
            let normalizedLocal = resolveLocalFileURL(from: storedLocalPath, fileName: fileName)
            let normalizedLocalPath = normalizedLocal?.path ?? storedLocalPath ?? ""
            let provider = VideoImageProvider(localPath: normalizedLocalPath)

            let overlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            overlay.contentMode = .scaleAspectFit
            self.imageView.addSubview(overlay)
            overlay.autoCenterInSuperview()

            DispatchQueue.main.async {
                self.imageView.kf.setImage(with: provider,
                                           placeholder: UIImage(systemName: "play.circle.fill"),
                                           options: [
                                               .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                                               .transition(.fade(0.2)),
                                               .scaleFactor(UIScreen.main.scale),
                                               .processor(DownsamplingImageProcessor(size: self.imageView.frame.size)),
                                               .diskCacheExpiration(StorageExpiration.seconds(300)),
                                           ])
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
        layoutSubviews()
        self.button = button
        self.imageView.kf.indicatorType = .none
        self.imageView.tintColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.4)

        if (attachment.contentType?.hasPrefix("image") ?? false) {
            self.imageView.setAttachment(attachment: attachment)
            self.imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
            self.imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loading"
            self.imageView.showThumbnail(
                cacheOnly: !DataConnectionUtilities.shouldFetchAttachments(),
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

            // use the correct resolver helper
            let normalizedLocal = resolveLocalFileURL(from: attachment.localPath, fileName: attachment.name)?.path
            let provider = VideoImageProvider(sourceUrl: sourceURL, localPath: normalizedLocal)

            self.imageView.contentMode = .scaleAspectFit
            DispatchQueue.main.async {
                self.imageView.kf.setImage(with: provider,
                                           placeholder: UIImage(systemName: "play.circle.fill"),
                                           options: [
                                               .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                                               .transition(.fade(0.2)),
                                               .scaleFactor(UIScreen.main.scale),
                                               .processor(DownsamplingImageProcessor(size: self.imageView.frame.size)),
                                               .cacheOriginalImage
                                           ]) { result in
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
        }
        else if (attachment.contentType?.hasPrefix("audio") ?? false) {
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
            label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .bottom)
        }

        self.backgroundColor = scheme?.colorScheme.backgroundColor

        if let button = button {
            self.addSubview(button)
            button.autoPinEdge(.bottom, to: .bottom, of: self.imageView, withOffset: -8)
            button.autoPinEdge(.right, to: .right, of: self.imageView, withOffset: -8)
        }
    }
}
