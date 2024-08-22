//
//  MeNavStack.swift
//  MAGE
//
//  Created by Dan Barela on 8/21/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class MeNavStack: MageNavStack {
    var viewModel: UserViewViewModel?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = userRepository.getCurrentUser(), let userUri = user.userId {
            self.viewModel = UserViewViewModel(uri: userUri)
            
            self.viewModel?.$user.receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] userModel in
                    if let name = userModel?.name {
                        self?.title = name
                    }
                })
                .store(in: &cancellables)
            
            let svc = SwiftUIViewController(
                swiftUIView: UserViewSwiftUI(
                    viewModel: self.viewModel!
                    )
                    .environmentObject(router)
            )
            self.view.addSubview(svc.view)
        }
    }
}
