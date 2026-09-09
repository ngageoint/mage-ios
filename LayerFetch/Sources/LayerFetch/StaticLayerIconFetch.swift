import FetchOperation
import Foundation
import Pipeline

public protocol StaticLayerIconFetch: Sendable {
    func fetch(
        iconsToFetch: [StaticLayerIconLocation],
        progress: @escaping OperationProgressHandler
    ) async throws
}

final class StaticLayerIconFetchImpl: StaticLayerIconFetch {
    func fetch(
        iconsToFetch: [StaticLayerIconLocation],
        progress: @escaping OperationProgressHandler
    ) async throws {
        let totalCount = Int64(iconsToFetch.count)
        var saveCount: Int64 = 0
        let documentsDirectory = getDocumentsDirectory()
        for icon in iconsToFetch {
            
            let featureIconRelativePath = "featureIcons/\(icon.layerID.rawValue)/\(icon.featureID.rawValue)"
            let featureIconPath = "\(documentsDirectory)/\(featureIconRelativePath)"
            do {
                let imageData = try Data(contentsOf: icon.url)
                if !FileManager.default.fileExists(atPath: featureIconPath) {
                    let featureDirectory = URL(fileURLWithPath: featureIconPath).deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: featureDirectory, withIntermediateDirectories: true, attributes: nil);
                    try imageData.write(to: URL(fileURLWithPath: featureIconPath), options: .atomic)
                    LayerFetchPackage.logger.debug("Wrote file to \(featureIconPath)")
                }
            } catch {
                LayerFetchPackage.logger.error("Failed to save icon: \(error)")
            }
            
            saveCount += 1
            
            if saveCount % 50 == 0 {
                try Task.checkCancellation()
                progress(
                    OperationProgress(
                        completed: saveCount,
                        total: totalCount
                    )
                )
            }
        }
        progress(
            OperationProgress(
                completed: saveCount,
                total: totalCount
            )
        )
        
        LayerFetchPackage.logger.info("Saved \(saveCount) static layers")
    }
    
    func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
}
