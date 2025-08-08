//
//  RelativePaths.swift
//  MAGE
//
//  Created by Brent Michalski on 8/8/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum PathResolver {
    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    static func makeRelativeToDocuments(_ absolute: URL) -> String {
        let path = absolute.standardizedFileURL.path
        let base = documentsURL.standardizedFileURL.path
        if path.hasPrefix(base) {
            let cut = base.hasSuffix("/") ? base.count : base.count + 1
            return String(path.dropFirst(cut))
        }
        return absolute.lastPathComponent
    }
    static func resolveFromDocuments(_ relative: String) -> URL {
        documentsURL.appendingPathComponent(relative)
    }
    static func stripToDocumentsRelative(_ rawPath: String) -> String {
        if let r = rawPath.range(of: "/Documents/") {
            return String(rawPath[r.upperBound...]) // e.g. "attachments/..../file.jpg"
        }
        return rawPath
    }
}
