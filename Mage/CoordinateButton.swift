//
//  CoordinateButton.swift
//  Marlin
//
//  Created by Daniel Barela on 6/15/23.
//

import SwiftUI
import MapKit

struct CoordinateButton: View {
    var action: CoordinateActions

    var body: some View {
        if let coordinate = action.getCoordinate() {
            Button {
                action()
            } label: {
                Label {
                    Text(coordinate.toDisplay(short: true))
                        .lineLimit(1)
                } icon: {
                    Image(uiImage: UIImage(named: "location_tracking_on")!.resized(to: CGSize(width: 14, height: 14)).withRenderingMode(.alwaysTemplate))
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Location")
        }
    }
}
