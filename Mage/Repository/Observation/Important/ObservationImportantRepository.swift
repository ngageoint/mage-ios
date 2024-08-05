//
//  ObservationImportantRepository.swift
//  MAGE
//
//  Created by Dan Barela on 8/5/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct ObservationImportantRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationImportantRepository = ObservationImportantRepository()
}

extension InjectedValues {
    var observationImportantRepository: ObservationImportantRepository {
        get { Self[ObservationImportantRepositoryProviderKey.self] }
        set { Self[ObservationImportantRepositoryProviderKey.self] = newValue }
    }
}


class ObservationImportantRepository: ObservableObject {
    @Injected(\.observationImportantLocalDataSource)
    var localDataSource: ObservationImportantLocalDataSource
    
    @Injected(\.observationImportantRemoteDataSource)
    var remoteDataSource: ObservationImportantRemoteDataSource
    
    var pushingImportant: [String : ObservationImportantModel] = [:]
    var cancellables: Set<AnyCancellable> = Set()
    
    init() {
        localDataSource.pushSubject?.sink(receiveValue: { important in
            Task { [weak self] in
                await self?.pushImportant(importants: [important])
            }
        })
        .store(in: &cancellables)
    }
    
    func sync() {
        Task { [weak self] in
            await self?.pushImportant(importants:self?.localDataSource.getImportantsToPush())
        }
    }
    
    func observeObservationImportant(observationUri: URL?) -> AnyPublisher<[ObservationImportantModel?], Never>? {
        localDataSource.observeObservationImportant(observationUri: observationUri)
    }
    
    func flagImportant(observationUri: URL?, reason: String) {
        localDataSource.flagImportant(observationUri: observationUri, reason: reason)
    }
    
    func removeImportant(observationUri: URL?) {
        localDataSource.removeImportant(observationUri: observationUri)
    }
    
    func pushImportant(importants: [ObservationImportantModel]?) async {
        guard let importants = importants else {
            return
        }

        // only push important changes that haven't already been told to be pushed
        var importantsToPush: [String : ObservationImportantModel] = [:]
        for important in importants {
            if let observationRemoteId = important.observationRemoteId,
               pushingImportant[observationRemoteId] == nil
            {
                NSLog("adding important to push \(observationRemoteId)")
                pushingImportant[observationRemoteId] = important
                importantsToPush[observationRemoteId] = important
            }
        }
        
        NSLog("about to push an additional \(importantsToPush.count) importants")
        for (observationId, important) in importantsToPush {
            let response = await remoteDataSource.pushImportant(important: important)
            localDataSource.handleServerPushResponse(important: important, response: response)
            self.pushingImportant.removeValue(forKey: observationId)
        }
    }
}
