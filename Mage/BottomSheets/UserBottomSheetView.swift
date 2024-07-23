//
//  UserBottomSheetController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import MaterialViews

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
            .sink(receiveValue: { updatedObject in
                self.user = updatedObject
            })
            .store(in: &disposables)
    }
}

struct UserBottomSheet: View {
    @ObservedObject
    var viewModel: UserBottomSheetViewModel
    
    var body: some View {
        Group {
            if let user = viewModel.user {
                VStack(spacing: 0) {
                    
                    UserSummary(
                        timestamp: user.timestamp,
                        name: user.name,
                        avatarUrl: user.avatarUrl
                    )
                    
                    UserBottomSheetActionBar(
                        coordinate: user.coordinate,
                        email: user.email,
                        phone: user.phone,
                        navigateToAction: CoordinateActions.navigateTo(
                            coordinate: user.coordinate,
                            itemKey: user.userId?.absoluteString,
                            dataSource: DataSources.user
                        )
                    )
                    Button {
                        // let the ripple dissolve before transitioning otherwise it looks weird
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: .ViewUser, object: user.userId)
                        }
                    } label: {
                        Text("More Details")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MaterialButtonStyle(type: .contained))
                    .padding(8)
                }
                .id(user.remoteId)
                .ignoresSafeArea()
            }
        }
        .animation(.default, value: self.viewModel.user != nil)
    }
}
