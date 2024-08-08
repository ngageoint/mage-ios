//
//  ObservationList.swift
//  MAGE
//
//  Created by Dan Barela on 8/6/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import MAGEStyle
import MaterialViews

struct ObservationList: View {
    @StateObject var viewModel: ObservationsViewModel = ObservationsViewModel()

    @State var sortOpen: Bool = false
    @State var filterOpen: Bool = false
    var selectedAttachment: (_ attachmentUri: URL) -> Void
    var selectedObservation: (_ observationUri: URL) -> Void
    var createNew: () -> Void
    var launchFilter: () -> Void
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                VStack(alignment: .center, spacing: 16) {
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                        Image("marker_large")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200)
                            .padding([.trailing, .leading], 24)
                            .foregroundColor(Color.onSurfaceColor.opacity(0.45))
                        Spacer()
                    }
                    Text("Loading Observations")
                        .font(.headline4)
                        .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                    ProgressView()
                        .tint(Color.primaryColorVariant)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundColor)
                .transition(AnyTransition.opacity)
            case let .loaded(rows: rows):
                    List(rows) { asamItem in
                        switch asamItem {
                        case .listItem(let uri):
                            VStack {
                                ObservationSummaryViewSwiftUI(
                                    viewModel: ObservationListViewModel(uri: uri),
                                    selectedAttachment: selectedAttachment
                                )
                            }
                            .onTapGesture {
                                selectedObservation(uri)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.backgroundColor)
                        case .sectionHeader(_):
                            EmptyView()
                        }
                        
                    }
                    .listStyle(.plain)
                    .listSectionSeparator(.hidden)
                    .emptyPlaceholder(rows) {
                        VStack(alignment: .center, spacing: 16) {
                            HStack(alignment: .center, spacing: 0) {
                                Spacer()
                                Image("outline_not_listed_location")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 200)
                                    .padding([.trailing, .leading], 24)
                                    .foregroundColor(Color.onSurfaceColor.opacity(0.45))
                                Spacer()
                            }
                            Text("No Observations")
                                .font(.headline4)
                                .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                            Text("No observations have been submitted within your configured time filter for this event.")
                                .font(.body1)
                                .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 8)
                            Button {
                                launchFilter()
                            } label: {
                                Label {
                                    Text("Adjust Filter")
                                } icon: {
                                    
                                }
                                .padding([.leading, .trailing], 16)

                            }
                            .buttonStyle(MaterialButtonStyle(type: .contained))

                        }
                        .padding(64)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfaceColor)
                    }
                    .transition(AnyTransition.opacity)
                
            case let .failure(error: error):
                Text(error.localizedDescription)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.currentUserCanEdit {
                Button {
                    createNew()
                } label: {
                    Label {
                        Text("")
                    } icon: {
                        Image("add_location")
                            .resizable()
                            .scaledToFit()
                    }
                    
                }
                .fixedSize()
                .buttonStyle(
                    MaterialFloatingButtonStyle(
                        type: .secondary,
                        size: .regular,
                        foregroundColor: .white,
                        backgroundColor: .secondaryColor
                    )
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(DataSources.observation.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundColor)
        .foregroundColor(Color.onSurfaceColor)
        .onAppear {
            viewModel.fetchObservations()
        }
    }
}
