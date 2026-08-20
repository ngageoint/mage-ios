//
//  LocationFetchLocal.swift
//  LocationFetch
//
//

import Foundation
import FetchOperation
import ServerDTO

public protocol LocationFetchLocal: FetchLocalDataSource where DTO == UserLocationDTO, SaveResult == LocationSaveResult {
    func getLastLocationDate(eventId: Int) async -> Date?
}
