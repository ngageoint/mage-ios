//
//  ObservationLocationBottomSheetActionBar.swift
//  MAGE
//
//  Created by Dan Barela on 7/17/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import MaterialViews
import DataSourceDefinition

enum CoordinateActions {
    case copyCoordinate(coordinate: CLLocationCoordinate2D?)
    case navigateTo(coordinate: CLLocationCoordinate2D?, itemKey: String?, dataSource: any DataSourceDefinition)
    
    func callAsFunction() {
        switch (self) {
            
        case .copyCoordinate(coordinate: let coordinate):
            guard let coordinate = coordinate else { break }
            let coordinateDisplay = UserDefaults.standard.coordinateDisplay
            UIPasteboard.general.string = coordinateDisplay.format(coordinate: coordinate)
            NotificationCenter.default.post(
                name: .SnackbarNotification,
                object: SnackbarNotification(
                    snackbarModel: SnackbarModel(
                        message: "Location \(coordinateDisplay.format(coordinate: coordinate)) copied to clipboard")
                )
            )
                        
        case .navigateTo(coordinate: let coordinate, itemKey: let itemKey, dataSource: let dataSource):
            NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
            NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)
            
            if let coordinate = coordinate {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let notification = DirectionsToItemNotification(
                        location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                        itemKey: itemKey,
                        dataSource: dataSource
                    )
                    NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
                }
            }
        }
    }
    
    func getCoordinate() -> CLLocationCoordinate2D? {
        switch (self) {
            
        case .copyCoordinate(coordinate: let coordinate):
            if let coordinate = coordinate, CLLocationCoordinate2DIsValid(coordinate) {
                return coordinate
            }
        case .navigateTo(coordinate: let coordinate, itemKey: _, dataSource: _):
            if let coordinate = coordinate, CLLocationCoordinate2DIsValid(coordinate) {
                return coordinate
            }
            
        }
        return nil
    }
}

enum ObservationActions {
    case favorite(viewModel: ObservationLocationBottomSheetViewModel)
    
    func callAsFunction() {
        switch (self) {
 
        case .favorite(viewModel: let viewModel):
            viewModel.toggleFavorite()
        }
    }
    
    func getObservationMapItem() -> ObservationMapItem? {
        switch (self) {
        case .favorite(viewModel: let viewModel):
            return viewModel.observationMapItem
        }
    }
}

struct ObservationLocationBottomSheetActionBar: View {
    var coordinate: CLLocationCoordinate2D?
    var favoriteCount: Int?
    var currentUserFavorite: Bool
    var favoriteAction: ObservationActions
    var navigateToAction: CoordinateActions
    
    var body: some View {
        HStack(spacing: 0) {
            CoordinateButton(action: CoordinateActions.copyCoordinate(coordinate: coordinate))
            
            Spacer()
            
            FavoriteButton(
                favoriteCount: favoriteCount,
                currentUserFavorite: currentUserFavorite,
                favoriteAction: favoriteAction
            )
            
            NavigateToButton(navigateToAction: navigateToAction)
        }
    }
}

