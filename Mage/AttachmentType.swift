//
//  AttachmentType.swift
//  MAGE
//
//  Created by James McDougall on 6/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

enum AttachmentType {
    case image
    case video
    case audio
    case document
    case other
    
    var defaultExtension: String {
        switch self {
        case .image: return "jpeg"
        case .video: return "mp4"
        case .audio: return "m4a"
        case .document: return "pdf"
        default: return "attachments"
        }
    }

    var subdirectory: String {
        switch self {
        case .image: return "images"
        case .video: return "videos"
        case .audio: return "audio"
        case .document: return "documents"
        default: return "attachments"
        }
    }
}
