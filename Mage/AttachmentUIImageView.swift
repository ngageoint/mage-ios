//
//  AttachmentUIImageView.swift
//  MAGE
//
//  Created by Daniel Barela on 3/30/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

@objc class AttachmentUIImageView: UIImageView {

    public var attachment: AttachmentModel? = nil
    var url: URL? = nil
    public var placeholderIsRealImage: Bool = false
    public var useDownloadPlaceholder: Bool = true
    private(set) var loaded: Bool = false
    private(set) var loadedThumb: Bool = false

    // Keep a healed local URL produced by AttachmentPath (single source of truth)
    private var healedLocalURL: URL?

    // MARK: - Small helpers (new)

    private var remoteURL: URL? {
        attachment?.url.flatMap(URL.init(string:))
    }
    private var thumbCacheKey: String? {
        attachment?.url.map { "\($0)_thumbnail" }
    }
    private var largeCacheKey: String? {
        attachment?.url.map { "\($0)_large" }
    }

    private func kfOptions(cacheOnly: Bool, targetSize: CGSize) -> KingfisherOptionsInfo {
        var opts: KingfisherOptionsInfo = [
            .scaleFactor(UIScreen.main.scale),
            .cacheOriginalImage
        ]
        if targetSize != .zero {
            opts.append(.processor(DownsamplingImageProcessor(size: targetSize)))
        }
        // Only apply auth/request modifier for network requests
        opts.append(.requestModifier(ImageCacheProvider.shared.accessTokenModifier))
        if cacheOnly { opts.append(.onlyFromCache) }
        return opts
    }

    private func makePlaceholder(thumbnail: Bool) -> PlaceholderImage {
        let ph = PlaceholderImage()
        ph.contentMode = .scaleAspectFit
        if useDownloadPlaceholder && thumbnail {
            ph.image = UIImage(named: "download_thumbnail")
        } else if useDownloadPlaceholder {
            ph.image = UIImage(named: "big_download")
            ph.tintColor = .lightGray
        }
        return ph
    }

    private func source(for url: URL) -> Source {
        url.isFileURL
        ? .provider(LocalFileImageDataProvider(fileURL: url))
        : .network(url)
    }

    private func imageResource(downloadURL: URL, cacheKey: String?) -> KF.ImageResource {
        KF.ImageResource(downloadURL: downloadURL, cacheKey: cacheKey)
    }

    // MARK: - Lifecycle

    override init(image: UIImage?) { super.init(image: image) }
    override init(frame: CGRect) { super.init(frame: frame) }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

    // MARK: - Cache Queries

    public func isFullSizeCached() -> Bool {
        guard let key = attachment?.url else { return false }
        return ImageCache.default.isCached(forKey: key)
    }

    public func isLargeSizeCached() -> Bool {
        guard let key = attachment?.url else { return false }
        return ImageCache.default.isCached(forKey: "\(key)_large") || isFullSizeCached()
    }

    public func isThumbnailCached() -> Bool {
        guard let key = attachment?.url else { return false }
        return ImageCache.default.isCached(forKey: "\(key)_thumbnail")
    }

    public func isAnyCached() -> Bool {
        isThumbnailCached() || isLargeSizeCached() || isFullSizeCached()
    }

    func getImageSize() -> Int {
        Int(max(bounds.size.height, bounds.size.width) * UIScreen.main.scale)
    }

    public func cancel() {
        kf.cancelDownloadTask()
    }

    // MARK: - API

    public func showThumbnail(
        cacheOnly: Bool,
        indicator: Indicator? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: @escaping (Result<RetrieveImageResult, KingfisherError>) -> Void
    ) {
        // Prefer healed local URL if it exists
        if let localURL = healedLocalURL {
            kf.setImage(
                with: source(for: localURL),
                options: kfOptions(cacheOnly: cacheOnly, targetSize: bounds.size),
                completionHandler: completionHandler
            )
            return
        }

        // Fallback: remote URL
        if let remote = remoteURL {
            kf.setImage(
                with: source(for: remote),
                options: kfOptions(cacheOnly: cacheOnly, targetSize: bounds.size) + [.transition(.fade(0.2))],
                completionHandler: completionHandler
            )
            return
        }

        // Final fallback: placeholder
        image = UIImage(named: "placeholder")
        completionHandler(.failure(.requestError(reason: .emptyRequest)))
    }

    public func setAttachment(attachment: AttachmentModel) {
        placeholderIsRealImage = false
        self.attachment = attachment
        // Use centralized path healer
        healedLocalURL = AttachmentPath.localURL(fromStored: attachment.localPath,
                                                 fileName: attachment.name)
    }

    public func setURL(url: URL?) {
        placeholderIsRealImage = false
        self.url = url
    }

    public func showImage(
        cacheOnly: Bool = false,
        fullSize: Bool = false,
        largeSize: Bool = false,
        thumbnail: Bool = false,
        indicator: Indicator? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) {
        let url = self.url ?? getAttachmentUrl(size: getImageSize())
        setImage(url: url,
                 cacheOnly: cacheOnly,
                 fullSize: fullSize,
                 largeSize: largeSize,
                 thumbnail: thumbnail,
                 indicator: indicator,
                 progressBlock: progressBlock,
                 completionHandler: completionHandler)
    }

    // Prefer healed URL via AttachmentPath; no raw fileExists on stored strings
    func getAttachmentUrl(size: Int) -> URL? {
        if let localURL = AttachmentPath.localURL(fromStored: attachment?.localPath, fileName: attachment?.name) {
            return localURL
        }
        
        guard let raw = attachment?.url, let base = URL(string: raw) else { return nil }
        var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)
        var items = comps?.queryItems ?? []
        items.append(URLQueryItem(name: "size", value: "\(size)"))
        comps?.queryItems = items
        return comps?.url
    }

    public func setImage(
        url: URL?,
        cacheOnly: Bool = false,
        fullSize: Bool = false,
        largeSize: Bool = false,
        thumbnail: Bool = false,
        indicator: Indicator? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) {
        // Nil URL → show upload icon
        guard let url = url else {
            contentMode = .scaleAspectFit
            image = UIImage(named: "upload")
            return
        }

        clipsToBounds = true
        contentMode = .scaleAspectFill

        // Local file: single path
        if url.isFileURL {
            kf.setImage(with: source(for: url), completionHandler: completionHandler)
            return
        }

        // Remote flow
        let targetSize = frame.size
        var options = kfOptions(cacheOnly: cacheOnly, targetSize: targetSize) + [.transition(.fade(0.3))]

        let placeholder = makePlaceholder(thumbnail: thumbnail)
        let fullRemote = remoteURL // may be nil if attachment missing URL
        let thumbKey = thumbCacheKey
        let largeKey = largeCacheKey

        // if they have the original sized image, show that no matter what size they really need
        if isFullSizeCached() || fullSize, let fullRemote {
            placeholderIsRealImage = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.kf.setImage(with: self.source(for: fullRemote),
                                 placeholder: placeholder,
                                 options: options,
                                 progressBlock: progressBlock) { result in
                    switch result {
                    case .failure(let error):
                        if case KingfisherError.cacheError(reason: .imageNotExisting(let key)) = error {
                            MageLogger.misc.debug("cache miss \(key)")
                        }
                    case .success:
                        if thumbnail { self.loadedThumb = true }
                        self.loaded = true
                    }
                    completionHandler?(result)
                }
            }
            return
        }

        // Thumbnail path
        if thumbnail {
            if isLargeSizeCached() || largeSize {
                let key = largeKey ?? url.absoluteString
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    let downloadURL = self.getAttachmentUrl(size: self.getImageSize()) ?? url
                    let res = self.imageResource(downloadURL: downloadURL, cacheKey: key)
                    self.kf.setImage(with: res, placeholder: placeholder, options: options, progressBlock: progressBlock) { result in
                        if case .failure(let error) = result,
                           case KingfisherError.cacheError(reason: .imageNotExisting(let k)) = error {
                            MageLogger.misc.debug("cache miss \(k)")
                        } else if case .success = result {
                            self.loadedThumb = true
                        }
                        completionHandler?(result)
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    let downloadURL = self.getAttachmentUrl(size: self.getImageSize()) ?? url
                    let res = self.imageResource(downloadURL: downloadURL, cacheKey: thumbKey ?? url.absoluteString)
                    self.kf.setImage(with: res, placeholder: placeholder, options: options, progressBlock: progressBlock) { result in
                        if case .failure(let error) = result,
                           case KingfisherError.cacheError(reason: .imageNotExisting(let k)) = error {
                            MageLogger.misc.debug("cache miss \(k)")
                        } else if case .success = result {
                            self.loadedThumb = true
                        }
                        completionHandler?(result)
                    }
                }
            }
            return
        }

        // Large path (not thumbnail)
        if isLargeSizeCached() || largeSize {
            placeholderIsRealImage = true
            let key = largeKey ?? url.absoluteString
            let downloadURL = getAttachmentUrl(size: getImageSize()) ?? url
            let res = imageResource(downloadURL: downloadURL, cacheKey: key)

            placeholder.kf.setImage(with: res, options: options) { result in
                if case .failure(let error) = result,
                   case KingfisherError.cacheError(reason: .imageNotExisting(let k)) = error {
                    MageLogger.misc.debug("cache miss \(k)")
                } else if case .success = result {
                    self.loadedThumb = true
                }
                completionHandler?(result)
            }
            return
        }

        // Final remote fetch
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.kf.setImage(with: self.source(for: url),
                             placeholder: placeholder,
                             options: options,
                             progressBlock: progressBlock) { result in
                if case .failure(let error) = result,
                   case KingfisherError.cacheError(reason: .imageNotExisting(let k)) = error {
                    MageLogger.misc.debug("cache miss \(k)")
                } else if case .success = result {
                    self.loaded = true
                }
                completionHandler?(result)
            }
        }
    }
}
