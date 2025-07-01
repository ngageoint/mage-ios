//
//  LocationList.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

class LocationListWrapperViewController: SwiftUIViewController {
    let router: MageRouter
    var scheme: AppContainerScheming?
    var viewModel: LocationsViewModel
    
    init(userRemoteIds: [String]? = nil, scheme: AppContainerScheming?, router: MageRouter) {
        self.router = router
        self.scheme = scheme
        self.viewModel = LocationsViewModel(userIds: userRemoteIds)
        super.init()
        swiftUIView = AnyView( LocationList(
            viewModel: self.viewModel
        )
            .environmentObject(router)
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
}

struct LocationList: View {
    @StateObject var viewModel: LocationsViewModel = LocationsViewModel()
    
    @EnvironmentObject
    var router: MageRouter
    
    var body: some View {
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
            EmptyStateList(
                data: rows,
                rowContent: { item in
                    switch item {
                    case .listItem(let uri):
                        ObservationSummaryViewSwiftUI(
                            viewModel: ObservationListViewModel(uri: uri)
                        )
                        .onAppear {
                            if rows.last == item {
                                viewModel.loadMore()
                            }
                        }
                        .onTapGesture {
                            router.appendRoute(ObservationRoute.detail(uri: uri))
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.backgroundColor)
                        
                    case .sectionHeader:
                        EmptyView()
                    }
                },
                placeholder: {
                    VStack(alignment: .center, spacing: 16) {
                        HStack {
                            Spacer()
                            Image("outline_not_listed_location")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 200, maxHeight: 200)
                                .padding(.horizontal, 24)
                                .foregroundColor(Color.onSurfaceColor.opacity(0.45))
                            Spacer()
                        }
                        Text("No Observations")
                            .font(.headline4)
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                            .multilineTextAlignment(.center)
                        Text("This user has not submitted any observations for this event.")
                            .font(.body1)
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                    }
                    .padding(64)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.backgroundColor)
                }
            )
            .transition(.opacity)
        case let .failure(error: error):
            Text(error.localizedDescription)
        }
        
//            .navigationTitle(DataSources.user.fullName)
//            .navigationBarTitleDisplayMode(.inline)
//            .background(Color.backgroundColor)
//            .foregroundColor(Color.onSurfaceColor)
//            .onAppear {
//                viewModel.fetchLocations()
//            }
    }
}
