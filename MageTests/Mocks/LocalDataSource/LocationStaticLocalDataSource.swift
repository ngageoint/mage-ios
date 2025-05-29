//
//  LocationStaticLocalDataSource.swift
//  MAGETests
//
//  Created by Dan Barela on 8/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class LocationStaticLocalDataSource: LocationLocalDataSource {
    var locationModels: [LocationModel] = []
    
    func getLocation(uri: URL) async -> MAGE.LocationModel? {
        locationModels.first { model in
            model.locationUri == uri
        }
    }
    
    func locations(userIds: [String]?, paginatedBy paginator: MAGE.Trigger.Signal?) -> AnyPublisher<[MAGE.URIItem], any Error> {
        AnyPublisher(Just(locationModels.compactMap{ model in
            model.locationUri
        }.map { userId in
            URIItem.listItem(userId)
        }).setFailureType(to: Error.self))
    }
    
    var subjectMap: [URL : CurrentValueSubject<LocationModel, Never>] = [:]
    func observeLocation(locationUri: URL) -> AnyPublisher<MAGE.LocationModel, Never>? {
        if let location = locationModels.first(where: { model in
            model.locationUri == locationUri
        }) {
            let subject = CurrentValueSubject<LocationModel, Never>(location)
            subjectMap[locationUri] = subject
            return AnyPublisher(subject)
        } else {
            return nil
        }
    }
    
    func updateLocation(locationUri: URL, model: LocationModel) {
        locationModels.removeAll { model in
            model.locationUri == locationUri
        }
        locationModels.append(model)
        if let subject = subjectMap[locationUri] {
            subject.send(model)
        }
    }
    
    var latestSubject: CurrentValueSubject<Date, Never> = CurrentValueSubject(Date(timeIntervalSince1970: 0))
    
    func observeLatestFiltered() -> AnyPublisher<Date, Never>? {
        return AnyPublisher(latestSubject)
    }
    
    func setLatest(date: Date = Date()) {
        latestSubject.send(date)
    }
    
    
}
