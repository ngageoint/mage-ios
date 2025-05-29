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
        .onChange(of: viewModel.selectedItem) { selectedItem in
            mapState.coordinateCenter = viewModel.currentItem?.coordinate
        }
        .onAppear {
            viewModel.observationUri = observationUri
            mixins.addMixin(OnlineLayerMapMixin())
            mixins.addMixin(ObservationMap(mapFeatureRepository: ObservationMapFeatureRepository(observationUri: observationUri)))
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
                        withAnimation {
                            viewModel.selectedItem = max(0, viewModel.selectedItem  - 1)
                        }
                    },
                    label: {
                        Label(
                            title: {EmptyView()},
                            icon: {
                                Image(systemName: "chevron.left")
                                    .renderingMode(.template)
                                    .foregroundColor(viewModel.selectedItem  != 0
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
                        withAnimation {
                            viewModel.selectedItem = min(viewModel.observationMapItems.count - 1, viewModel.selectedItem + 1)
                        }
                    },
                    label: {
                        Label(
                            title: {},
                            icon: {
                                Image(systemName: "chevron.right")
                                    .renderingMode(.template)
                                    .foregroundColor(viewModel.observationMapItems.count - 1 != viewModel.selectedItem
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
