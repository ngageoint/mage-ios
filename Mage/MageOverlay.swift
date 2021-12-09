//
//  MageOverlay.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol MageOverlay {
    var renderer: MKOverlayRenderer? { get set }
}
