//
//  StaticLayerFeatureBottomSheetActionBar.swift
//  MAGE
//
//  Created by Dan Barela on 7/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct StaticLayerFeatureBottomSheetActionBar: View {
    var coordinate: CLLocationCoordinate2D?
    var navigateToAction: CoordinateActions

    var body: some View {
        HStack(spacing: 0) {
            CoordinateButton(action: CoordinateActions.copyCoordinate(coordinate: coordinate))
            
            Spacer()

            NavigateToButton(navigateToAction: navigateToAction)
        }
    }
}
