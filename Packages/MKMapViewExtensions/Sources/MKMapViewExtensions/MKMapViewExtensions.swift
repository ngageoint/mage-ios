import MapKit

extension MKMapView {

    static let MAX_CLUSTER_ZOOM = 17

    // modified from https://github.com/d-babych/mapkit-wrap/blob/master/MapKitWrap/MyMap.swift
    public var zoomLevel: Int {
        // function returns current zoom of the map
        var angleCamera = self.camera.heading
        if angleCamera > 270 {
            angleCamera = 360 - angleCamera
        } else if angleCamera > 90 {
            angleCamera = fabs(angleCamera - 180)
        }
        let angleRad = .pi * angleCamera / 180 // camera heading in radians
        let width = Double(self.frame.size.width)
        let height = Double(self.frame.size.height)
        let heightOffset : Double = 20 // the offset (status bar height) which is taken by MapKit into consideration to calculate visible area height
        // calculating Longitude span corresponding to normal (non-rotated) width
        let spanStraight = width * self.region.span.longitudeDelta / (width * cos(angleRad) + (height - heightOffset) * sin(angleRad))
        let double = log2(360 * ((width / 256) / spanStraight)) + 1
        return Int(double)
      }

}
