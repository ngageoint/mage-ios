//
//  String+ContentTypes.swift
//  MAGE
//
//  Created by Brent Michalski on 8/12/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension String {
    var isImageContentType: Bool { lowercased().hasPrefix("image/") || lowercased() == "image" }
    var isVideoContentType: Bool { lowercased().hasPrefix("video/") || lowercased() == "video" }
    var isAudioContentType: Bool { lowercased().hasPrefix("audio/") || lowercased() == "audio" }
}
