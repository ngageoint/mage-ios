//
//  KingfisherHelpers.swift
//  MAGE
//
//  Created by Brent Michalski on 8/12/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Kingfisher
import UIKit

enum KFOptions {
    static func common(for targetSize: CGSize) -> KingfisherOptionsInfo {
        [
            .scaleFactor(UIScreen.main.scale),
            .processor(DownsamplingImageProcessor(size: targetSize)),
            .cacheOriginalImage
        ]
    }
}

extension UIImageView {
    func setImage(attachment: AttachmentModel?,
                  placeholder: UIImage? = nil,
                  completion: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        
        guard let att = attachment else {
            image = placeholder
            return
        }
        
        if let fileURL = att.localFileURL {
            kf.setImage(with: .provider(LocalFileImageDataProvider(fileURL: fileURL)),
                        placeholder: placeholder,
                        options: KFOptions.common(for: bounds.size),
                        completionHandler: completion)
        } else if let remote = att.remoteURL {
            kf.setImage(with: remote,
                        placeholder: placeholder,
                        options: KFOptions.common(for: bounds.size),
                        completionHandler: completion)
        } else {
            image = placeholder
        }
    }
}
