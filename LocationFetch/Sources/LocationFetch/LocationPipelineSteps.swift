//
//  LocationPipelineSteps.swift
//  LocationFetch
//
//

import Foundation
import ServerDTO
import FetchOperation
import Pipeline

public extension PipelineStep where Context: LocationDTOContext & URLRequestContext {
    static func downloadLocations(
        remote: LocationFetchRemote
    ) -> Self
    {
        
        Self(
            phase: .downloading
        ) { context, progress in
            
            var context = context
            
            context.locationDTO = try await remote.fetch(
                urlRequest: context.urlRequest,
                progress: progress
            )
            
            return context
        }
    }
}

public extension PipelineStep where Context: LocationDTOContext & LocationSaveResultContext {
    
    static func saveLocations(
        local: any LocationFetchLocal) -> Self {
            Self(
                phase: .saving,
                perform: { context, progress in
                    
                    var context = context
                    
                    context.locationSaveResult = try await local.save(
                        context.locationDTO,
                        progress: progress
                    )
                    
                    return context
                }
            )
        }
}

public enum LocationPipelineSteps {
    
    public static func constructRequest(
        local: any LocationFetchLocal,
        url: URL
    ) -> PipelineStep<LocationPipelineContext> {
        
        PipelineStep(
            phase: .preparing
        ) { context, _ in
            
            var context = context
            
            let date = await local.getLastLocationDate(
                eventId: context.eventID.intValue
            )
            
            context.urlRequest = try? LocationFetchRouter(
                baseURL: url,
                endpoint: .fetchLocations(eventId: context.eventID.rawValue, lastLocationDate: date)
            ).asURLRequest()
            
            return context
        }
    }
}
