//
//  ImageCacheProvider.m
//  MAGE
//
//  Created by Daniel Barela on 2/21/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Kingfisher

@objc class ImageCacheProvider: NSObject {
    
    @objc public static let shared = ImageCacheProvider()
    public var accessTokenModifier: AnyModifier!
    
    private override init() {
        super.init()
        
        self.accessTokenModifier = AnyModifier { request in
            var r = request
            r.setValue(String(format: "Bearer %@", StoredPassword.retrieveStoredToken()), forHTTPHeaderField: "Authorization")
            return r
        }
    }
    
    @objc public func isCached(url: URL) -> Bool {
        return ImageCache.default.isCached(forKey: url.absoluteString)
    }
    
    @objc public func setImageViewUrl(imageView: UIImageView, url: URL) {
        imageView.kf.setImage(with: url)
    }
}
