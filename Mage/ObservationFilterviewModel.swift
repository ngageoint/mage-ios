//
//  ObservationFilterviewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/2/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Combine

class ObservationFilterviewModel: ObservableObject {
    @Injected(\.userRepository)
    var userRepository: UserRepository
    var cancellable: Set<AnyCancellable> = Set()
    
    @Published var users: [URIItem] = []
    
    //TODO Filter Users Logic
    
    init(users: [URIItem] = []) {
        self.users = users
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
