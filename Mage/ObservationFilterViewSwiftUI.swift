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

@objc class ObservationFilterViewUIHostingFactory: NSObject {
    @objc static func makeViewController() -> UIViewController {
        return UIHostingController(rootView: ObservationFilterView())
    }
}

struct ObservationFilterView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject
    var viewModel: ObservationFilterviewModel
    
    @State private var selectedItems: Set<User> = []
    @State var searchText: String = "" // TODO: not working
    
    init(viewModel: ObservationFilterviewModel = .init()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        if viewModel.users.isEmpty {
            VStack {
                Text("Users not found in CoreData")
            }
        } else {
            NavigationStack {
                ScrollView {
                    LazyVStack(alignment:.leading) {
                        ForEach(Array(viewModel.users), id: \.self) { user in
                            UserObservationCellView(selectedItems: $selectedItems, user: user)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search")
                .navigationTitle("Search Users")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(colorScheme, for: .navigationBar)
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct UserObservationCellView: View {
    @Binding var selectedItems: Set<User>
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
                Text(user.name ?? "unknown")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(user.remoteId ?? "unknown")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: selectedItems.contains(user) ? "checkmark" : "")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .onTapGesture {
            if selectedItems.contains(user) {
                selectedItems.remove(user)
            } else {
                selectedItems.insert(user)
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
//    
//    ObservationFilterView(viewModel: ObservationFilterviewModel(users: users))
}
