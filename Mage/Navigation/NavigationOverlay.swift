//
//  NavigationOverlay.swift
//
//  Created by Tyler Burgett on 8/21/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation
import MapKit
import MapFramework

class NavigationOverlay: MKPolyline, OverlayRenderable {
    var color: UIColor = UIColor.systemRed
    var lineWidth: CGFloat = 1.0
    
    var renderer: MKOverlayRenderer {
        get {
            let renderer = MKPolylineRenderer(overlay: self);
            renderer.strokeColor = self.color;
            renderer.lineWidth = self.lineWidth;
            return renderer;
        }
    }

    public convenience init(points: UnsafePointer<MKMapPoint>, count: Int, color: UIColor = .systemRed, lineWidth: CGFloat = 8.0) {
        self.init(points: points, count: count);
        self.color = color;
        self.lineWidth = lineWidth;
    }
}
