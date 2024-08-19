//
//  DownloadingImageViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

class DownloadingImageViewModel: ObservableObject {
    @Published
    var error: String?
    
    @Published
    var fileUrl: URL?
    
    @Published
    var fileDate: Date = Date()
    
    @Published
    var receivedSize: Int64 = 0
    
    @Published
    var totalSize: Int64 = 0
    
    var imageUrl: URL
    var router: MageRouter
    
    init(imageUrl: URL, router: MageRouter) {
        self.imageUrl = imageUrl
        self.router = router
        
        KingfisherManager.shared.retrieveImage(
            with: imageUrl,
            options: [
                .forceRefresh,
                .cacheOriginalImage,
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
            ],
            progressBlock: { receivedSize, totalSize in
                DispatchQueue.main.async { [weak self] in
                    self?.receivedSize = receivedSize
                    self?.totalSize = totalSize
                }
            }
        ) { result in
            switch result {
            case .success(_):
                router.path.append(FileRoute.showCachedImage(cacheKey: imageUrl.absoluteString))
            case .failure(let error):
                self.error = error.localizedDescription
            }
        }
    }
}
