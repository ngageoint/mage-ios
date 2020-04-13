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
    var imageSize: Int!
    var largeSizeCached: Bool = false;
    public var placeholderIsRealImage: Bool = false;
    public var useDownloadPlaceholder: Bool = true;
    
    override init(image: UIImage?) {
        super.init(image: image)
        self.imageSize = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageSize = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.imageSize = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
    }
    
    public func isFullSizeCached() -> Bool {
        return ImageCache.default.isCached(forKey: (self.attachment?.url!)!);
    }
    
    public func isLargeSizeCached() -> Bool {
        return self.isFullSizeCached() || ImageCache.default.isCached(forKey: self.getAttachmentUrl(size: self.imageSize).absoluteString);
    }
    
    public func isThumbnailCached() -> Bool {
        return self.attachment != nil && ImageCache.default.isCached(forKey: String(format: "%@_thumbnail", self.attachment!.url!));
    }
    
    public func isAnyCached() -> Bool {
        return isThumbnailCached() || isLargeSizeCached();
    }
    
    public func showThumbnail(indicator: Indicator? = nil,
                              progressBlock: DownloadProgressBlock? = nil,
                              completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        let thumbUrl = URL(string: String(format: "%@_thumbnail", self.attachment!.url!))!;
        self.setImage(url: thumbUrl, thumbnail: true, indicator: indicator, progressBlock: progressBlock, completionHandler: completionHandler);
    }
    
    public func setAttachment(attachment: Attachment) {
        self.placeholderIsRealImage = false;
        self.attachment = attachment;
    }
    
    public func showImage(cacheOnly: Bool = false,
                          fullSize: Bool = false,
                          thumbnail: Bool = false,
                          indicator: Indicator? = nil,
                          progressBlock: DownloadProgressBlock? = nil,
                          completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        let url = self.getAttachmentUrl(size: self.imageSize);
        self.setImage(url: url, cacheOnly: cacheOnly, fullSize: fullSize, thumbnail: thumbnail, indicator: indicator, progressBlock: progressBlock, completionHandler: completionHandler);
    }
    
    func getAttachmentUrl(size: Int) -> URL {
        if (self.attachment?.localPath != nil && FileManager.default.fileExists(atPath: self.attachment!.localPath!)) {
            return URL(fileURLWithPath: (self.attachment?.localPath!)!);
        } else {
            return URL(string: String(format: "%@?size=%ld", self.attachment!.url!, size))!;
        }
    }
    
    func setImage(url: URL,
                  cacheOnly: Bool = false,
                  fullSize: Bool = false,
                  thumbnail: Bool = false,
                  indicator: Indicator? = nil,
                  progressBlock: DownloadProgressBlock? = nil,
                  completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        
        let thumbUrl = URL(string: String(format: "%@_thumbnail", self.attachment!.url!))!;
        
        if (indicator != nil) {
            self.kf.indicatorType = .custom(indicator: indicator!);
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
                
        let placeholder = PlaceholderImage(frame: CGRect(x: 0, y: 0, width: self.frame.size.width/2, height: self.frame.size.height/2));
        placeholder.contentMode = .scaleAspectFit;
        
        if (self.useDownloadPlaceholder) {
            placeholder.image = UIImage.init(named: "big_download");
        }
        
        if (thumbnail) {
            if (self.useDownloadPlaceholder) {
                placeholder.image = UIImage.init(named: "download_thumbnail");
            }
            let resource = ImageResource(downloadURL: url, cacheKey: String(format: "%@_thumbnail", self.attachment!.url!))
            self.kf.setImage(with: resource, placeholder: placeholder, options: options)
        }
        // if they have the original sized image, show that
        else if (self.isFullSizeCached() || fullSize) {
            self.placeholderIsRealImage = true;
            self.kf.setImage(with: URL(string: self.attachment!.url!),
                             options: options, progressBlock: progressBlock,
                                        completionHandler: completionHandler);
            return;
        }
        // else if they had a large sized image downloaded
        else if (self.isLargeSizeCached()) {
            self.placeholderIsRealImage = true;
            placeholder.kf.setImage(with: self.getAttachmentUrl(size: self.imageSize), options: options)
        }
        // if they had the thumbnail already downloaded for some reason, show that while we go get the bigger one
        else if (ImageCache.default.isCached(forKey: thumbUrl.absoluteString)) {
            self.placeholderIsRealImage = true;
            placeholder.kf.setImage(with: thumbUrl, options: options)
        }
        // Have to do this so that the placeholder image shows up behind the activity indicator
        DispatchQueue.main.async {
            self.kf.setImage(with: url, placeholder: placeholder, options: options, progressBlock: progressBlock,
                                        completionHandler: completionHandler);
        }
    }
}
