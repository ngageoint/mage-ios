//
//  AttachmentRepository+Env.swift
//  MAGE
//
//  Created by Brent Michalski on 8/12/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

/// Dependency points the repo uses, so tests can override deterministically.
enum AttachmentRepoEnv {
    /// Whether downloads are allowed by policy (Wi-Fi only, etc.)
    static var fetchPolicy: () -> Bool = { DataConnectionUtilities.shouldFetchAttachments() }

    /// Whether a key is cached in Kingfisher.
    static var isCached: (String) -> Bool = { ImageCache.default.isCached(forKey: $0) }
    
    // NEW — off by default (keeps current behavior)
    static var preferStreamingVideo: () -> Bool = { false }
    static var preferStreamingAudio: () -> Bool = { false }
}
