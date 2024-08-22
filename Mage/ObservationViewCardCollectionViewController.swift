//
//  ObservationViewCardCollectionViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialCollections
import MaterialComponents.MDCCard
import MaterialComponents.MDCContainerScheme;
import Combine
import SwiftUI
import MaterialViews
import MAGEStyle

struct ObservationFullView: View {
    @StateObject
    var viewModel: ObservationViewViewModel
    
    @EnvironmentObject
    var router: MageRouter
    
    var selectedUnsentAttachment: (_ localPath: String, _ contentType: String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ObservationHeaderViewSwiftUI(
                    viewModel: viewModel
                )
                
                Text("Forms")
                    .overlineText()
                    .padding()
                ForEach(viewModel.observationForms ?? []) { form in
                    ObservationFormViewSwiftUI(
                        viewModel: ObservationFormViewModel(form: form),
                        selectedUnsentAttachment: selectedUnsentAttachment
                    )
                }
            }
            .padding(.bottom, 36)
            .padding([.top, .leading, .trailing], 8)
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.currentUserCanEdit {
                Button {
                    router.appendRoute(ObservationRoute.edit(uri: viewModel.observationModel?.observationId))
                } label: {
                    Label {
                        Text("")
                    } icon: {
                        Image(systemName: "pencil")
                            .fontWeight(.black)
                    }
                    
                }
                .fixedSize()
                .buttonStyle(
                    MaterialFloatingButtonStyle(
                        type: .secondary,
                        size: .mini,
                        foregroundColor: .white,
                        backgroundColor: .secondaryColor
                    )
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.backgroundColor)
    }
}
