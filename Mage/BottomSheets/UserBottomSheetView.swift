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
                    .padding(8)
                }
                .id(user.remoteId)
                .ignoresSafeArea()
            }
        }
        .animation(.default, value: self.viewModel.user != nil)
    }
}
