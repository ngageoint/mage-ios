//
//  Attachment+FileURL.swift
//  MAGE
//
//  Created by Brent Michalski on 8/8/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension Attachment {
    /// Absolute URL for this run, no matter what was stored previously.
    var fileURL: URL? {
        guard let name = self.name, !name.isEmpty else { return nil }

        // If localPath exists, combine it with name; otherwise just use name
        let combined: String
        if let local = self.localPath, !local.isEmpty {
            combined = (local as NSString).appendingPathComponent(name)
        } else {
            combined = name
        }

        // If the stored string was an absolute path from an old container,
        // strip down to the Documents-relative part, then rebuild for THIS run.
        let relative: String
        if let r = combined.range(of: "/Documents/") {
            relative = String(combined[r.upperBound...])     // e.g. "attachments/ABC/file.jpg"
        } else {
            relative = combined                               // already relative, or just the filename
        }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(relative)
    }
}
