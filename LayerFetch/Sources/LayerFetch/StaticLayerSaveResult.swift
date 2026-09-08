import Foundation
import FetchOperation
import ServerDTO

public struct StaticLayerIconLocation: Sendable {
    let url: URL
    let layerID: LayerID
    let featureID: StaticLayerFeatureID
}
public struct StaticLayerSaveResult: Sendable {
    public init(
        saveCount: Int,
        iconsToFetch: [StaticLayerIconLocation]
    ) {
        self.saveCount = saveCount
        self.iconsToFetch = iconsToFetch
    }
    
    public var saveCount: Int
    public var iconsToFetch: [StaticLayerIconLocation] = []
}
