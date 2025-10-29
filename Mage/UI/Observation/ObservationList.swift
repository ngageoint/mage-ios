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
    @EnvironmentObject var router: MageRouter
    // We need to get the "context" from our "persistence" object
    @Injected(\.persistence) var persistence: Persistence

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingView
            case let .loaded(rows: rows):
                loadedView(rows: rows)
            case let .failure(error: error):
                Text(error.localizedDescription)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.currentUserCanEdit {
                fabButton
            }
        }
        .navigationTitle(DataSources.observation.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundColor)
        .foregroundColor(Color.onSurfaceColor)
        .onAppear {
            viewModel.reload()
        }
    }

    // MARK: - Loading View

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

    // MARK: - Loaded View

    @ViewBuilder
    private func loadedView(rows: [ObservationItem]) -> some View {
        ScrollViewReader { proxy in
            List(rows) { uriItem in
                rowView(uriItem: uriItem, rows: rows)
            }
            .listStyle(.plain)
            .listSectionSeparator(.hidden)
            .emptyPlaceholder(rows) {
                emptyPlaceholderView
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private func rowView(uriItem: ObservationItem, rows: [ObservationItem]) -> some View {
        switch uriItem {
        case .listItem(let uri):
            // Convert URL to NSManagedObjectID
            if let objectID = persistence.getContext().persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) {
                ObservationSummaryViewSwiftUI(
                    viewModel: ObservationListViewModel(observationObjectID: objectID, context: persistence.getContext())
                )
                .onAppear {
                    if rows.first == uriItem {
                        viewModel.setFirstRowVisible(visible: true)
                    }
                    if rows.last == uriItem {
                        viewModel.loadMore()
                    }
                }
                .onDisappear {
                    if rows.first == uriItem {
                        viewModel.setFirstRowVisible(visible: false)
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.backgroundColor)
            } else {
                // fallback/error view
                EmptyView()
            }
        case .sectionHeader(_):
            EmptyView()
        }
    }

    // MARK: - Placeholder

    private var emptyPlaceholderView: some View {
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
            Text("No observations have been submitted within your configured time filter for this event.")
                .font(.body1)
                .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            Button {
                router.appendRoute(MageRoute.observationFilter)
            } label: {
                Label {
                    Text("Adjust Filter")
                } icon: {
                    // (Add icon here if you want)
                }
                .padding([.leading, .trailing], 16)
            }
            .buttonStyle(MaterialButtonStyle(type: .contained))
        }
        .padding(64)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceColor)
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Button {
            router.appendRoute(ObservationRoute.create)
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
