//
//  UserViewViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/9/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class UserViewViewModel: ObservableObject {
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Published
    var user: UserModel?
    
    var currentUserIsMe: Bool {
        UserDefaults.standard.currentUserId == user?.remoteId
    }
    
    @Published private(set) var state: State = .loading
    @Published var loaded: Bool = false
    private var disposables = Set<AnyCancellable>()
    
    private let trigger = Trigger()
    
    enum State {
        case loading
        case loaded(rows: [URIItem])
        case failure(error: Error)
        
        fileprivate var rows: [URIItem] {
            if case let .loaded(rows: rows) = self {
                return rows
            } else {
                return []
            }
        }
    }
    
    private enum TriggerId: Hashable {
        case reload
        case loadMore
    }
    
    func reload() {
        trigger.activate(for: TriggerId.reload)
    }
    
    func loadMore() {
        trigger.activate(for: TriggerId.loadMore)
    }
    
    var uri: URL
    
    init(uri: URL) {
        self.uri = uri
        
        userRepository.observeUser(userUri: uri)?
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assign(to: &$user)
    }
    
    func fetchObservations(limit: Int = 100) {
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, observationRepository, uri] in
            observationRepository.userObservations(
                userUri: uri,
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { existing, new in
                (existing + new).uniqued() // NOTE: this is a band-aid to fix duplicates issue #1370
            }
            .map { State.loaded(rows: $0) }
            .catch { error in
                return Just(State.failure(error: error))
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] recieve in
            guard let self = self else { return }
            switch(self.state, recieve) {
            case (.loaded, .loaded):
                self.state = recieve
            default:
                withAnimation(.easeIn(duration: 1.0)) {
                    self.state = recieve
                }
            }
        }
        .store(in: &disposables)
    }
}
