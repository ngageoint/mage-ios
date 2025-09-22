//
//  AttachmentPath.swift
//  MAGE
//
//  Consolidated path helpers for reading/writing attachment file paths.
//
//  Created by Brent Michalski on 8/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum AttachmentPath {
    /// Documents folder for the current container.
    private static var documentsURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            preconditionFailure("Documents directory not found.")
        }
        return url.standardizedFileURL
    }
    
    /// Convert an absolute URL to a Documents-relative string when possible
    static func makeRelativeToDocuments(_ absolute: URL) -> String {
        let path = absolute.standardizedFileURL.path
        let base = documentsURL.path
        
        if path.hasPrefix(base) {
            let cut = base.hasSuffix("/") ? base.count : base.count + 1
            return String(path.dropFirst(cut))
        }
        
        return absolute.lastPathComponent  // Fall back to filename
    }
    
    /// If the string contains ".../Documents/...", strip up to that and return the suffix.
    static func stripToDocumentsRelative(_ rawPath: String) -> String {
        if let r = rawPath.range(of: "/Documents/") {
            return String(rawPath[r.upperBound...])
        }
        return rawPath
    }
    
    /// Resolve a Documents-relative string back to an absolute URL.
    static func resolveFromDocuments(_ relative: String) -> URL {
        documentsURL.appendingPathComponent(relative)
    }
    
    /// Heals a previously stored path (possibly absolute in another container, or a directory prefix).
    /// - Parameters:
    ///   - storedPath: previously stored path string (may be absolute or relative, or a directory)
    ///   - fileName: filename we expect inside the directory/prefix
    /// - Returns: best-guess absolute file URL if it exists
    static func localURL(fromStored storedPath: String?, fileName: String?) -> URL? {
        guard var raw = storedPath, !raw.isEmpty else { return nil }
        let fm = FileManager.default
        
        // If it contains "/Documents/", rebuild under THIS install's Documents
        if let docsRange = raw.range(of: "/Documents/") {
            let relative = String(raw[docsRange.upperBound...])
            raw = documentsURL.appendingPathComponent(relative).path
        }
        
        var url = URL(fileURLWithPath: raw)
        
        // If exact file exists, done
        if fm.fileExists(atPath: url.path) {
            return url
        }
        
        // If looks like a directory or a prefix, try to match by prefix in that directory
        let dir = url.deletingLastPathComponent()
        let prefix = url.lastPathComponent
        if let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
           let match = contents.first(where: { $0.lastPathComponent.hasPrefix(prefix) }),
           fm.fileExists(atPath: match.path) {
            return match
        }
        
        // Final attempt: use directory + expected fileName
        if let name = fileName, !name.isEmpty {
            let candidate = dir.appendingPathComponent(name)
            if fm.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        
        return nil
    }
}
