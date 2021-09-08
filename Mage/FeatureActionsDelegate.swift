//
//  FeatureActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 7/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc protocol FeatureActionsDelegate {
    @objc optional func getDirectionsToLocation(_ location: CLLocationCoordinate2D, title: String?, sourceView: UIView?);
    @objc optional func viewFeature(annotation: MapAnnotation);
}
