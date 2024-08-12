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
    case navigateTo(
        coordinate: CLLocationCoordinate2D?,
        itemKey: String?,
        dataSource: any DataSourceDefinition,
        includeCopy: Bool = false
    )
    
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
                        
        case .navigateTo(coordinate: let coordinate, itemKey: let itemKey, dataSource: let dataSource, includeCopy: let includeCopy):
            NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
            NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)
            
            if let coordinate = coordinate {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let notification = DirectionsToItemNotification(
                        location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                        itemKey: itemKey,
                        dataSource: dataSource,
                        includeCopy: includeCopy
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
        case .navigateTo(coordinate: let coordinate, itemKey: _, dataSource: _, includeCopy: _):
            if let coordinate = coordinate, CLLocationCoordinate2DIsValid(coordinate) {
                return coordinate
            }
            
        }
        return nil
    }
}

enum ObservationActions {
    case favorite(observationUri: URL?, userRemoteId: String?)
    case syncNow(observationUri: URL?)
    case toggleImportant(observationUri: URL?)
    
    func callAsFunction() {
        switch (self) {
 
        case .favorite(observationUri: let observationUri, userRemoteId: let userRemoteId):
            print("favorite")
            if let userRemoteId = userRemoteId {
                @Injected(\.observationFavoriteRepository)
                var observationFavoriteRepository: ObservationFavoriteRepository
                observationFavoriteRepository.toggleFavorite(observationUri: observationUri, userRemoteId: userRemoteId)
            }
        case .syncNow(observationUri: let observationUri):
            print("sync now")
            @Injected(\.observationRepository)
            var observationRepository: ObservationRepository
            observationRepository.syncObservation(uri: observationUri)
        case .toggleImportant(observationUri: let observationUri):
            print("toggle important")
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

struct ObservationViewActionBar: View {
    var isImportant: Bool
    var importantAction: () -> Void
    var favoriteCount: Int?
    var currentUserFavorite: Bool
    var favoriteAction: ObservationActions
    var showFavoritesAction: () -> Void
    var navigateToAction: CoordinateActions
    var moreActions: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ShowFavoritesButton(
                favoriteCount: favoriteCount,
                favoriteAction: showFavoritesAction
            )
            
            Spacer()
            
            ImportantButton(
                importantAction: importantAction,
                isImportant: isImportant
            )
            
            FavoriteButton(
                currentUserFavorite: currentUserFavorite,
                favoriteAction: favoriteAction
            )
            
            NavigateToButton(navigateToAction: navigateToAction)
            
            Button(action: moreActions) {
                Label {
                    Text("")
                } icon: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                }
            }
            .buttonStyle(MaterialButtonStyle(foregroundColor: .onSurfaceColor.opacity(0.6)))
        }
    }
}

struct ObservationListActionBar: View {
    var coordinate: CLLocationCoordinate2D?
    var isImportant: Bool
    var importantAction: () -> Void
    var favoriteCount: Int?
    var currentUserFavorite: Bool
    var favoriteAction: ObservationActions
    var navigateToAction: CoordinateActions
    
    var body: some View {
        HStack(spacing: 0) {
            if let coordinate = coordinate {
                CoordinateButton(action: CoordinateActions.copyCoordinate(coordinate: coordinate))
            }
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
