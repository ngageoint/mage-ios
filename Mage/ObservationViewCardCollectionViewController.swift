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
    
    var showFavorites: (_ favoritesModel: ObservationFavoritesModel?) -> Void
    var moreActions: () -> Void
    var editObservation: (_ observationUri: URL) -> Void
    var selectedAttachment: (_ attachmentUri: URL) -> Void
    var selectedUnsentAttachment: (_ localPath: String, _ contentType: String) -> Void
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    ObservationHeaderViewSwiftUI(
                        viewModel: viewModel,
                        showFavorites: showFavorites,
                        moreActions: moreActions
                    )
                    
                    Text("Forms")
                        .overlineText()
                        .padding()
                    ForEach(viewModel.observationForms ?? []) { form in
                        ObservationFormViewSwiftUI(
                            viewModel: ObservationFormViewModel(form: form),
                            selectedAttachment: selectedAttachment,
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
                        if let observationUri = viewModel.observationModel?.observationId {
                            editObservation(observationUri)
                        }
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
