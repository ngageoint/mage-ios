//
//  ObservationIconLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 6/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct ObservationIconLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationIconLocalDataSource = ObservationIconCoreDataDataSource()
}

extension InjectedValues {
    var observationIconLocalDataSource: ObservationIconLocalDataSource {
        get { Self[ObservationIconLocalDataSourceProviderKey.self] }
        set { Self[ObservationIconLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol ObservationIconLocalDataSource {
//    func getIconPath(observationUri: URL) async -> String?
//    func getIconPath(observation: Observation) -> String?
    func getMaximumIconHeightToWidthRatio(eventId: Int) async -> CGSize
    func resetEventIconSize(eventId: Int)
}

class ObservationIconCoreDataDataSource: ObservationIconLocalDataSource {
    @Injected(\.observationLocalDataSource)
    var localDataSource: ObservationLocalDataSource
    
    var iconSizePerEvent: [Int: CGSize] = [:]
    
//    func getIconPath(observationUri: URL) async -> String? {
//        if let observation = await localDataSource.getObservation(observationUri: observationUri) {
//            return getIconPath(observation: observation)
//        }
//        return nil
//    }
//
//    func getIconPath(observation: Observation) -> String? {
//        ObservationImage.imageName(observation: observation)
//    }

    let queue = DispatchQueue(label: "Queue")

    func getMaximumIconHeightToWidthRatio(eventId: Int) async -> CGSize {
        if let eventIconSize = iconSizePerEvent[eventId] {
            return eventIconSize
        }
        
        return await withCheckedContinuation { continuation in
            // doing this to synchronize access to the size
            // see: https://www.donnywals.com/an-introduction-to-synchronizing-access-with-swifts-actors/
            queue.async {
                if let iconSize = self.iconSizePerEvent[eventId] {
                    continuation.resume(returning: iconSize)
                } else {
                    // start with the default marker
                    var size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0)
                    if let defaultMarker = UIImage(named: "defaultMarker") {
                        size = defaultMarker.size
                    }
                    let iconSize = self.iterateIconDirectoriesAtRoot(
                        directory: self.rootIconFolder(eventId: eventId),
                        currentLargest: size
                    )
                    self.iconSizePerEvent[eventId] = iconSize
                    continuation.resume(returning: iconSize)
                }
            }
          }
    }
    
    func resetEventIconSize(eventId: Int) {
        iconSizePerEvent.removeValue(forKey: eventId)
    }

    func iterateIconDirectoriesAtRoot(
        directory: URL,
        currentLargest: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0)
    ) -> CGSize {
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
