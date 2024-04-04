//
//  ObservationImage.m
//  Mage
//
//

import Foundation

@objc public class ObservationImage: NSObject {
    
    static let annotationScaleWidth = 35.0
    
    public static var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        return cache
    }()
    
    static func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }

    public static func imageName(
        eventId: Int64?,
        formId: Int64?,
        primaryFieldText: String?,
        secondaryFieldText: String?
    ) -> String? {
        guard let eventId = eventId else {
            return nil
        }
        let rootIconFolder = "\(getDocumentsDirectory())/events/icons-\(eventId)/icons"
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
                                return "\(directoryToSearch)\(path)"
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

    @objc public static func imageName(observation: Observation?) -> String? {
        guard let observation = observation, let eventId = observation.eventId else {
            return nil
        }
        var formId: Int64?
        if let primaryObservationForm = observation.primaryObservationForm, let formIdNumber = primaryObservationForm[FormKey.formId.key] as? NSNumber {
            formId = formIdNumber.int64Value
        }

        var primaryText: String?
        if let primaryFieldText = observation.primaryFieldText, primaryFieldText.count != 0 {
            primaryText = primaryFieldText
        }

        var secondaryText: String?
        if let secondaryFieldText = observation.secondaryFieldText, secondaryFieldText.count != 0  {
            secondaryText = secondaryFieldText
        }

        return ObservationImage.imageName(
            eventId: eventId.int64Value,
            formId: formId,
            primaryFieldText: primaryText,
            secondaryFieldText: secondaryText
        )
    }
    
    @objc public static func image(observation: Observation) -> UIImage {
        guard let imagePath = ObservationImage.imageName(observation: observation) as NSString? else {
            return UIImage(named: "defaultMarker")!
        }
        
        if let image = ObservationImage.imageCache.object(forKey: imagePath) {
            // image is cached
            image.accessibilityIdentifier = imagePath as String
            return image
        }
        
        if let image = UIImage(contentsOfFile: imagePath as String), let cgImage = image.cgImage {
            let scale = image.size.width / annotationScaleWidth
            
            let scaledImage = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
            ObservationImage.imageCache.setObject(scaledImage, forKey: imagePath)
            scaledImage.accessibilityIdentifier = imagePath as String
            return scaledImage
        }
        
        let image = UIImage(named:"defaultMarker")!
        image.accessibilityIdentifier = imagePath as String
        return image
    }
}
