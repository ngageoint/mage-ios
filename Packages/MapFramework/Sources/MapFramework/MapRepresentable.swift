//
//  MapRepresentable.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import MapKit
import MAGEStyle

@MainActor
public struct MapRepresentable: UIViewRepresentable, MapProtocol {
    var notificationOnTap: NSNotification.Name = .MapItemsTapped
    var notificationOnLongPress: NSNotification.Name = .MapLongPress
    var focusNotification: NSNotification.Name = .FocusMapOnItem
    @State var name: String

    @ObservedObject var mixins: MapMixins
    @StateObject var mapState: MapState = MapState()
    var allowMapTapsOnItems: Bool = true

    public init(name: String, mixins: MapMixins, mapState: MapState?) {
        self.name = name
        self.mixins = mixins
        if let mapState = mapState {
            _mapState = StateObject(wrappedValue: mapState)
        }
    }

    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: UIScreen.main.bounds)
        // double tap recognizer has no action
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: nil)
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(doubleTapRecognizer)

        let singleTapGestureRecognizer = MapSingleTap(coordinator: context.coordinator, mapView: mapView)
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.numberOfTouchesRequired = 1
        singleTapGestureRecognizer.delaysTouchesBegan = true
        singleTapGestureRecognizer.cancelsTouchesInView = true
        singleTapGestureRecognizer.delegate = context.coordinator
        singleTapGestureRecognizer.require(toFail: doubleTapRecognizer)
        mapView.addGestureRecognizer(singleTapGestureRecognizer)

        let longPressGestureRecognizer = MapLongPress(coordinator: context.coordinator, mapView: mapView)
        mapView.addGestureRecognizer(longPressGestureRecognizer)

        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isPitchEnabled = false
        mapView.showsCompass = false
        mapView.tintColor = UIColor(Color.primaryColorVariant)
        mapView.accessibilityLabel = name

        context.coordinator.mapView = mapView
        if let region = context.coordinator.currentRegion {
            context.coordinator.setMapRegion(region: region)
        }

        mapView.register(
            EnlargedAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: EnlargedAnnotationView.ReuseID
        )

        for mixin in mixins.mixins {
            mixin.setupMixin(mapView: mapView, mapState: mapState)
        }
        context.coordinator.mixins = mixins.mixins
        context.coordinator.allowMapTapsOnItems = allowMapTapsOnItems
        return mapView
    }

    func setMapLocation(context: Context) {
        if let center = mapState.center,
           center.center.latitude != context.coordinator.setCenter?.latitude,
           center.center.longitude != context.coordinator.setCenter?.longitude {
            context.coordinator.setMapRegion(region: center)
            context.coordinator.setCenter = center.center
        }

        if let center = mapState.forceCenter, context.coordinator.forceCenterDate != mapState.forceCenterDate {
            context.coordinator.setMapRegion(region: center)
            context.coordinator.forceCenterDate = mapState.forceCenterDate
        }

        if let center = mapState.coordinateCenter, context.coordinator.forceCenterDate != mapState.forceCenterDate {
            context.coordinator.setCoordinateCenter(coordinate: center)
            context.coordinator.setCenter = center
        }
    }

    func setMapType(mapView: MKMapView, context: Context) {
        if let mkmapType = MKMapType(rawValue: UInt(mapState.mapType)) {
            mapView.mapType = mkmapType
        }
    }

    public func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.mapView = mapView
        context.coordinator.allowMapTapsOnItems = allowMapTapsOnItems

        setMapLocation(context: context)

        if context.coordinator.trackingModeSet != MKUserTrackingMode(rawValue: mapState.userTrackingMode) {
            mapView.userTrackingMode = MKUserTrackingMode(rawValue: mapState.userTrackingMode) ?? .none
            context.coordinator.trackingModeSet = MKUserTrackingMode(rawValue: mapState.userTrackingMode)
        }

        setMapType(mapView: mapView, context: context)

        // remove any mixins that were removed
        for mixin in context.coordinator.mixins
        where !mixins.mixins.contains(where: { mixinFromMixins in
            mixinFromMixins.uuid == mixin.uuid
        }) {
            // this means it was removed
            mixin.removeMixin(mapView: mapView, mapState: mapState)
        }

        for mixin in mixins.mixins {
            if !context.coordinator.mixins.contains(where: { mixinFromCoordinator in
                mixinFromCoordinator.uuid == mixin.uuid
            }) {
                // this means it is new
                mixin.setupMixin(mapView: mapView, mapState: mapState)
            } else {
                // just update it
                mixin.updateMixin(mapView: mapView, mapState: mapState)
            }
        }
        context.coordinator.mixins = mixins.mixins
    }
    
    public func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(self, focusNotification: focusNotification)
    }

}
