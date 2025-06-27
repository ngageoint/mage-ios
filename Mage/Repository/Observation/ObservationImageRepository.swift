//
//  ObservationImageRepository.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct ObservationImageRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationImageRepository = ObservationImageRepositoryImpl()
}

extension InjectedValues {
    var observationImageRepository: ObservationImageRepository {
        get { Self[ObservationImageRepositoryProviderKey.self] }
        set { Self[ObservationImageRepositoryProviderKey.self] = newValue }
    }
}

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
    
    // This is used as the key to a dictionary of imageNames
    struct ImageNameCacheKey: Hashable {
        let eventId: Int64
        let formId: Int?
        let primaryFieldText: String?
        let secondaryFieldText: String?
    }
    
    private static let cacheQueue = DispatchQueue(label: "imageNameCacheQueue")
    /**
     # Returning an image location/name and storing it for later
     - `rootIconFolder` = "\(documentsDirectory)/events/icons-\(eventId)/icons"
       + this only changes with the `eventId`
     - `iconPath` - each of the following variables gets appended to each other like this
       + `formId/primaryFieldText/secondaryFieldText`
       + one by one, if not found, removing the last variable from the string
     - We end up with a fullpath to some icon, if we find one
     - So the point of this cache and queue is to safely store them once to keep the lookup as close to O(N) as possible
     */
    private static var imageNameCache: [ImageNameCacheKey: String?] = [:]
    
    func imageName(
        eventId: Int64?,
        formId: Int?,
        primaryFieldText: String?,
        secondaryFieldText: String?
    ) -> String? {
        guard let eventId = eventId else {
            return nil
        }
        
        let cacheKey = ImageNameCacheKey(
            eventId: eventId,
            formId: formId,
            primaryFieldText: primaryFieldText,
            secondaryFieldText: secondaryFieldText
        )
        
        // Read from cache
        if let cachedResult = ObservationImageRepositoryImpl.cacheQueue.sync(execute: {
            ObservationImageRepositoryImpl.imageNameCache[cacheKey]
        }) {
            return cachedResult
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
                                // Write to cache
                                ObservationImageRepositoryImpl.cacheQueue.sync {
                                    ObservationImageRepositoryImpl.imageNameCache[cacheKey] = fullpath
                                }
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
        guard let imagePath = imagePath as? NSString else {
            return UIImage(named: "defaultMarker")!
        }
        if let image = imageCache.object(forKey: imagePath) {
            // image is cached
            image.accessibilityIdentifier = imagePath as String
            return image
        }

        if let image = UIImage(contentsOfFile: imagePath as String), let cgImage = image.cgImage {
            let scale = image.size.width / annotationScaleWidth

            let scaledImage = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
            imageCache.setObject(scaledImage, forKey: imagePath)
            scaledImage.accessibilityIdentifier = imagePath as String
            return scaledImage
        }

        let image = UIImage(named:"defaultMarker")!
        image.accessibilityIdentifier = imagePath as String
        return image
    }
}
