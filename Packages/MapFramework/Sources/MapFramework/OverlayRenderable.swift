//
//  File.swift
//  
//
//  Created by Daniel Barela on 4/12/24.
//

import Foundation
import MapKit

public protocol OverlayRenderable {
    var renderer: MKOverlayRenderer { get }
}
