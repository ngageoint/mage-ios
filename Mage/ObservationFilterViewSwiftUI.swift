//
//  ObservationFilterViewSwiftUI.swift
//  MAGE
//
//  Created by Daniel Benner on 9/30/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Combine
import Kingfisher

// allows the crossover from objc to swift
@objc class ObservationFilterViewUIHostingFactory: NSObject {
    @objc static func makeViewController() -> UIViewController {
        return UIHostingController(rootView: ObservationFilterView())
    }
}

struct ObservationFilterView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel = ObservationFilterviewModel()
    
    //    init(viewModel: ObservationFilterviewModel = .init()) {
    //        self.viewModel = viewModel
    //    }
    
    var body: some View {
        if (viewModel.users.isEmpty) {
            VStack {
                VStack(spacing: 8) {
                    Image(systemName: "person.3")
                        .font(.system(size: 36, weight: .medium))
                        .padding(.bottom, 4)
                    Text("No users have created observations for this event. Please have a user create an observation to find observations by user here.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        } else {
            NavigationStack {
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
                            ForEach(Array(viewModel.filteredUsers), id: \.self) { user in
                                UserObservationCellView(viewModel: viewModel, user: user)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .searchable(text: $viewModel.searchText, prompt: "Search")
                .navigationTitle("User Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(colorScheme, for: .navigationBar)
                .scrollIndicators(.hidden)
                .listRowSeparator(.visible)
            }
        }
    }
}

struct UserObservationCellView: View {
    @ObservedObject var viewModel: ObservationFilterviewModel
    var user: User
    var body: some View {
        HStack {
            if let url = URL(string: user.avatarUrl ?? "") {
                KFImage(url)
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                    .forceRefresh()
                    .cacheOriginalImage()
                    .onlyFromCache(!DataConnectionUtilities.shouldFetchAttachments())
                    .placeholder {
                        Image(systemName: "person.crop.square")
                            .symbolRenderingMode(.monochrome)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                    }
                
                    .fade(duration: 0.3)
                    .resizable()
                    .scaledToFill()
                    .frame(idealWidth: 48, maxWidth: 48, idealHeight: 48, maxHeight: 48)
                    .clipShape(.circle)
            }
            VStack(alignment: .leading) {
                Text(user.name ?? "")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(user.username ?? "")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: viewModel.selectedUsers.contains(user.remoteId ?? "") ? "checkmark" : "")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .onTapGesture {
            if let remoteId = user.remoteId {
                viewModel.updateSelectedUsers(remoteId: remoteId)
            }
        }
    }
}

#Preview {
    //    let one = User()
    //    one.name = "dbenner"
    //    one.remoteId = "1"
    //    let two = User()
    //    two.name = "jmcdougall"
    //    two.remoteId = "2"
    //
    //    let users: [User] = [one, two]
    
    ObservationFilterView(viewModel: ObservationFilterviewModel())
}
