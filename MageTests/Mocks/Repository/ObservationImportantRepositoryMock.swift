//
//  ObservationImportantRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

@testable import MAGE

class ObservationImportantRepositoryMock: ObservationImportantRepository {
    var syncCalled = false
    func sync() {
        syncCalled = true
    }
    var observationSubjectMap: [URL : CurrentValueSubject<[ObservationImportantModel?], Never>] = [:]
    func observeObservationImportant(observationUri: URL?) -> AnyPublisher<[MAGE.ObservationImportantModel?], Never>? {
        let subject = CurrentValueSubject<[ObservationImportantModel?], Never>([importants[observationUri!]])
        observationSubjectMap[observationUri!] = subject
        return AnyPublisher(subject)
    }
    var importants: [URL: ObservationImportantModel] = [:]
    
    func updateObservationImportant(observationUri: URL, model: ObservationImportantModel?) {
        importants[observationUri] = model
        if let subject = observationSubjectMap[observationUri] {
            subject.send([model])
        }
    }
    
    var flagImportantUri: URL?
    var flagImportantReason: String?
    func flagImportant(observationUri: URL?, reason: String) {
        flagImportantReason = reason
        flagImportantUri = observationUri
        
        if let originalImportant = importants[observationUri!] {
            updateObservationImportant(
                observationUri: observationUri!,
                model: ObservationImportantModel(
                    important: true,
                    userId: UserDefaults.standard.currentUserId,
                    reason: reason,
                    observationRemoteId: originalImportant.observationRemoteId,
                    importantUri: originalImportant.importantUri,
                    eventId: originalImportant.eventId
                )
            )
        } else {
            Task {
                @Injected(\.observationRepository)
                var repo: ObservationRepository
                let observation = await repo.getObservation(observationUri: observationUri)
                let eventId:NSNumber? = {
                    if let eventId = observation?.eventId {
                        return NSNumber(value: eventId)
                    }
                    return nil
                }()
                updateObservationImportant(
                    observationUri: observationUri!,
                    model: ObservationImportantModel(
                        important: true,
                        userId: UserDefaults.standard.currentUserId,
                        reason: reason,
                        observationRemoteId: observation?.remoteId,
                        importantUri: URL(string:"magetest://important/100")!,
                        eventId: eventId
                    )
                )
            }
        }
    }
    
    var removeImportantUri: URL?
    func removeImportant(observationUri: URL?) {
        removeImportantUri = observationUri
        updateObservationImportant(observationUri: observationUri!, model: nil)
        
    }
    
    var pushImportantModels: [ObservationImportantModel]?
    func pushImportant(importants: [MAGE.ObservationImportantModel]?) async {
        pushImportantModels = importants
    }
}
