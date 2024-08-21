//
//  LocationList.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import MaterialViews

struct LocationList: View {
    @StateObject var viewModel: LocationsViewModel = LocationsViewModel()
    
    @EnvironmentObject
    var router: MageRouter
        
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
                    Text("Loading Users")
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
                List(rows) { item in
                    switch item {
                    case .listItem(let uri):
                        LocationSummaryView(viewModel: LocationSummaryViewModel(uri: uri))
                            .frame(maxWidth: .infinity)
                            .background(Color.surfaceColor)
                            .card()
                            .onAppear {
                                if rows.last == item {
                                    viewModel.loadMore()
                                }
                            }
                        .onTapGesture {
                            router.path.append(UserRoute.userFromLocation(locationUri: uri))
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
                            Image(systemName: "figure.wave")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 200, maxHeight: 200)
                                .padding([.trailing, .leading], 24)
                                .foregroundColor(Color.onSurfaceColor.opacity(0.45))
                            Spacer()
                        }
                        Text("No Locations")
                            .font(.headline4)
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                        Text("No users have reported their location within your configured time filter for this event.")
                            .font(.body1)
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                        Button {
                            router.path.append(MageRoute.locationFilter)
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
        .navigationTitle(DataSources.user.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundColor)
        .foregroundColor(Color.onSurfaceColor)
        .onAppear {
            viewModel.fetchLocations()
        }
    }
}
