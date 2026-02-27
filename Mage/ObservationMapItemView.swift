//
//  ObservationMapItemView.swift
//  MAGE
//
//  Created by Daniel Barela on 4/10/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialViews
import SwiftUI
import MAGEStyle
import MapFramework
import GeoPackage

struct ObservationMapItemView: View {

    @StateObject var viewModel: ObservationMapItemViewModel = ObservationMapItemViewModel()
    @State var observationUri: URL

    @StateObject var mixins: MapMixins = MapMixins()
    @StateObject var mapState: MapState = MapState()

    let focusMapAtLocation = NotificationCenter.default.publisher(for: .FocusMapAtLocation)
    let longPressPub = NotificationCenter.default.publisher(for: .MapLongPress)

    var body: some View {
        VStack(spacing: 0) {
            map.frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
            coordinateButton
        }
        .onChange(of: observationUri) { observationUri in
            viewModel.observationUri = observationUri
        }
        .onChange(of: viewModel.currentItemIndex) { _ in
            updateMap()
        }
        .onChange(of: viewModel.observationMapItems) { _ in
            updateMap()
        }
        .onAppear {
            viewModel.observationUri = observationUri
            updateMap()
            mixins.addMixin(OnlineLayerMapMixin())
            mixins.addMixin(ObservationMap(mapFeatureRepository: ObservationMapFeatureRepository(observationUri: observationUri)))
        }
    }
    
    func updateMap() {
        if let currentItem = viewModel.currentItem {
            let region = currentItem.boundingRegion()
            mapState.centerRegion = region
        }
    }

    var map: some View {
        MapRepresentable(name: "MAGE Map", mixins: mixins, mapState: mapState)
            .ignoresSafeArea()
    }

    var coordinateButton: some View {
        HStack(spacing: 0) {
            if viewModel.observationMapItems.count == 1 {
                if let item = viewModel.currentItem, let coordinate = item.coordinate {
                    Spacer()
                    CoordinateButton(action: CoordinateActions.copyCoordinate(coordinate: coordinate))
                        .buttonStyle(MaterialButtonStyle())
                        .padding(.trailing, 8)
                    Text(item.accuracyDisplay ?? "")
                        .font(Font.caption)
                        .foregroundColor(Color.onSurfaceColor.opacity(0.6))
                    Spacer()
                }
            } else if viewModel.observationMapItems.count > 1 {
                Button(
                    action: {
                        viewModel.currentItemIndex = max(0, viewModel.currentItemIndex  - 1)
                    },
                    label: {
                        Label(
                            title: {EmptyView()},
                            icon: {
                                Image(systemName: "chevron.left")
                                    .renderingMode(.template)
                                    .foregroundColor(viewModel.currentItemIndex  != 0
                                                     ? Color.primaryColorVariant : Color.disabledColor
                                    )
                            })
                    }
                )
                .contentShape(Rectangle())
                .buttonStyle(MaterialButtonStyle(type: .text))
                .accessibilityElement()
                .accessibilityLabel("previous")
                if let item = viewModel.currentItem, let coordinate = item.coordinate {
                    CoordinateButton(action: CoordinateActions.copyCoordinate(coordinate: coordinate))
                        .buttonStyle(MaterialButtonStyle())
                        .padding(.trailing, 8)
                    Text(item.accuracyDisplay ?? "")
                        .font(Font.caption)
                        .foregroundColor(Color.onSurfaceColor.opacity(0.6))
                }
                Button(
                    action: {
                        viewModel.currentItemIndex = min(viewModel.observationMapItems.count - 1, viewModel.currentItemIndex + 1)
                    },
                    label: {
                        Label(
                            title: {},
                            icon: {
                                Image(systemName: "chevron.right")
                                    .renderingMode(.template)
                                    .foregroundColor(viewModel.observationMapItems.count - 1 != viewModel.currentItemIndex
                                                     ? Color.primaryColorVariant : Color.disabledColor)
                            })
                    }
                )
                .contentShape(Rectangle())
                .buttonStyle(MaterialButtonStyle())
                .accessibilityElement()
                .accessibilityLabel("next")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
