//
//  CoordinateButton.swift
//  Marlin
//
//  Created by Daniel Barela on 6/15/23.
//

import SwiftUI
import MapKit

struct CoordinateButton: View {
    var action: Actions.Location

    @AppStorage("coordinateDisplay") var coordinateDisplay: CoordinateDisplayType = .latitudeLongitude

    var body: some View {
        if CLLocationCoordinate2DIsValid(action.latLng) {
            Button(action: action.action) {
                HStack {
                    Image(uiImage: UIImage(named: "location_tracking_on")!.resized(to: CGSize(width: 14, height: 14)).withRenderingMode(.alwaysTemplate))
                    Text(action.latLng.toDisplay(short: true))
                        .foregroundColor(Color.primaryColorVariant)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .padding(8)
            .accessibilityElement()
            .accessibilityLabel("Location")
        }
    }
}
