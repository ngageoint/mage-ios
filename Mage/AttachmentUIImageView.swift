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
        return self.attachment != nil && self.attachment?.url != nil && ImageCache.default.isCached(forKey: (self.attachment?.url!)!);
    }
    
    public func isLargeSizeCached() -> Bool {
        return self.attachment != nil && (self.isFullSizeCached() || (self.getAttachmentUrl(size: getImageSize()) != nil && ImageCache.default.isCached(forKey: self.getAttachmentUrl(size: getImageSize())!.absoluteString)));
    }
    
    public func isThumbnailCached() -> Bool {
        return self.attachment != nil && self.attachment?.url != nil && ImageCache.default.isCached(forKey: String(format: "%@_thumbnail", self.attachment!.url!));
    }
    
    public func isAnyCached() -> Bool {
        return isThumbnailCached() || isLargeSizeCached();
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
                          thumbnail: Bool = false,
                          indicator: Indicator? = nil,
                          progressBlock: DownloadProgressBlock? = nil,
                          completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        let url = self.url != nil ? self.url! : self.getAttachmentUrl(size: getImageSize());
        self.setImage(url: url, cacheOnly: cacheOnly, fullSize: fullSize, thumbnail: thumbnail, indicator: indicator, progressBlock: progressBlock, completionHandler: completionHandler);
    }
    
    func getAttachmentUrl(size: Int) -> URL? {
        if (self.attachment?.localPath != nil && FileManager.default.fileExists(atPath: self.attachment!.localPath!)) {
            return URL(fileURLWithPath: (self.attachment?.localPath!)!);
        } else if (self.attachment?.url != nil) {
            return URL(string: String(format: "%@?size=%ld", self.attachment!.url!, size))!;
        }
        return nil;
    }
    
    public func setImage(url: URL?,
                  cacheOnly: Bool = false,
                  fullSize: Bool = false,
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
        
        guard let safeUrl = url else {
            return;
        }
        
        if (safeUrl.isFileURL) {
            let provider = LocalFileImageDataProvider(fileURL: safeUrl)
            self.kf.setImage(with: provider)
            return;
        }
        
        var thumbUrl = safeUrl;
        if (self.attachment?.url != nil) {
            thumbUrl = URL(string: String(format: "%@_thumbnail", self.attachment!.url!))!
        }
        
        if (indicator != nil) {
            self.kf.indicatorType = .custom(indicator: indicator!);
        } else {
            self.kf.indicatorType = .activity;
        }
        var options: KingfisherOptionsInfo = [
            .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
            .transition(.fade(0.3)),
            .scaleFactor(UIScreen.main.scale),
            .processor(DownsamplingImageProcessor(size: self.frame.size)),
            .cacheOriginalImage]
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
        
        if (thumbnail) {
            // Have to do this so that the placeholder image shows up behind the activity indicator
            DispatchQueue.main.async {
                let resource = ImageResource(downloadURL: safeUrl, cacheKey: thumbUrl.absoluteString)
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
            return;
        }
        // if they have the original sized image, show that
        else if (self.isFullSizeCached() || fullSize) {
            self.placeholderIsRealImage = true;
            self.kf.setImage(with: URL(string: self.attachment!.url!),
                             options: options, progressBlock: progressBlock) { result in
                
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
            return;
        }
        // else if they had a large sized image downloaded
        else if (self.isLargeSizeCached()) {
            self.placeholderIsRealImage = true;
            placeholder.kf.setImage(with: self.getAttachmentUrl(size: getImageSize()), options: options) { result in
                
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
        DispatchQueue.main.async {
            self.kf.setImage(with: safeUrl, placeholder: placeholder, options: options, progressBlock: progressBlock) { result in
                
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
