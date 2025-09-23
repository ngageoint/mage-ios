//
//  ObservationImageRepository.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol ObservationImageRepository {
    func clearCache()
    func imageName(
        eventId: Int64?,
        formId: Int?,
        primaryFieldText: String?,
        secondaryFieldText: String?
    ) -> String?
    func imageName(observation: Observation?) -> String?
    func imageAtPath(imagePath: String?) -> UIImage
    func image(observation: Observation) -> UIImage
}

class ObservationImageRepositoryImpl: ObservationImageRepository, ObservableObject {
    
    static let shared = ObservationImageRepositoryImpl()
    private init() {} // prevents accidental new instances
    
    let annotationScaleWidth = 35.0
    
    private var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        return cache
    }()
    
    private lazy var documentsDirectory: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }()
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    func imageName(
        eventId: Int64?,
        formId: Int?,
        primaryFieldText: String?,
        secondaryFieldText: String?
    ) -> String? {
        guard let eventId = eventId else {
            return nil
        }
        
        let rootIconFolder = "\(documentsDirectory)/events/icons-\(eventId)/icons"
        var foundIcon = false
        let fileManager = FileManager.default

        var iconProperties: [String] = []
        if let formId = formId {
            iconProperties.append("\(formId)")
        }
        if let primaryFieldText = primaryFieldText, primaryFieldText.count != 0 {
            iconProperties.append(primaryFieldText)
        }

        if let secondaryFieldText = secondaryFieldText, secondaryFieldText.count != 0  {
            iconProperties.append(secondaryFieldText)
        }

        while (!foundIcon) {
            let iconPath = iconProperties.joined(separator: "/")
            var directoryToSearch = "\(rootIconFolder)/\(iconPath)"
            if iconPath.count != 0 {
                directoryToSearch = directoryToSearch + "/"
            }
            if fileManager.fileExists(atPath: directoryToSearch) {
                do {
                    let directoryContents = try fileManager.contentsOfDirectory(atPath: directoryToSearch)
                    if directoryContents.count != 0 {
                        for path in directoryContents {
                            let url = URL(fileURLWithPath: path)
                            let filename = url.lastPathComponent
                            if filename.hasPrefix("icon") {
                                let fullpath = "\(directoryToSearch)\(path)"
                                return fullpath
                            }
                        }
                    }

                    if iconProperties.count == 0 {
                        foundIcon = true;
                    } else {
                        iconProperties.removeLast()
                    }
                } catch {

                }
            } else {
                if iconProperties.count == 0 {
                    foundIcon = true;
                } else {
                    iconProperties.removeLast()
                }
            }
        }
        return nil
    }
    
    func imageName(observation: Observation?) -> String? {
        guard let observation = observation, let eventId = observation.eventId else {
            return nil
        }
        var formId: Int?
        if let primaryObservationForm = observation.primaryObservationForm, let formIdNumber = primaryObservationForm[FormKey.formId.key] as? NSNumber {
            formId = formIdNumber.intValue
        }

        var primaryText: String?
        if let primaryFieldText = observation.primaryFieldText, primaryFieldText.count != 0 {
            primaryText = primaryFieldText
        }

        var secondaryText: String?
        if let secondaryFieldText = observation.secondaryFieldText, secondaryFieldText.count != 0  {
            secondaryText = secondaryFieldText
        }

        return imageName(
            eventId: eventId.int64Value,
            formId: formId,
            primaryFieldText: primaryText,
            secondaryFieldText: secondaryText
        )
    }
    
    func image(observation: Observation) -> UIImage {
        return imageAtPath(imagePath: imageName(observation: observation))
    }
    
    func imageAtPath(imagePath: String?) -> UIImage {
        // 0) Fallback
        let fallback = UIImage(named: "defaultMarker")!

        // 1) Validate input
        guard var rawPath = imagePath, !rawPath.isEmpty else { return fallback }

        // 2) If the saved path points into an old container, remap it to THIS install’s Documents
        //    We do this by taking the suffix starting at "/Documents/" and joining to the current docs dir.
        if let docsRange = rawPath.range(of: "/Documents/") {
            let relativeFromDocs = String(rawPath[docsRange.upperBound...]) // e.g. "attachments/MAGE_ABC123"
            if let currentDocs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                rawPath = currentDocs.appendingPathComponent(relativeFromDocs).path
            }
        }

        let fm = FileManager.default
        var resolvedPath = rawPath

        // 3) If the exact file doesn't exist, treat path as a prefix and search its directory
        if !fm.fileExists(atPath: resolvedPath) {
            let candidate = URL(fileURLWithPath: resolvedPath)
            let dirURL = candidate.deletingLastPathComponent()
            let prefix = candidate.lastPathComponent

            if let urls = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil) {
                if let match = urls.first(where: { $0.lastPathComponent.hasPrefix(prefix) }) {
                    resolvedPath = match.path
                }
            }
        }

        // 4) Cache key based on the resolved path
        let cacheKey = resolvedPath as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            cached.accessibilityIdentifier = resolvedPath
            return cached
        }

        // 5) Load, scale, cache
        if let image = UIImage(contentsOfFile: resolvedPath), let cgImage = image.cgImage {
            let scale = image.size.width / annotationScaleWidth
            let scaledImage = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
            imageCache.setObject(scaledImage, forKey: cacheKey)
            scaledImage.accessibilityIdentifier = resolvedPath
            return scaledImage
        }

        // 6) Fallback
        fallback.accessibilityIdentifier = resolvedPath
        return fallback
    }

    
    func imageAtPath_ugh(imagePath: String?) -> UIImage {
        // Default if we can’t find anything
        let fallback = UIImage(named: "defaultMarker")!

        // 1) Validate input
        guard let rawPath = imagePath, !rawPath.isEmpty else {
            return fallback
        }

        // 2) Resolve to an actual file on disk
        var resolvedPath = rawPath
        let fm = FileManager.default

        if !fm.fileExists(atPath: rawPath) {
            // Treat rawPath as a prefix, search its directory for a file that starts with it
            let candidate = URL(fileURLWithPath: rawPath)
            let dirURL = candidate.deletingLastPathComponent()
            let prefix = candidate.lastPathComponent

            if let urls = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil) {
                if let match = urls.first(where: { $0.lastPathComponent.hasPrefix(prefix) }) {
                    resolvedPath = match.path
                }
            }
        }

        // 3) Use a cache key based on the resolved path
        let cacheKey = resolvedPath as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            cached.accessibilityIdentifier = resolvedPath
            return cached
        }

        // 4) Load, scale, cache
        if let image = UIImage(contentsOfFile: resolvedPath), let cgImage = image.cgImage {
            let scale = image.size.width / annotationScaleWidth
            let scaledImage = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
            imageCache.setObject(scaledImage, forKey: cacheKey)
            scaledImage.accessibilityIdentifier = resolvedPath
            return scaledImage
        }

        // 5) Fallback if the file still wasn’t found/readable
        fallback.accessibilityIdentifier = resolvedPath
        return fallback
    }

}
