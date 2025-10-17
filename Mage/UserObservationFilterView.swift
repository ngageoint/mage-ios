//
//  UserObservationFilterView.swift
//  MAGE
//
//  Created by James McDougall on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Combine
import Kingfisher

@objc class UserObservationFilterViewUIHostingFactory: NSObject {
    @objc static func makeViewController() -> UIViewController {
        return UIHostingController(rootView: UserObservationFilterView())
    }
}

struct UserObservationFilterView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel = UserObservationFilterViewModel()
    @State var isSelected: Bool = false
    
    init() {
        let searchBarAppearance = UISearchBar.appearance()
        searchBarAppearance.backgroundColor = UIColor.systemBackground
    }
    
    var body: some View {
        if (viewModel.users.isEmpty) {
            VStack {
                VStack(spacing: 8) {
                    Image(systemName: "person.3")
                        .font(.system(size: 36, weight: .medium))
                        .padding(.bottom, 4)
                    Text("No users have created observations for this event.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        } else {
            ScrollView {
                if viewModel.filteredUsers.isEmpty && !viewModel.searchText.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36, weight: .medium))
                            .padding(.bottom, 4)
                        Text("No matches for “\(viewModel.searchText)”")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    LazyVStack(alignment:.leading) {
                        ForEach(Array(viewModel.filteredUsers), id: \.remoteId) { user in
                            UserObservationCellView(viewModel: viewModel, isSelected: $isSelected, user: user)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search for Users")
            .navigationTitle(viewModel.selectedUsers.count > 0 ? "\(viewModel.selectedUsers.count) Users Selected" : "Select Users")
            .navigationBarTitleDisplayMode(.inline)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.clearSelectedUsers() }
                    } label: {
                        Text("Clear")
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct UserObservationCellView: View {
    
    @ObservedObject var viewModel: UserObservationFilterViewModel
    @Binding var isSelected: Bool
    var user: User
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                if let url = URL(string: user.avatarUrl ?? "") {
                    KFImage(url)
                        .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                        .cacheOriginalImage()
                        .onlyFromCache(DataConnectionUtilities.shouldFetchAttachments())
                        .fade(duration: 0.3)
                        .resizable()
                        .scaledToFill()
                        .frame(idealWidth: 48, maxWidth: 48, idealHeight: 48, maxHeight: 48)
                        .clipShape(.circle)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(idealWidth: 48, maxWidth: 48, idealHeight: 48, maxHeight: 48)
                        .clipShape(.circle)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    Text(user.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack {
                        Text("@") +
                        Text(user.username ?? "")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: viewModel.selectedUsers.contains(user.remoteId ?? "") ? "checkmark.circle.fill" : "")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.gradientDarkBlue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .onTapGesture {
                if let remoteId = user.remoteId {
                    viewModel.updateSelectedUsers(remoteId: remoteId)
                }
            }
            .contentShape(Rectangle())
            Divider()
        }
    }
}

#Preview {
    UserObservationFilterView()
}
