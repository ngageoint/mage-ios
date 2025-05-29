//
//  ObservationFavoriteRemoteDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 8/6/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct ObservationFavoriteRemoteDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationFavoriteRemoteDataSource = ObservationFavoriteRemoteDataSource()
}

extension InjectedValues {
    var observationFavoriteRemoteDataSource: ObservationFavoriteRemoteDataSource {
        get { Self[ObservationFavoriteRemoteDataSourceProviderKey.self] }
        set { Self[ObservationFavoriteRemoteDataSourceProviderKey.self] = newValue }
    }
}

class ObservationFavoriteRemoteDataSource {
    
    func pushFavorite(favorite: ObservationFavoriteModel) async -> [AnyHashable: Any] {
        guard let eventId = favorite.eventId,
              let observationRemoteId = favorite.observationRemoteId
        else {
            return [:]
        }
        
        let request: ObservationFavoriteService = {
            if !favorite.favorite {
                return ObservationFavoriteService.deleteFavorite(
                    eventId: eventId,
                    observationRemoteId: observationRemoteId
                )
            } else {
                return ObservationFavoriteService.pushFavorite(
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
                            MageLogger.misc.error("Error while decoding response: \(error) from: \(String(data: data, encoding: .utf8) ?? "empty")")
                            continuation.resume(returning: [:])
                        }
                    case .failure(let error):
                        MageLogger.misc.error("Error \(error)")
                        continuation.resume(returning: [:])
                    }
                }
        }
    }
}
