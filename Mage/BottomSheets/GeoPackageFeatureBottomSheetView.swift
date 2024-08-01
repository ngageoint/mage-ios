//
//  GeoPackageFeatureBottomSheetView.swift
//  MAGE
//
//  Created by Daniel Barela on 9/20/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import MAGEStyle

struct GeoPackageFeatureBottomSheet: View {
    @ObservedObject
    var viewModel: GeoPackageFeatureBottomSheetViewModel
    
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 0) {
                GeoPackageFeatureSummary(
                    title: viewModel.title,
                    date: viewModel.date,
                    secondaryTitle: viewModel.secondaryTitle,
                    layerName: viewModel.layerName,
                    featureDetail: viewModel.featureDetail,
                    icon: viewModel.icon,
                    color: viewModel.color
                )
                
                StaticLayerFeatureBottomSheetActionBar(
                    coordinate: viewModel.coordinate,
                    navigateToAction: CoordinateActions.navigateTo(
                        coordinate: viewModel.coordinate,
                        itemKey: viewModel.itemKey,
                        dataSource: DataSources.featureItem
                    )
                )
                
                GeoPackageMediaView(medias: viewModel.mediaRows)
                GeoPackagePropertyRows(rows: viewModel.propertyRows)
                
                ForEach(viewModel.attributeRelations, id: \.self) { attributeRow in
                    Text("Attributes")
                        .primaryText()
                    GeoPackageMediaView(medias: attributeRow.medias)
                    GeoPackagePropertyRows(rows: attributeRow.properties)
                }
            }
            .id(viewModel.itemKey)
            .ignoresSafeArea()
        }
    }
}
