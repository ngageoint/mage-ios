//
//  LocationRepositoryFactory.swift
//  MAGE
//
//

import Foundation
import Persistence
import FetchOperation
import ServerDTO
import APIRouter
import Pipeline

public struct LocationFetchRequest: Sendable {
    public let eventID: EventID
    public let currentUserID: UserID
    
    public init(
        eventID: EventID,
        currentUserID: UserID,
    ) {
        self.eventID = eventID
        self.currentUserID = currentUserID
    }
}

public class LocationFetchRepositoryFactory {
    public static let LocationFetchOperationKind = PipelineOperationKind(rawValue: "fetch locations")
    
    public static func createFetchRepository(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol
    ) -> AnyFetchRepository<LocationFetchRequest, LocationRepositoryFetchResult> {
        
        AnyFetchRepository(
            FetchRepository<LocationFetchRequest, LocationRepositoryFetchResult> { input in
                
                let local = LocationFetchLocalImpl(
                    persistence: persistence,
                    currentUserID: input.currentUserID
                )
                let remote = LocationFetchRemote(
                    url: url,
                    session: session,
                    eventID: input.eventID
                )
                
                let pipeline = Pipeline(
                    operation: LocationFetchOperationKind,
                    context: LocationPipelineContext(eventID: input.eventID)
                ) {
                    LocationPipelineSteps.constructRequest(local: local, url: url)
                    PipelineStep<LocationPipelineContext>.downloadLocations(remote: remote)
                    PipelineStep<LocationPipelineContext>.saveLocations(local: local)
                } output: {
                    let saveResult = $0.locationSaveResult
                    return LocationRepositoryFetchResult(
                        dto: $0.locationDTO,
                        missingUserIDs: saveResult?.missingUserIds,
                        inserts: saveResult?.inserted ?? 0,
                        updates: saveResult?.updated ?? 0
                    )
                }
                
                return pipeline.execute()
            }
        )
    }
}
