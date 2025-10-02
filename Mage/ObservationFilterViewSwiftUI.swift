//
//  ObservationFilterViewSwiftUI.swift
//  MAGE
//
//  Created by Daniel Benner on 9/30/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Combine

@objc class ObservationFilterViewUIHostingFactory: NSObject {
    @objc static func makeViewController() -> UIViewController {
        return UIHostingController(rootView: ObservationFilterView())
    }
}

struct ObservationFilterView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject
    var viewModel: ObservationFilterviewModel
    
    @State var isSelected: Bool = false
    @State var searchText: String = ""
    
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
                    ForEach(0...10, id: \.self) { user in
                        UserObservationCellView(isSelected: $isSelected)
                            .padding(.vertical, 8)
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
    @Binding var isSelected: Bool
    var body: some View {
        HStack {
            Image(.iconWBackground)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text("James McDougall")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("@jmcdougall")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "checkmark.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .onTapGesture {
            isSelected.toggle()
        }
    }
}

#Preview {
    let userOne = UserModel(userId: nil, remoteId: nil, name: "Dan Benner", coordinate: nil, email: nil, phone: nil, lastUpdated: nil, avatarUrl: nil, username: "dbenner", timestamp: nil, hasEditPermissions: true, cllocation: nil)
    let userTwo = UserModel(userId: nil, remoteId: nil, name: "James McDougall", coordinate: nil, email: nil, phone: nil, lastUpdated: nil, avatarUrl: nil, username: "jmcdougall", timestamp: nil, hasEditPermissions: true, cllocation: nil)
    
    var previewModel = ObservationFilterviewModel(
        users: [])
    ObservationFilterView()
}
