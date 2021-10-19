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
    
    public func cancel() {
        self.kf.cancelDownloadTask();
    }
    
    public func setUser(user: User) {
        self.user = user;
    }
    
    public func setURL(url: URL?) {
        self.url = url;
    }
    
    public func showImage(cacheOnly: Bool = false,
                          indicator: Indicator? = nil,
                          progressBlock: DownloadProgressBlock? = nil,
                          completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        let url = self.url != nil ? self.url! : self.getAvatarUrl();
        self.setImage(url: url, cacheOnly: cacheOnly, indicator: indicator, progressBlock: progressBlock, completionHandler: completionHandler);
    }

    func getAvatarUrl() -> URL? {
        guard let user = self.user, let avatarUrl = self.user?.avatarUrl else {
            return nil;
        }
        
        let lastUpdated = String(format:"%.0f", (user.lastUpdated?.timeIntervalSince1970.rounded() ?? 0))
        return URL(string: "\(avatarUrl)?_lastUpdated=\(lastUpdated)");
    }
    
    public func setImage(url: URL?,
                         cacheOnly: Bool = false,
                         indicator: Indicator? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.contentMode = .scaleAspectFill;
        
        if let url = url {
        
            if (url.isFileURL) {
                let provider = LocalFileImageDataProvider(fileURL: url)
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
                .cacheOriginalImage]
            if (self.frame.size.height != 0) {
                options.append(.processor(DownsamplingImageProcessor(size: self.frame.size)))
            }
            if (cacheOnly) {
                options.append(.onlyFromCache);
            }
            
            let placeholder = PlaceholderImage();
            placeholder.contentMode = .scaleAspectFit;
            
            self.clipsToBounds = true;
            
            if (self.useDownloadPlaceholder) {
                placeholder.image = UIImage.init(named: "portrait");
            }
            
            // Have to do this so that the placeholder image shows up behind the activity indicator
            DispatchQueue.main.async {
                self.kf.setImage(with: url, placeholder: placeholder, options: options, progressBlock: progressBlock, completionHandler: completionHandler);
            }
        } else {
            self.image = UIImage(named: "portrait")
        }
    }
}
