//
//  MageRouter.swift
//  MAGE
//
//  Created by Dan Barela on 8/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class MageRouter: ObservableObject {
    @Published
    var path: [Any] = []
}

enum ObservationRoute: Hashable {
    case detail(uri: URL?)
    case create
    case edit(uri: URL?)
}

enum FileRoute: Hashable {
    case showCachedImage(cacheKey: String?)
    case showFileImage(filePath: String)
    case cacheImage(url: URL)
    case askToCache(url: URL)
}

enum AttachmentRoute: Hashable {
    case askToDownload(attachmentUri: URL?)
    case showVideo(attachmentUri: URL?)
    case showAudio(attachmentUri: URL?)
    case showFilePreview(attachmentUri: URL?)
}
