//
//  NavigationOverlay.swift
//
//  Created by Tyler Burgett on 8/21/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation
import MapKit

class NavigationOverlay: NSObject, MKOverlay {
    var color: UIColor
    var lineWidth: CGFloat
    var coordinate: CLLocationCoordinate2D
    var startPoint: MKMapPoint
    var endPoint: MKMapPoint
    var boundingMapRect: MKMapRect
    var lowerAccuracyEndPoint: MKMapPoint?
    var upperAccuracyEndPoint: MKMapPoint?
    @objc public lazy var renderer: NavigationRenderer = {
        var renderer = NavigationRenderer(overlay: self);
        // get the color from user preferences
        renderer.strokeColor = self.color.cgColor;
        renderer.lineWidth = self.lineWidth;
        return renderer;
    }()
    
    init(start: MKMapPoint, end:MKMapPoint, boundingMapRect:MKMapRect, color: UIColor = UIColor.systemRed, lineWidth: CGFloat = 8.0) {
        self.color = color;
        self.lineWidth = lineWidth;
        self.coordinate = start.coordinate
        self.startPoint = start
        self.endPoint = end;
        self.boundingMapRect = boundingMapRect
    }
}
