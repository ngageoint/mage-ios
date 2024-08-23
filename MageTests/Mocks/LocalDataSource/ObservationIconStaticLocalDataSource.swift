//
//  ObservationIconStaticLocalDataSource.swift
//  MAGETests
//
//  Created by Dan Barela on 5/16/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import OHHTTPStubs

@testable import MAGE

class ObservationIconStaticLocalDataSource: ObservationIconLocalDataSource {
    func resetEventIconSize(eventId: Int) {
        
    }
    
    func getIconPath(observationUri: URL) async -> String? {
        return OHPathForFile("110.png", type(of: self))
    }
    
    func getIconPath(observation: MAGE.Observation) -> String? {
        return OHPathForFile("110.png", type(of: self))
    }
    
    func getMaximumIconHeightToWidthRatio(eventId: Int) -> CGSize {
        var size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0)
        let path = OHPathForFile("110.png", type(of: self))
        if let defaultMarker = UIImage(contentsOfFile: path!) {
            size = defaultMarker.size
        }
        return size
    }
    
}
