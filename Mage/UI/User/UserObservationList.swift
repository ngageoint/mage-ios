//
//  UserObservationList.swift
//  MAGE
//
//  Created by Dan Barela on 8/9/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import CoreData

struct UserObservationList: View {
    @ObservedObject
    var viewModel: UserViewViewModel
    
    @EnvironmentObject
    var router: MageRouter

    var body: some View {
        switch viewModel.state {
        case .loaded(let rows):
            loadedView(rows: rows)
        case .loading:
            loadingView
        case .failure(let error):
            Text(error.localizedDescription)
        }
    }

    @ViewBuilder
    private func loadedView(rows: [URIItem]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if rows.isEmpty {
                    emptyPlaceholder
                } else {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { idx, item in
                        UserObservationRow(
                            item: item,
                            isLast: idx == rows.count - 1,
                            viewModel: viewModel,
                            router: router
                        )
                    }
                }
            }
            .background(Color.backgroundColor)
        }
        .transition(.opacity)
    }

    private var emptyPlaceholder: some View {
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
    
    private var loadingView: some View {
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
        .transition(.opacity)
    }
}

struct UserObservationRow: View {
    let item: URIItem
    let isLast: Bool
    let viewModel: UserViewViewModel
    let router: MageRouter

    // We need to get the "context" from our "persistence" object
    @Injected(\.persistence) var persistence: Persistence

    var body: some View {
        switch item {
        case .listItem(let uri):
            let _ = print("\n-----------------------------------")
            let _ = debugPrint(uri)
            let _ = debugPrint(persistence.getContext())
            let _ = print("-----------------------------------\n")
            
            if let coordinator = persistence.getContext().persistentStoreCoordinator,
               let objectID = coordinator.managedObjectID(forURIRepresentation: uri) {
                ObservationSummaryViewSwiftUI(
                    viewModel: ObservationListViewModel(observationObjectID: objectID, context: persistence.getContext())
                )
                .onAppear {
                    if isLast {
                        viewModel.loadMore()
                    }
                }
                .onTapGesture {
                    router.appendRoute(ObservationRoute.detail(uri: uri))
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.backgroundColor)
            } else {
                // Fallback view if objectID cannot be resolved
                Text("Unable to load observation")
            }
        case .sectionHeader(_):
            EmptyView()
        }
    }
}
