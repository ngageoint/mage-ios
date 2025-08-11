// AttachmentPathHealer.swift
// Put this somewhere both UIKit and SwiftUI files can import (e.g., in the app target).

import Foundation

/// Rewrites a stored local path (possibly from an old app container) to this run's container.
/// If `storedPath` points to a directory, `fileName` will be appended.
/// If the exact file is missing, we'll prefix-scan the directory for a match.
public func resolveLocalFileURL(from storedPath: String?, fileName: String?) -> URL? {
    guard var path = storedPath, !path.isEmpty else { return nil }
    let fm = FileManager.default

    // If path includes ".../Documents/...", rebuild it under THIS install's Documents
    if let docsRange = path.range(of: "/Documents/"),
       let currentDocs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
        let relative = String(path[docsRange.upperBound...]) // e.g. "attachments/MAGE_ABC123"
        path = currentDocs.appendingPathComponent(relative).path
    }

    var url = URL(fileURLWithPath: path)

    // If it's a directory and we have a fileName, append it
    var isDir: ObjCBool = false
    if fm.fileExists(atPath: url.path, isDirectory: &isDir),
       isDir.boolValue,
       let name = fileName, !name.isEmpty {
        url = url.appendingPathComponent(name)
    }

    // If that exists, great
    if fm.fileExists(atPath: url.path) {
        return url
    }

    // Otherwise, treat last component as a *prefix* and scan the directory
    let dir = url.deletingLastPathComponent()
    let prefix = url.lastPathComponent
    if let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
       let match = contents.first(where: { $0.lastPathComponent.hasPrefix(prefix) }) {
        return match
    }

    // As a final try: directory + fileName (in case the stored fileName differs)
    if let name = fileName, !name.isEmpty {
        let alt = dir.appendingPathComponent(name)
        if fm.fileExists(atPath: alt.path) { return alt }
    }

    return nil
}

public extension AttachmentModel {
    /// Best-effort healed local file URL (if the asset exists on this device).
    var healedLocalURL: URL? {
        resolveLocalFileURL(from: self.localPath, fileName: self.name)
    }

    /// Remote API URL as provided by the model (`attachment.url`).
    /// (We use what's already on the model instead of rebuilding from IDs.)
    var remoteAPIURL: URL? {
        guard let s = self.url else { return nil }
        return URL(string: s)
    }

    /// Remote API URL with a `size` query param (if you want server-sized thumbnails).
    func remoteAPIURL(size: Int) -> URL? {
        guard let s = self.url, var comps = URLComponents(string: s) else { return nil }
        var items = comps.queryItems ?? []
        items.append(URLQueryItem(name: "size", value: String(size)))
        comps.queryItems = items
        return comps.url
    }

    /// Choose the best URL to display: prefer healed local, otherwise remote.
    /// For images you can pass a preferred thumbnail size; for videos ignore size.
    func bestDisplayURL(preferredThumbSize: Int? = nil) -> URL? {
        if let local = healedLocalURL, FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        if let size = preferredThumbSize, contentType?.hasPrefix("image") == true {
            return remoteAPIURL(size: size) ?? remoteAPIURL
        }
        return remoteAPIURL
    }
}
