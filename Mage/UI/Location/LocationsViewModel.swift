//
//  LocationsViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class LocationsViewModel: ObservableObject {
    @Injected(\.locationRepository)
    var repository: LocationRepository
    
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
    
    @Published private(set) var state: State = .loading
    @Published var userIds: [URL] = []
    @Published var loaded: Bool = false
    private var disposables = Set<AnyCancellable>()
        
    private let trigger = Trigger()
    private enum TriggerId: Hashable {
        case reload
        case loadMore
    }
    
    init() {
        repository.refreshPublisher?
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.reload()
            })
            .store(in: &disposables)
        
        repository.observeLatest()?
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] count in
                guard let self = self else { return }
                self.reload()
            })
            .store(in: &disposables)
    }
    
    func reload() {
        trigger.activate(for: TriggerId.reload)
    }
    
    func loadMore() {
        trigger.activate(for: TriggerId.loadMore)
    }
    
    func fetchLocations(limit: Int = 100) {
        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, repository] in
            repository.locations(
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
