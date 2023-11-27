//
//  AttachmentUIImage.swift
//  MAGE
//
//  Created by Daniel Barela on 3/30/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

@objc class AttachmentUIImageView: UIImageView {

    public var attachment: Attachment? = nil;
    var url: URL? = nil;
    var largeSizeCached: Bool = false;
    public var placeholderIsRealImage: Bool = false;
    public var useDownloadPlaceholder: Bool = true;
    public var loaded: Bool = false;
    public var loadedThumb: Bool = false;
    
    override init(image: UIImage?) {
        super.init(image: image)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func isFullSizeCached() -> Bool {
        if let attachmentUrl = self.attachment?.url {
            return ImageCache.default.isCached(forKey: attachmentUrl)
        }
        return false
    }
    
    public func isLargeSizeCached() -> Bool {
        if let attachmentUrl = self.attachment?.url {
            return ImageCache.default.isCached(forKey: String(format: "%@_large", attachmentUrl)) || isFullSizeCached()
        }
        return false
    }
    
    public func isThumbnailCached() -> Bool {
        if let attachmentUrl = self.attachment?.url {
            return ImageCache.default.isCached(forKey: String(format: "%@_thumbnail", attachmentUrl))
        }
        return false
    }
    
    public func isAnyCached() -> Bool {
        return isThumbnailCached() || isLargeSizeCached() || isFullSizeCached();
    }
    
    func getImageSize() -> Int {
        return Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale)
    }
    
    public func cancel() {
        self.kf.cancelDownloadTask();
    }
    
    public func showThumbnail(cacheOnly: Bool = false,
                              indicator: Indicator? = nil,
                              progressBlock: DownloadProgressBlock? = nil,
                              completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.setImage(url: self.getAttachmentUrl(size: getImageSize()), cacheOnly: cacheOnly, thumbnail: true, indicator: indicator, progressBlock: progressBlock, completionHandler: completionHandler);
    }
    
    public func setAttachment(attachment: Attachment) {
        self.placeholderIsRealImage = false;
        self.attachment = attachment;
    }
    
    public func setURL(url: URL?) {
        self.placeholderIsRealImage = false;
        self.url = url;
    }
        
    public func showImage(cacheOnly: Bool = false,
                          fullSize: Bool = false,
                          largeSize: Bool = false,
                          thumbnail: Bool = false,
                          indicator: Indicator? = nil,
                          progressBlock: DownloadProgressBlock? = nil,
                          completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        let url = self.url ?? self.getAttachmentUrl(size: getImageSize());
        self.setImage(url: url, cacheOnly: cacheOnly, fullSize: fullSize, largeSize: largeSize, thumbnail: thumbnail, indicator: indicator, progressBlock: progressBlock, completionHandler: completionHandler);
    }
    
    func getAttachmentUrl(size: Int) -> URL? {
        if let localPath = self.attachment?.localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath);
        } else if let attachmentUrl = self.attachment?.url {
            return URL(string: String(format: "%@?size=%ld", attachmentUrl, size));
        }
        return nil;
    }
    
    public func setImage(url: URL?,
                  cacheOnly: Bool = false,
                  fullSize: Bool = false,
                  largeSize: Bool = false,
                  thumbnail: Bool = false,
                  indicator: Indicator? = nil,
                  progressBlock: DownloadProgressBlock? = nil,
                  completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        // this is the case where the attachment was saved by another user, but not uploaded to the server yet
        if (url == nil) {
            self.contentMode = .scaleAspectFit;
            self.image = UIImage(named: "upload");
            return;
        }
        
        self.contentMode = .scaleAspectFill;
        
        guard let url = url else {
            return;
        }
        
        if (url.isFileURL) {
            let provider = LocalFileImageDataProvider(fileURL: url)
            self.kf.setImage(with: provider, completionHandler: completionHandler)
            return;
        }
        
        var thumbUrl = url;
        if let attachmentUrl = self.attachment?.url {
            thumbUrl = URL(string: String(format: "%@_thumbnail", attachmentUrl)) ?? url
        }
        
//        if let indicator = indicator {
//            self.kf.indicatorType = .custom(indicator: indicator);
//        } else {
//            self.kf.indicatorType = .activity;
//        }
        var options: KingfisherOptionsInfo = [
            .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
            .transition(.fade(0.3)),
            .scaleFactor(UIScreen.main.scale),
            .cacheOriginalImage]
        if self.frame.size != .zero {
            options.append(.processor(DownsamplingImageProcessor(size: self.frame.size)))
        }
        if (cacheOnly) {
            options.append(.onlyFromCache);
        }
                
        let placeholder = PlaceholderImage();
        placeholder.contentMode = .scaleAspectFit;
        
        self.clipsToBounds = true;
        
        if (self.useDownloadPlaceholder && thumbnail) {
            placeholder.image = UIImage.init(named: "download_thumbnail");
        } else if (self.useDownloadPlaceholder) {
            placeholder.image = UIImage.init(named: "big_download");
            placeholder.tintColor = .lightGray;
        }
        
        // if they have the original sized image, show that no matter what size they really need
        if (self.isFullSizeCached() || fullSize) {
            self.placeholderIsRealImage = true;
            DispatchQueue.main.async {
                self.kf.setImage(with: URL(string: self.attachment?.url ?? ""), placeholder: placeholder,
                                 options: options, progressBlock: progressBlock) { result in
                    
                    switch result {
                    case .failure(let error):
                        if case KingfisherError.cacheError(reason: .imageNotExisting(let key)) = error {
                            print("cache miss \(key)")
                        }
                    case .success(_):
                        if (thumbnail) {
                            self.loadedThumb = true;
                        }
                        self.loaded = true;
                        break;
                    }
                    completionHandler?(result);
                };
            }
            return;
        }
        else if (thumbnail) {
            if (self.isLargeSizeCached() || largeSize) {
                var largeUrl = url;
                if let attachmentUrl = self.attachment?.url {
                    largeUrl = URL(string: String(format: "%@_large", attachmentUrl)) ?? url
                }
                DispatchQueue.main.async {
                    let resource = KF.ImageResource(downloadURL: self.getAttachmentUrl(size: self.getImageSize())!, cacheKey: largeUrl.absoluteString)
                    self.kf.setImage(with: resource, placeholder: placeholder, options: options, progressBlock: progressBlock) { result in
                        
                        switch result {
                        case .failure(let error):
                            if case KingfisherError.cacheError(reason: .imageNotExisting(let key)) = error {
                                print("cache miss \(key)")
                            }
                        case .success(_):
                            self.loadedThumb = true;
                            break;
                        }
                        completionHandler?(result);
                    };
                }
            } else {
                // Have to do this so that the placeholder image shows up behind the activity indicator
                DispatchQueue.main.async {
                    let resource = KF.ImageResource(downloadURL: self.getAttachmentUrl(size: self.getImageSize())!, cacheKey: thumbUrl.absoluteString)
                    self.kf.setImage(with: resource, placeholder: placeholder, options: options, progressBlock: progressBlock) { result in
                        
                        switch result {
                        case .failure(let error):
                            if case KingfisherError.cacheError(reason: .imageNotExisting(let key)) = error {
                                print("cache miss \(key)")
                            }
                        case .success(_):
                            self.loadedThumb = true;
                            break;
                        }
                        completionHandler?(result);
                    };
                }
            }
            return;
        }

        // else if they had a large sized image downloaded
        else if (self.isLargeSizeCached() || largeSize) {
            self.placeholderIsRealImage = true;
            var largeUrl = url;
            if let attachmentUrl = self.attachment?.url {
                largeUrl = URL(string: String(format: "%@_large", attachmentUrl)) ?? url
            }
            let resource = KF.ImageResource(downloadURL: self.getAttachmentUrl(size: getImageSize())!, cacheKey: largeUrl.absoluteString)

            placeholder.kf.setImage(with: resource, options: options) { result in
                
                switch result {
                case .failure(let error):
                    if case KingfisherError.cacheError(reason: .imageNotExisting(let key)) = error {
                        print("cache miss \(key)")
                    }
                case .success(_):
                    self.loadedThumb = true;
                    break;
                }
                completionHandler?(result);
            };
        }
        // if they had the thumbnail already downloaded for some reason, show that while we go get the bigger one
        else if (ImageCache.default.isCached(forKey: thumbUrl.absoluteString)) {
            self.placeholderIsRealImage = true;
            placeholder.kf.setImage(with: thumbUrl, options: options) { result in
                
                switch result {
                case .failure(let error):
                    if case KingfisherError.cacheError(reason: .imageNotExisting(let key)) = error {
                        print("cache miss \(key)")
                    }
                case .success(_):
                    self.loadedThumb = true;
                    break;
                }
                completionHandler?(result);
            };
        }
        // Have to do this so that the placeholder image shows up behind the activity indicator
        // if the user has their settings such that they do not want to download images automatically
        // the placeholder will be shown and this will just fail which is fine
        DispatchQueue.main.async {
            self.kf.setImage(with: url, placeholder: placeholder, options: options, progressBlock: progressBlock) { result in
                
                switch result {
                case .failure(let error):
                    if case KingfisherError.cacheError(reason: .imageNotExisting(let key)) = error {
                        print("cache miss \(key)")
                    }
                case .success(_):
                    self.loaded = true;
                    break;
                }
                completionHandler?(result);
            };
        }
    }
}
