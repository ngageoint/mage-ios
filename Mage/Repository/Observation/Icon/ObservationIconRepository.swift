//
//  ObservationIconRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 3/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIImageExtensions

class ObservationIconRepository: ObservableObject {
    let observationRepository: ObservationRepository
    init(observationRepository: ObservationRepository) {
        self.observationRepository = observationRepository
    }

    func getIconPath(observationUri: URL) async -> String? {
        if let observation = await observationRepository.getObservation(observationUri: observationUri) {
            return getIconPath(observation: observation)
        }
        return nil
    }

    func getIconPath(observation: Observation) -> String? {
        ObservationImage.imageName(observation: observation)
    }

    func getMaximumIconHeightToWidthRatio(eventId: Int) -> CGSize {
        return iterateIconDirectoriesAtRoot(directory: rootIconFolder(eventId: eventId))
    }

    func iterateIconDirectoriesAtRoot(directory: URL, currentLargest: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0)) -> CGSize {
        var largest = currentLargest
        do {
            let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
            let enumerator = FileManager.default.enumerator(at: directory,
                                                            includingPropertiesForKeys: resourceKeys,
                                                            options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                print("directoryEnumerator error at \(url): ", error)
                return true
            })!

            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                if resourceValues.isDirectory == true {
                    largest = iterateIconDirectoriesAtRoot(directory: fileURL, currentLargest: largest)
                } else {
                    let size = UIImage.getSizeOfImageFile(fileUrl: fileURL)

                    let heightToWidthRatio = size.height / size.width
                    let currentRatio = largest.height / largest.width

                    if heightToWidthRatio > currentRatio {
                        largest = size
                    }
                }
            }
        } catch {
            print(error)
        }
        return largest
    }

    func rootIconFolder(eventId: Int) -> URL {
        URL(fileURLWithPath: "\(getDocumentsDirectory())/events/icons-\(eventId)/icons", isDirectory: true)
    }

    func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
}
