//
//  ObservationsViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

enum ObservationItem: Hashable, Identifiable {
    var id: String {
        switch self {
        case .listItem(let observationId):
            return observationId.absoluteString
        case .sectionHeader(let header):
            return header
        }
    }

    case listItem(_ observationId: URL)
    case sectionHeader(header: String)
}

class ObservationsViewModel: ObservableObject {
    @Injected(\.observationRepository)
    var repository: ObservationRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    @Published private(set) var state: State = .loading
    @Published var observationIds: [URL] = []
    @Published var loaded: Bool = false
    private var disposables = Set<AnyCancellable>()
    
    var currentUserCanEdit: Bool {
        self.currentUser?.hasEditPermission ?? false
    }
    
    lazy var currentUser: User? = {
        userRepository.getCurrentUser()
    }()
    
    var publisher: AnyPublisher<CollectionDifference<ObservationModel>, Never>?
    
    private let trigger = Trigger()
    
    enum State {
        case loading
        case loaded(rows: [ObservationItem])
        case failure(error: Error)
        
        fileprivate var rows: [ObservationItem] {
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
    
    func fetchObservations(limit: Int = 100) {
        if publisher != nil {
            return
        }
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, repository] in
            repository.observations(
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
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
