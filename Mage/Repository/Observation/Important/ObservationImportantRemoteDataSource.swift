//
//  ObservationImportantRemoteDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 8/5/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct ObservationImportantRemoteDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationImportantRemoteDataSource = ObservationImportantRemoteDataSource()
}

extension InjectedValues {
    var observationImportantRemoteDataSource: ObservationImportantRemoteDataSource {
        get { Self[ObservationImportantRemoteDataSourceProviderKey.self] }
        set { Self[ObservationImportantRemoteDataSourceProviderKey.self] = newValue }
    }
}

class ObservationImportantRemoteDataSource {
    
    func pushImportant(important: ObservationImportantModel) async -> [AnyHashable: Any] {
        guard let eventId = important.eventId,
              let observationRemoteId = important.observationRemoteId
        else {
            return [:]
        }
        
        let request: ObservationImportantService = {
            if important.important {
                return ObservationImportantService.pushImportant(
                    eventId: eventId,
                    observationRemoteId: observationRemoteId,
                    reason: important.reason
                )
            } else {
                return ObservationImportantService.deleteImportant(
                    eventId: eventId,
                    observationRemoteId: observationRemoteId
                )
            }
        }()
        
        return await withCheckedContinuation { continuation in
            MageSession.shared.session.request(request)
                .validate(MageSession.shared.validateMageResponse)
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            let json = try JSONSerialization.jsonObject(with: data)
                            if let json = json as? [AnyHashable: Any] {
                                continuation.resume(returning: json)
                            }
                        } catch {
                            print("Error while decoding response: \(error) from: \(String(data: data, encoding: .utf8) ?? "empty")")
                            continuation.resume(returning: [:])
                        }
                    case .failure(let error):
                        print("Error \(error)")
                        continuation.resume(returning: [:])
                    }
                }
        }
    }
}
