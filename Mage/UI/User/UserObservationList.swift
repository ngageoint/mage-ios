//
//  UserObservationList.swift
//  MAGE
//
//  Created by Dan Barela on 8/9/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct UserObservationList: View {
    @ObservedObject
    var viewModel: UserViewViewModel
    
    @EnvironmentObject
    var router: MageRouter

    var body: some View {
        switch(viewModel.state) {
        case .loaded(let rows):
            ForEach(rows) { uriItem in
                switch uriItem {
                case .listItem(let uri):
                    ObservationSummaryViewSwiftUI(
                        viewModel: ObservationListViewModel(uri: uri)
                    )
                    .onAppear {
                        if rows.last == uriItem {
                            viewModel.loadMore()
                        }
                    }
                    .onTapGesture {
                        router.appendRoute(ObservationRoute.detail(uri: uri))
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.backgroundColor)
                case .sectionHeader(_):
                    EmptyView()
                }
            }

            .emptyPlaceholder(rows) {
                VStack(alignment: .center, spacing: 16) {
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                        Image("outline_not_listed_location")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .padding([.trailing, .leading], 24)
                            .foregroundColor(Color.onSurfaceColor.opacity(0.45))
                        Spacer()
                    }
                    Text("No Observations")
                        .font(.headline4)
                        .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                    Text("This user has not submitted any observations for this event.")
                        .font(.body1)
                        .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                }
                .padding(64)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundColor)
            }
            .transition(AnyTransition.opacity)
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
        case .failure(let error):
            Text(error.localizedDescription)
        }
    }
}
