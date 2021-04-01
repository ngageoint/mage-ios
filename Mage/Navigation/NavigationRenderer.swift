//
//  NavigationRenderer.swift
//
//  Created by Tyler Burgett on 8/21/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation
import MapKit

class NavigationRenderer: MKOverlayRenderer {
    var lineWidth:CGFloat = 1.0
    var strokeColor:CGColor = CGColor.init(srgbRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let navigationOverlay:NavigationOverlay = self.overlay as! NavigationOverlay
        let path = CGMutablePath()
        
        path.move(to: self.point(for: navigationOverlay.startPoint))
        path.addLine(to: self.point(for: navigationOverlay.endPoint))
        
        if let safeUpperAccuracyEndPoint = navigationOverlay.upperAccuracyEndPoint {
            path.move(to: self.point(for: navigationOverlay.startPoint))
            path.addLine(to: self.point(for: safeUpperAccuracyEndPoint))
        }
        
        if let safeLowerAccuracyEndPoint = navigationOverlay.lowerAccuracyEndPoint {
            path.move(to: self.point(for: navigationOverlay.startPoint))
            path.addLine(to: self.point(for: safeLowerAccuracyEndPoint))
        }
        
        context.addPath(path)
        context.setStrokeColor(self.strokeColor)
        context.setLineCap(.round)
        context.setLineWidth(self.lineWidth/zoomScale)
        context.drawPath(using: .fillStroke)
    }
}
