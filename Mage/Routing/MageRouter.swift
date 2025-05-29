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
    
    @Published
    var bottomSheetRoute: BottomSheetRoute?
    
    func appendRoute(_ route: Any) {
        if let bottomSheetRoute = route as? BottomSheetRoute {
            self.bottomSheetRoute = bottomSheetRoute
        } else {
            path.append(route)
        }
    }
}

enum MageRoute: Hashable {
    case observationFilter
    case locationFilter
}

enum BottomSheetRoute: Hashable {
    case observationMoreActions(observationUri: URL?)
    case userAvatarActions(userUri: URL?)
}

enum ObservationRoute: Hashable {
    case detail(uri: URL?)
    case create
    case edit(uri: URL?)
}

enum UserRoute: Hashable {
    case detail(uri: URL?)
    case userFromLocation(locationUri: URL?)
    case showFavoritedUsers(remoteIds: [String])
}

enum FileRoute: Hashable {
    case showCachedImage(cacheKey: String?)
    case showFileImage(filePath: String)
    case cacheImage(url: URL)
    case askToCache(url: URL)
    
    case showLocalVideo(filePath: String)
    case showRemoteVideo(url: URL)
    
    case showLocalAudio(filePath: String)
    case showRemoteAudio(url: URL)
    
    case askToDownload(url: URL)
    case downloadFile(url: URL)
    case showDownloadedFile(fileUrl: URL, url: URL)
}
