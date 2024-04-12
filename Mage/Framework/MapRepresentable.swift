//
//  MapRepresentable.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

struct MarlinMap: UIViewRepresentable, MarlinMapProtocol {
    var notificationOnTap: NSNotification.Name = .MapItemsTapped
    var notificationOnLongPress: NSNotification.Name = .MapLongPress
    var focusNotification: NSNotification.Name = .FocusMapOnItem
    @State var name: String

    @ObservedObject var mixins: MapMixins
    @StateObject var mapState: MapState = MapState()
    var allowMapTapsOnItems: Bool = true

    func makeUIView(context: Context) -> MKMapView {
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

    func setupScale(mapView: MKMapView, context: Context) {
        let scale = context.coordinator.mapScale ?? mapView.subviews.first { view in
            return (view as? MKScaleView) != nil
        }
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
        //        if mapState.mapType == ExtraMapTypes.osm.rawValue {
        //            if context.coordinator.osmOverlay == nil {
        //                context.coordinator.osmOverlay
        //                = MKTileOverlay(urlTemplate: "https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png")
        //                context.coordinator.osmOverlay?.tileSize = CGSize(width: 512, height: 512)
        //                context.coordinator.osmOverlay?.canReplaceMapContent = true
        //            }
        //            mapView.removeOverlay(context.coordinator.osmOverlay!)
        //            mapView.insertOverlay(context.coordinator.osmOverlay!, at: 0, level: .aboveRoads)
        //        } else if let mkmapType = MKMapType(rawValue: UInt(mapState.mapType)) {
        //            mapView.mapType = mkmapType
        //            if let osmOverlay = context.coordinator.osmOverlay {
        //                mapView.removeOverlay(osmOverlay)
        //            }
        //        }
    }

    func setGrids(mapView: MKMapView, context: Context) {
        //        if mapState.showGARS {
        //            if context.coordinator.garsOverlay == nil {
        //                context.coordinator.garsOverlay = GARSTileOverlay(512, 512)
        //            }
        //            mapView.addOverlay(context.coordinator.garsOverlay!, level: .aboveRoads)
        //        } else {
        //            if let garsOverlay = context.coordinator.garsOverlay {
        //                mapView.removeOverlay(garsOverlay)
        //            }
        //        }
        //
        //        if mapState.showMGRS {
        //            if context.coordinator.mgrsOverlay == nil {
        //                context.coordinator.mgrsOverlay = MGRSTileOverlay(512, 512)
        //            }
        //            mapView.addOverlay(context.coordinator.mgrsOverlay!, level: .aboveRoads)
        //        } else {
        //            if let mgrsOverlay = context.coordinator.mgrsOverlay {
        //                mapView.removeOverlay(mgrsOverlay)
        //            }
        //        }
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.mapView = mapView
        context.coordinator.allowMapTapsOnItems = allowMapTapsOnItems

        setupScale(mapView: mapView, context: context)

        setMapLocation(context: context)

        if context.coordinator.trackingModeSet != MKUserTrackingMode(rawValue: mapState.userTrackingMode) {
            mapView.userTrackingMode = MKUserTrackingMode(rawValue: mapState.userTrackingMode) ?? .none
            context.coordinator.trackingModeSet = MKUserTrackingMode(rawValue: mapState.userTrackingMode)
        }

        setMapType(mapView: mapView, context: context)

        setGrids(mapView: mapView, context: context)

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

    func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(self, focusNotification: focusNotification)
    }

}
