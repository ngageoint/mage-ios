//
//  ObservationDataFetchOperation.swift
//  MAGE
//
//  Created by Daniel Barela on 4/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire

class ObservationDataFetchOperation: DataFetchOperation<[AnyHashable : Any]> {

    var date: Date?
    var eventId: Int

    init(eventId: Int, date: Date? = nil) {
        self.date = date
        self.eventId = eventId
    }

    override func fetchData() async -> [[AnyHashable : Any]] {
        if self.isCancelled {
            return []
        }

        let request = ObservationService.getObservations(eventId: eventId, date: date)
        let queue = DispatchQueue(label: "mil.nga.msi.MAGE.api", qos: .background)

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
                            }
                        } catch {
                            print("Error while decoding response: \(error) from: \(String(data: data, encoding: .utf8) ?? "empty")")
                        }
                    case .failure(let error):
                        print("Error \(error)")
                        continuation.resume(returning: [])
                    }
                }
        }
    }
}
