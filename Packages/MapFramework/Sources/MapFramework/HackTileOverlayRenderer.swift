/*
 This class fixes the blink when a tile overlay is removed or added to the map view.  Github repository explaining
 the bug and this fix is here: https://github.com/briancoyner/MKOverlayRendererBug
 */

import MapKit

final class HackTileOverlayRenderer: MKTileOverlayRenderer {

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}
