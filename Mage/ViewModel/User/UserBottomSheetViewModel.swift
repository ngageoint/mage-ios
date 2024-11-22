//
//  UserBottomSheetViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

class UserBottomSheetViewModel: ObservableObject {
    @Injected(\.userRepository)
    var repository: UserRepository
    
    var disposables = Set<AnyCancellable>()
    
    @Published
    var user: UserModel?
    
    var userUri: URL?
    
    init(userUri: URL?) {
        self.userUri = userUri
        repository.observeUser(userUri: userUri)?
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] updatedObject in
                self?.user = updatedObject
            })
            .store(in: &disposables)
    }
}
