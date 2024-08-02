//
//  ObservationLocationFieldView.swift
//  MAGE
//
//  Created by Dan Barela on 8/1/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import MapFramework
import MAGEStyle
import MaterialViews

struct ObservationLocationFieldView: View {

    @StateObject var viewModel: ObservationLocationFieldViewModel = ObservationLocationFieldViewModel()
    @State var observationUri: URL
    @State var observationFormId: String
    @State var fieldName: String

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
            viewModel.observationFormId = observationFormId
            viewModel.fieldName = fieldName
            mixins.addMixin(OnlineLayerMapMixin())
            mixins.addMixin(ObservationMap(mapFeatureRepository: ObservationMapFeatureRepository(
                observationUri: observationUri,
                observationFormId: observationFormId,
                fieldName: fieldName
            )))
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
                            title: {},
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
                .buttonStyle(MaterialButtonStyle())
                .accessibilityElement()
                .accessibilityLabel("previous")
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
    }
}
