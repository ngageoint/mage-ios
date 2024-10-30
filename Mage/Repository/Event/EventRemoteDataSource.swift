//
//  EventRemoteDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 9/1/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct EventRemoteDataSourceProviderKey: InjectionKey {
    static var currentValue: EventRemoteDataSource = EventRemoteDataSourceImpl()
}

extension InjectedValues {
    var eventRemoteDataSource: EventRemoteDataSource {
        get { Self[EventRemoteDataSourceProviderKey.self] }
        set { Self[EventRemoteDataSourceProviderKey.self] = newValue }
    }
}

protocol EventRemoteDataSource {
    func fetchEvents() async -> [[AnyHashable: Any]]?
}

class EventRemoteDataSourceImpl: ObservableObject, EventRemoteDataSource {
    func fetchEvents() async -> [[AnyHashable: Any]]? {
        let request = EventService.fetchEvents
        
        return await withCheckedContinuation { continuation in
            MageSession.shared.session.request(request)
                .validate(MageSession.shared.validateMageResponse)
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            let json = try JSONSerialization.jsonObject(with: data)
                            if let json = json as? [[AnyHashable: Any]] {
                                continuation.resume(returning: json)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        } catch {
                            print("Error while decoding response: \(error) from: \(String(data: data, encoding: .utf8) ?? "empty")")
                            // TODO: what should this throw?
                            continuation.resume(returning: nil)
                        }
                    case .failure(let error):
                        print("Error \(error)")
                        // TODO: what should this throw?
                        continuation.resume(returning: nil)
                    }
                }
        }
    }
}
