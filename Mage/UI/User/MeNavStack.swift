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
            
            let controller = MageHostingController(
                rootView: UserViewSwiftUI(
                    viewModel: self.viewModel!
                    )
                    .environmentObject(router)
            )
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(controller.view)
            controller.didMove(toParent: self)
            
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                controller.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
    }
}
