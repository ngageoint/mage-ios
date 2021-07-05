//
//  UserAvatarUIImageView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

@objc class UserAvatarUIImageView: UIImageView {
    
    public var user: User? = nil;
    var url: URL? = nil;
    var largeSizeCached: Bool = false;
    public var placeholderIsRealImage: Bool = false;
    public var useDownloadPlaceholder: Bool = true;
    
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
        return self.user != nil && self.user?.avatarUrl != nil && ImageCache.default.isCached(forKey: (self.user?.avatarUrl!)!);
    }
    
    public func isLargeSizeCached() -> Bool {
        return self.user != nil && self.user?.avatarUrl != nil && ImageCache.default.isCached(forKey: (self.user?.avatarUrl!)!);
    }
    
    public func isThumbnailCached() -> Bool {
        return self.user != nil && self.user?.avatarUrl != nil && ImageCache.default.isCached(forKey: (self.user?.avatarUrl!)!);
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
    
    public func showThumbnail(indicator: Indicator? = nil,
                              progressBlock: DownloadProgressBlock? = nil,
                              completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.setImage(url: self.getAvatarUrl(size: getImageSize()), thumbnail: true, indicator: indicator, progressBlock: progressBlock, completionHandler: completionHandler);
    }
    
    public func setUser(user: User) {
        self.placeholderIsRealImage = false;
        self.user = user;
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
        let url = self.url != nil ? self.url! : self.getAvatarUrl(size: getImageSize());
        self.setImage(url: url, cacheOnly: cacheOnly, fullSize: fullSize, thumbnail: thumbnail, indicator: indicator, progressBlock: progressBlock, completionHandler: completionHandler);
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    
    func getAvatarUrl(size: Int) -> URL? {
        guard let safeUrl = self.user?.avatarUrl else {
            return nil;
        }
        
        let localPath = "\(getDocumentsDirectory())/\(safeUrl)";
        if (FileManager.default.fileExists(atPath: localPath)) {
            return URL(fileURLWithPath: localPath);
        } else {
            return URL(string: String(format: "%@?size=%ld", safeUrl, size))!;
        }
    }
    
    public func setImage(url: URL?,
                         cacheOnly: Bool = false,
                         fullSize: Bool = false,
                         thumbnail: Bool = false,
                         indicator: Indicator? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.contentMode = .scaleAspectFill;
        
        if let safeUrl = url {
        
            if (safeUrl.isFileURL) {
                let provider = LocalFileImageDataProvider(fileURL: safeUrl)
                self.kf.setImage(with: provider)
                return;
            }
            
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
                let resource = ImageResource(downloadURL: safeUrl, cacheKey: safeUrl.absoluteString)
                self.kf.setImage(with: resource, placeholder: placeholder, options: options, progressBlock: progressBlock,
                                 completionHandler: completionHandler);
                return;
            }
            // if they have the original sized image, show that
            else if (self.isFullSizeCached() || fullSize) {
                self.placeholderIsRealImage = true;
                self.kf.setImage(with: safeUrl,
                                 options: options, progressBlock: progressBlock,
                                 completionHandler: completionHandler);
                return;
            }
            // else if they had a large sized image downloaded
            else if (self.isLargeSizeCached()) {
                self.placeholderIsRealImage = true;
                placeholder.kf.setImage(with: self.getAvatarUrl(size: getImageSize()), options: options)
            }
            // if they had the thumbnail already downloaded for some reason, show that while we go get the bigger one
            else if (ImageCache.default.isCached(forKey: safeUrl.absoluteString)) {
                self.placeholderIsRealImage = true;
                placeholder.kf.setImage(with: url, options: options)
            }
            // Have to do this so that the placeholder image shows up behind the activity indicator
            DispatchQueue.main.async {
                self.kf.setImage(with: safeUrl, placeholder: placeholder, options: options, progressBlock: progressBlock, completionHandler: completionHandler);
            }
        } else {
            self.image = UIImage(named: "avatar_small");
        }
    }
}
