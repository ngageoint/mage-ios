//
//  Actions.swift
//  Marlin
//
//  Created by Daniel Barela on 2/8/24.
//

import Foundation
import MapKit
import SwiftUI

protocol Action {
    func action()
}

enum Actions {
    class Location: Action {
        var latLng: CLLocationCoordinate2D
        init(latLng: CLLocationCoordinate2D) {
            self.latLng = latLng
        }

        func action() {
            let coordinateDisplay = UserDefaults.standard.coordinateDisplay
            UIPasteboard.general.string = coordinateDisplay.format(coordinate: latLng)
            
            NotificationCenter.default.post(
                name: .SnackbarNotification,
                object: SnackbarNotification(
                    snackbarModel: AlertModel(
                        message: "Location \(coordinateDisplay.format(coordinate: latLng)) copied to clipboard")
                )
            )
        }
    }
}
