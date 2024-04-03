// The Swift Programming Language
// https://docs.swift.org/swift-book
import MapKit

extension MKMapView {

    static let MAX_CLUSTER_ZOOM = 17

    public var zoomLevel: Int {
        let maxZoom: Double = 20
        var width = self.frame.size.width
        if width == 0.0 {
            let windowSize = UIApplication.shared.connectedScenes
                .compactMap({ scene -> UIWindow? in
                    (scene as? UIWindowScene)?.keyWindow
                })
                .first?
                .frame
                .size
            width = windowSize?.width ?? 0.0
        }
        if width != 0.0 {
            let zoomScale = self.visibleMapRect.size.width / Double(width)
            let zoomExponent = log2(zoomScale)
            return Int(maxZoom - ceil(zoomExponent))
        }
        return 0
    }

}
