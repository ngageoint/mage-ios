//
//  ObservationFilterViewSwiftUI.swift
//  MAGE
//
//  Created by Daniel Benner on 9/30/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

@objc class ObservationFilterViewUIHostingFactory: NSObject {
    @objc static func makeViewController() -> UIViewController {
        return UIHostingController(rootView: ObservationFilterView())
    }
}

struct ObservationFilterView: View {
    @StateObject
    var viewModel = ObservationFilterviewModel()
    
    var body: some View {
        if viewModel.users.isEmpty {
            VStack {
                Text("Users not found in CoreData")
            }
        } else {
            LazyVStack {
                ForEach(viewModel.users, id: \.self) { user in
                    Text(user.id)
                }
            }
        }
    }
}

class ObservationFilterviewModel: ObservableObject {
    @Injected(\.userRepository)
    var userRepository: UserRepository
    var cancellable: Set<AnyCancellable> = Set()
    
    @Published var users: [URIItem] = []
    
    //TODO Filter Users Logic
    
    init() {
        self.userRepository.users(paginatedBy: nil)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error fetching users: \(error)")
                    }
                },
                receiveValue: { [weak self] users in
                    self?.users = users
                }
            )
            .store(in: &cancellable)
    }
}


